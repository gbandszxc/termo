import Foundation

/// 文件传输仍由 RemoteFS 执行；此边界让目录编排可以用临时文件系统验证。
protocol TransferFileSystem: AnyObject {
    func enumerateDirectory(_ path: String, visit: (RemoteFile) async throws -> Void) async throws
    func ensureDirectory(_ path: String) async throws
    func probeUpload(remotePath: String) async -> UploadProbe
    func upload(localURL: URL, toRemote remotePath: String, startOffset: Int64, control: UploadControl) async -> UploadOutcome
    func finalizeUpload(remotePath: String) async -> Result<Void, RemoteFSError>
    func download(_ remotePath: String, to localURL: URL, startOffset: Int64, control: UploadControl) async -> UploadOutcome
    func cleanupPart(remotePath: String) async
    func closeSession()
}

/// 轻量记录：用于惰性遍历及失败重试，不为整棵目录树创建 ObservableObject。
struct TransferEntry: Codable {
    enum Kind: String, Codable { case file, directory, skipped }
    let localURL: URL
    let remotePath: String
    let size: Int64
    let kind: Kind
    var error: String? = nil
    var interrupted = false

    static func upload(_ url: URL, to directory: String) async -> TransferEntry {
        await Task.detached {
            let path = directory.hasSuffix("/") ? directory + url.lastPathComponent : directory + "/" + url.lastPathComponent
            do {
                let attrs = try FileManager.default.attributesOfItem(atPath: url.path)
                let type = attrs[.type] as? FileAttributeType
                let kind: Kind = type == .typeDirectory ? .directory : (type == .typeRegular ? .file : .skipped)
                return TransferEntry(localURL: url, remotePath: path,
                                     size: kind == .file ? (attrs[.size] as? NSNumber)?.int64Value ?? 0 : 0, kind: kind)
            } catch {
                return TransferEntry(localURL: url, remotePath: path, size: 0, kind: .file, error: error.localizedDescription)
            }
        }.value
    }

    static func download(_ file: RemoteFile, to url: URL) -> TransferEntry {
        TransferEntry(localURL: url, remotePath: file.path, size: file.kind == .file ? file.size : 0,
                      kind: file.isDir ? .directory : (file.kind == .file ? .file : .skipped))
    }
}

/// 不覆盖已有文件、目录或悬空链接；目录名中的点不视为扩展名。
func uniqueDownloadURL(_ name: String, in directory: URL, isDirectory: Bool, taken: Set<String> = []) -> URL {
    let base = isDirectory ? name : (name as NSString).deletingPathExtension
    let ext = isDirectory ? "" : (name as NSString).pathExtension
    var candidate = directory.appendingPathComponent(name)
    var suffix = 1
    while taken.contains(candidate.path) || (try? FileManager.default.attributesOfItem(atPath: candidate.path)) != nil {
        let renamed = ext.isEmpty ? "\(base) (\(suffix))" : "\(base) (\(suffix)).\(ext)"
        candidate = directory.appendingPathComponent(renamed)
        suffix += 1
    }
    return candidate
}

private final class LocalDirectoryCursor: @unchecked Sendable {
    private var error: Error?
    private var enumerator: FileManager.DirectoryEnumerator?

    init(_ url: URL) {
        enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: nil,
                                                    options: [.skipsSubdirectoryDescendants]) { [weak self] _, error in
            self?.error = error
            return false
        }
    }

    func next() throws -> URL? {
        guard let enumerator else { throw CocoaError(.fileReadNoPermission) }
        let next = enumerator.nextObject() as? URL
        if let error { throw error }
        return next
    }
}

/// 深度优先、消费一项才继续读下一项。没有无界 pending 队列；远端每层至多持有一个 readdir 批次。
struct DirectoryTransfer {
    let direction: TransferDirection
    let fs: any TransferFileSystem
    let checkpoint: () async throws -> Void
    let consume: (TransferEntry) async throws -> Bool

    func walk(_ entry: TransferEntry, depth: Int = 0) async throws {
        try await checkpoint()
        guard depth < 256 else {
            var failed = entry
            failed.error = String(localized: "目录层级过深")
            _ = try await consume(failed)
            return
        }
        guard try await consume(entry), entry.kind == .directory else { return }
        do {
            if direction == .upload {
                // FileManager 的枚举器惰性读取，文件属性也在后台读取，避免大目录阻塞主线程。
                let cursor = await Task.detached { LocalDirectoryCursor(entry.localURL) }.value
                while true {
                    try await checkpoint()
                    let child = try await Task.detached { try cursor.next() }.value
                    guard let child else { break }
                    try await walk(TransferEntry.upload(child, to: entry.remotePath), depth: depth + 1)
                }
            } else {
                try await fs.enumerateDirectory(entry.remotePath) { file in
                    guard file.name != ".", file.name != ".." else { return }
                    // 远端名称不可信：拒绝绝对路径、路径分隔符与本地 HFS 的冒号别名，保证落地不逃出目标目录。
                    guard !file.name.isEmpty, !file.name.contains("/"), !file.name.contains(":"), !file.name.contains("\0") else {
                        throw RemoteFSError(message: String(localized: "无效远端文件名"))
                    }
                    let child = RemoteFile(name: file.name,
                                           path: entry.remotePath.hasSuffix("/") ? entry.remotePath + file.name : entry.remotePath + "/" + file.name,
                                           kind: file.kind, size: file.size, modified: file.modified)
                    let local = await Task.detached {
                        uniqueDownloadURL(file.name, in: entry.localURL, isDirectory: file.isDir)
                    }.value
                    try await walk(.download(child, to: local), depth: depth + 1)
                }
            }
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            var failed = entry
            failed.error = (error as? RemoteFSError)?.message ?? error.localizedDescription
            _ = try await consume(failed)
        }
    }
}

/// 失败记录落在应用自己的临时目录，逐条读取重试；大量失败也不会无限增长 UI 内存。
/// 临时记录不含凭证，任务释放时删除。不改变已有的远端 .part 续传方式。
final class TransferJournal {
    private let url: URL
    private let handle: FileHandle
    private var readOffset: UInt64 = 0

    init() throws {
        url = FileManager.default.temporaryDirectory.appendingPathComponent("termo-transfer-\(UUID().uuidString)")
        guard FileManager.default.createFile(atPath: url.path, contents: nil, attributes: [.posixPermissions: 0o600]) else {
            throw CocoaError(.fileWriteUnknown)
        }
        handle = try FileHandle(forUpdating: url)
    }

    deinit {
        try? handle.close()
        try? FileManager.default.removeItem(at: url)
    }

    func append(_ entry: TransferEntry) throws {
        let data = try JSONEncoder().encode(entry)
        var size = UInt32(data.count).littleEndian
        try handle.seekToEnd()
        try withUnsafeBytes(of: &size) { try handle.write(contentsOf: Data($0)) }
        try handle.write(contentsOf: data)
    }

    func rewind() { readOffset = 0 }

    func next() throws -> TransferEntry? {
        try handle.seek(toOffset: readOffset)
        guard let header = try handle.read(upToCount: 4), !header.isEmpty else { return nil }
        guard header.count == 4 else { throw CocoaError(.fileReadCorruptFile) }
        let size = header.enumerated().reduce(UInt32(0)) { $0 | UInt32($1.element) << (8 * $1.offset) }
        guard let data = try handle.read(upToCount: Int(size)), data.count == size else { throw CocoaError(.fileReadCorruptFile) }
        readOffset += 4 + UInt64(size)
        return try JSONDecoder().decode(TransferEntry.self, from: data)
    }
}
