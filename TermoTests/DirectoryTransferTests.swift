import XCTest
import Combine
@testable import Termo

/// 只写测试创建的本地临时目录；远端为内存模型，不连接或修改任何服务器。
private final class TestTransferFS: TransferFileSystem {
    var directories: Set<String> = ["/remote"]
    var files: [String: Data] = [:]
    var parts: [String: Data] = [:]
    var listings: [String: [RemoteFile]] = [:]
    var failing: Set<String> = []
    var generatedFiles = 0
    var completeGeneratedFiles = false
    var reads = 0
    var onProbe: (() async -> Void)?
    var onUpload: ((UploadControl) async -> UploadOutcome?)?
    var offsets: [Int64] = []

    func enumerateDirectory(_ path: String, visit: (RemoteFile) async throws -> Void) async throws {
        if failing.contains(path) { throw RemoteFSError(message: "测试目录读取失败") }
        for file in listings[path] ?? [] {
            reads += 1
            try await visit(file)
        }
        if path == "/remote/many" {
            for i in 0..<generatedFiles {
                reads += 1
                try await visit(RemoteFile(name: "file-\(i)", path: "\(path)/file-\(i)", kind: .file, size: 1, modified: nil))
            }
        }
    }

    func ensureDirectory(_ path: String) async throws {
        if failing.contains(path) || files[path] != nil { throw RemoteFSError(message: "测试目录创建失败") }
        directories.insert(path)
    }

    func probeUpload(remotePath: String) async -> UploadProbe {
        await onProbe?()
        return UploadProbe(partSize: Int64(parts[remotePath]?.count ?? 0), finalExists: files[remotePath] != nil,
                           finalSize: Int64(files[remotePath]?.count ?? 0))
    }

    func upload(localURL: URL, toRemote remotePath: String, startOffset: Int64, control: UploadControl) async -> UploadOutcome {
        offsets.append(startOffset)
        if let outcome = await onUpload?(control) { return outcome }
        if failing.contains(remotePath) { return .failed("测试文件上传失败") }
        do {
            let data = try Data(contentsOf: localURL)
            parts[remotePath] = Data(data.prefix(Int(startOffset))) + data.dropFirst(Int(startOffset))
            control.setSent(Int64(data.count))
            return .completed
        } catch { return .failed(error.localizedDescription) }
    }

    func finalizeUpload(remotePath: String) async -> Result<Void, RemoteFSError> {
        files[remotePath] = parts.removeValue(forKey: remotePath)
        return .success(())
    }

    func download(_ remotePath: String, to localURL: URL, startOffset: Int64, control: UploadControl) async -> UploadOutcome {
        if completeGeneratedFiles, remotePath.hasPrefix("/remote/many/") {
            control.setSent(1)
            return .completed
        }
        if failing.contains(remotePath) || remotePath.hasPrefix("/remote/many/") { return .failed("测试文件下载失败") }
        do {
            let data = files[remotePath] ?? Data()
            try data.write(to: localURL)
            control.setSent(Int64(data.count))
            return .completed
        } catch { return .failed(error.localizedDescription) }
    }

    func cleanupPart(remotePath: String) async { parts.removeValue(forKey: remotePath) }
    func closeSession() {}
}

@MainActor
final class DirectoryTransferTests: XCTestCase {
    private func temporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("termo-tests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        addTeardownBlock { try FileManager.default.removeItem(at: url) }
        return url
    }

    private func file(_ name: String, in parent: String, kind: RemoteFile.Kind = .file, size: Int64 = 3) -> RemoteFile {
        RemoteFile(name: name, path: parent + "/" + name, kind: kind, size: size, modified: nil)
    }

    private func run(_ task: UploadTask, start: () -> Void) async {
        let finished = expectation(description: "传输完成")
        task.onFinished = { finished.fulfill() }
        start()
        await fulfillment(of: [finished], timeout: 30)
    }

    func testMixedUploadNestedEmptyDirectoriesAndSymlinks() async throws {
        let base = try temporaryDirectory()
        let folder = base.appendingPathComponent("project")
        let nested = folder.appendingPathComponent("nested")
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: folder.appendingPathComponent("empty"), withIntermediateDirectories: false)
        try Data("abc".utf8).write(to: nested.appendingPathComponent("same.txt"))
        try Data("xyz".utf8).write(to: folder.appendingPathComponent("same.txt"))
        try Data("single".utf8).write(to: base.appendingPathComponent("single.txt"))
        try FileManager.default.createSymbolicLink(at: folder.appendingPathComponent("loop"), withDestinationURL: folder)
        try FileManager.default.createSymbolicLink(at: folder.appendingPathComponent("file-link"), withDestinationURL: nested.appendingPathComponent("same.txt"))
        let second = base.appendingPathComponent("other")
        try FileManager.default.createDirectory(at: second, withIntermediateDirectories: false)
        let fs = TestTransferFS()
        let task = UploadTask(files: [folder, base.appendingPathComponent("single.txt"), second], destDir: "/remote", fs: fs) {}
        await run(task) { task.start() }
        XCTAssertEqual(task.phase, .done)
        XCTAssertFalse(task.hasFailures)
        XCTAssertEqual(fs.files["/remote/project/nested/same.txt"], Data("abc".utf8))
        XCTAssertEqual(fs.files["/remote/project/same.txt"], Data("xyz".utf8))
        XCTAssertEqual(fs.files["/remote/single.txt"], Data("single".utf8))
        XCTAssertTrue(fs.directories.contains("/remote/project/empty"))
        XCTAssertTrue(fs.directories.contains("/remote/other"))
        XCTAssertNil(fs.files["/remote/project/file-link"])
        XCTAssertEqual(task.items.filter { $0.state == .skipped }.count, 2)
        XCTAssertEqual(task.overallSent, 12)
    }

    func testDownloadNestedEmptyAndSymbolicLinks() async throws {
        let local = try temporaryDirectory()
        let fs = TestTransferFS()
        let root = file("project", in: "/remote", kind: .directory, size: 0)
        fs.listings[root.path] = [file("empty", in: root.path, kind: .directory),
                                  file("nested", in: root.path, kind: .directory),
                                  file("same.txt", in: root.path), file("loop", in: root.path, kind: .symlink)]
        fs.listings[root.path + "/nested"] = [file("same.txt", in: root.path + "/nested")]
        fs.files[root.path + "/same.txt"] = Data("abc".utf8)
        fs.files[root.path + "/nested/same.txt"] = Data("xyz".utf8)
        let output = local.appendingPathComponent(root.name)
        let task = UploadTask(download: [root], toLocalURLs: [output], inDir: local, fs: fs) {}
        await run(task) { task.start() }
        XCTAssertFalse(task.hasFailures)
        XCTAssertTrue(FileManager.default.fileExists(atPath: output.appendingPathComponent("empty").path))
        XCTAssertEqual(try Data(contentsOf: output.appendingPathComponent("same.txt")), Data("abc".utf8))
        XCTAssertEqual(try Data(contentsOf: output.appendingPathComponent("nested/same.txt")), Data("xyz".utf8))
        XCTAssertFalse(FileManager.default.fileExists(atPath: output.appendingPathComponent("loop").path))
    }

    func testCollisionReservationsAndDanglingLink() throws {
        let local = try temporaryDirectory()
        try Data("keep".utf8).write(to: local.appendingPathComponent("same.txt"))
        let first = uniqueDownloadURL("same.txt", in: local, isDirectory: false)
        XCTAssertEqual(first.lastPathComponent, "same (1).txt")
        XCTAssertEqual(uniqueDownloadURL("same.txt", in: local, isDirectory: false, taken: [first.path]).lastPathComponent, "same (2).txt")
        try FileManager.default.createSymbolicLink(atPath: local.appendingPathComponent("project.v1").path, withDestinationPath: "/nonexistent-termo-test")
        XCTAssertEqual(uniqueDownloadURL("project.v1", in: local, isDirectory: true).lastPathComponent, "project.v1 (1)")
        XCTAssertEqual(try Data(contentsOf: local.appendingPathComponent("same.txt")), Data("keep".utf8))
    }

    func testPartialFailureContinuesAndRetriesOnlyFailedFile() async throws {
        let local = try temporaryDirectory()
        let fs = TestTransferFS()
        let root = file("project", in: "/remote", kind: .directory)
        fs.listings[root.path] = [file("bad.txt", in: root.path), file("good.txt", in: root.path)]
        fs.failing = [root.path + "/bad.txt"]
        fs.files[root.path + "/good.txt"] = Data("yes".utf8)
        let output = local.appendingPathComponent("project")
        let task = UploadTask(download: [root], toLocalURLs: [output], inDir: local, fs: fs) {}
        await run(task) { task.start() }
        XCTAssertEqual(task.failureCount, 1)
        XCTAssertEqual(try Data(contentsOf: output.appendingPathComponent("good.txt")), Data("yes".utf8))
        fs.failing = []
        fs.files[root.path + "/bad.txt"] = Data("fix".utf8)
        await run(task) { task.retryFailed(resume: false) }
        XCTAssertFalse(task.hasFailures)
        XCTAssertEqual(task.itemCount, 1)
        XCTAssertEqual(try Data(contentsOf: output.appendingPathComponent("bad.txt")), Data("fix".utf8))
    }

    func testFailedSubtreeDoesNotStopSiblingAndCanRetryDirectory() async throws {
        let local = try temporaryDirectory()
        let fs = TestTransferFS()
        let root = file("project", in: "/remote", kind: .directory)
        let bad = file("bad", in: root.path, kind: .directory)
        fs.listings[root.path] = [bad, file("ok.txt", in: root.path)]
        fs.failing = [bad.path]
        let output = local.appendingPathComponent("project")
        let task = UploadTask(download: [root], toLocalURLs: [output], inDir: local, fs: fs) {}
        await run(task) { task.start() }
        XCTAssertEqual(task.failureCount, 1)
        XCTAssertTrue(FileManager.default.fileExists(atPath: output.appendingPathComponent("ok.txt").path))
        fs.failing = []
        fs.listings[bad.path] = [file("fixed.txt", in: bad.path)]
        await run(task) { task.retryFailed(resume: false) }
        XCTAssertFalse(task.hasFailures)
        XCTAssertTrue(FileManager.default.fileExists(atPath: output.appendingPathComponent("bad/fixed.txt").path))
    }

    func testTenThousandFailuresHaveBoundedHistoryAndCompleteRetryJournal() async throws {
        let local = try temporaryDirectory()
        let fs = TestTransferFS()
        fs.generatedFiles = 10_000
        let root = file("many", in: "/remote", kind: .directory)
        let task = UploadTask(download: [root], toLocalURLs: [local.appendingPathComponent("many")], inDir: local, fs: fs) {}
        await run(task) { task.start() }
        XCTAssertEqual(task.failureCount, 10_000)
        XCTAssertEqual(task.itemCount, 10_001)
        XCTAssertLessThanOrEqual(task.items.count, UploadTask.historyLimit)
        await run(task) { task.retryFailed(resume: false) }
        XCTAssertEqual(task.failureCount, 10_000)
        XCTAssertEqual(task.itemCount, 10_000)
        XCTAssertLessThanOrEqual(task.items.count, UploadTask.historyLimit)
    }

    func testCancellationStopsDirectoryEnumeration() async throws {
        let local = try temporaryDirectory()
        let fs = TestTransferFS()
        fs.generatedFiles = 10_000
        let root = file("many", in: "/remote", kind: .directory)
        let task = UploadTask(download: [root], toLocalURLs: [local.appendingPathComponent("many")], inDir: local, fs: fs) {}
        task.objectWillChange.sink { if task.itemCount >= 5 { task.cancel() } }.store(in: &subscriptions)
        await run(task) { task.start() }
        XCTAssertEqual(task.phase, .cancelled)
        XCTAssertLessThan(fs.reads, 10)
        XCTAssertTrue(FileManager.default.fileExists(atPath: local.appendingPathComponent("many").path))
    }

    private var subscriptions: Set<AnyCancellable> = []

    func testPauseDuringProbeDoesNotStartUploadUntilResume() async throws {
        let local = try temporaryDirectory()
        let source = local.appendingPathComponent("file")
        try Data("data".utf8).write(to: source)
        let fs = TestTransferFS()
        let task = UploadTask(files: [source], destDir: "/remote", fs: fs) {}
        let paused = expectation(description: "探测期间暂停")
        fs.onProbe = { task.pause(); paused.fulfill() }
        task.start()
        await fulfillment(of: [paused], timeout: 5)
        XCTAssertEqual(task.phase, .paused)
        XCTAssertTrue(fs.offsets.isEmpty)
        fs.onProbe = nil
        await run(task) { task.requestResume(slotFree: true) }
        XCTAssertEqual(fs.files["/remote/file"], Data("data".utf8))
    }

    func testUploadFailureResumesExistingPart() async throws {
        let local = try temporaryDirectory()
        let source = local.appendingPathComponent("file")
        try Data("abcdef".utf8).write(to: source)
        let fs = TestTransferFS()
        let task = UploadTask(files: [source], destDir: "/remote", fs: fs) {}
        fs.onUpload = { control in
            fs.parts["/remote/file"] = Data("abc".utf8)
            control.setSent(3)
            return .failed("测试中断")
        }
        await run(task) { task.start() }
        fs.onUpload = nil
        await run(task) { task.retryFailed(resume: true) }
        XCTAssertEqual(fs.offsets, [0, 3])
        XCTAssertEqual(fs.files["/remote/file"], Data("abcdef".utf8))
    }

    func testOverwriteDecisionAndSkipPreserveSingleFileBehavior() async throws {
        let local = try temporaryDirectory()
        let source = local.appendingPathComponent("file")
        try Data("new".utf8).write(to: source)
        let fs = TestTransferFS()
        fs.files["/remote/file"] = Data("old".utf8)
        let task = UploadTask(files: [source], destDir: "/remote", fs: fs) {}
        task.$pendingAsk.sink { if $0 != nil { Task { @MainActor in task.resolveAsk(.skipAll) } } }.store(in: &subscriptions)
        await run(task) { task.start() }
        XCTAssertEqual(fs.files["/remote/file"], Data("old".utf8))
        XCTAssertEqual(task.items.first?.state, .skipped)
    }

    func testUploadDirectoryCreationFailureContinuesWithNextRoot() async throws {
        let local = try temporaryDirectory()
        let folder = local.appendingPathComponent("folder")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: false)
        let source = local.appendingPathComponent("file")
        try Data("abc".utf8).write(to: source)
        let fs = TestTransferFS()
        fs.failing = ["/remote/folder"]
        let task = UploadTask(files: [folder, source], destDir: "/remote", fs: fs) {}
        await run(task) { task.start() }
        XCTAssertEqual(task.failureCount, 1)
        XCTAssertEqual(fs.files["/remote/file"], Data("abc".utf8))
        fs.failing = []
        await run(task) { task.retryFailed(resume: false) }
        XCTAssertFalse(task.hasFailures)
        XCTAssertTrue(fs.directories.contains("/remote/folder"))
    }

    func testQueuedCancellationDoesNotTouchFileSystem() async throws {
        let fs = TestTransferFS()
        let task = UploadTask(files: [URL(fileURLWithPath: "/not-a-real-file")], destDir: "/remote", fs: fs) {}
        task.cancel()
        XCTAssertEqual(task.phase, .cancelled)
        XCTAssertTrue(fs.offsets.isEmpty)
        XCTAssertEqual(fs.reads, 0)
    }

    func testAggregateProgressSurvivesHistoryEviction() async throws {
        let local = try temporaryDirectory()
        let fs = TestTransferFS()
        fs.generatedFiles = 512
        fs.completeGeneratedFiles = true
        let root = file("many", in: "/remote", kind: .directory)
        let task = UploadTask(download: [root], toLocalURLs: [local.appendingPathComponent("many")], inDir: local, fs: fs) {}
        await run(task) { task.start() }
        XCTAssertEqual(task.totalBytes, 512)
        XCTAssertEqual(task.overallSent, 512)
        XCTAssertEqual(task.processedCount, 513)
        XCTAssertLessThanOrEqual(task.items.count, UploadTask.historyLimit)
    }

    func testCancellationWhileWaitingForSamePathLock() async throws {
        let model = AppModel.shared
        let key = "termo-test-lock-\(UUID().uuidString)"
        let acquired = await model.acquireTransferPath(key)
        XCTAssertTrue(acquired)
        defer { model.releaseTransferPath(key) }
        let local = try temporaryDirectory()
        let source = local.appendingPathComponent("file")
        try Data("abc".utf8).write(to: source)
        let fs = TestTransferFS()
        let task = UploadTask(files: [source], destDir: "/remote", fs: fs) {}
        let waiting = expectation(description: "等待文件锁")
        task.acquirePathLock = { _, control in
            waiting.fulfill()
            return await model.acquireTransferPath(key, control: control)
        }
        task.releasePathLock = { _ in XCTFail("取消的等待者不应取得或释放别人的锁") }
        task.onCancelRequested = { model.wakeTransferPathWaiters() }
        task.start()
        await fulfillment(of: [waiting], timeout: 5)
        await run(task) { task.cancel() }
        XCTAssertEqual(task.phase, .cancelled)
        XCTAssertTrue(fs.files.isEmpty)
    }

    func testUnsafeRemoteNameCannotEscapeDownloadDirectory() async throws {
        let local = try temporaryDirectory()
        let fs = TestTransferFS()
        let root = file("project", in: "/remote", kind: .directory)
        fs.listings[root.path] = [file("../escape", in: root.path)]
        let task = UploadTask(download: [root], toLocalURLs: [local.appendingPathComponent("project")], inDir: local, fs: fs) {}
        await run(task) { task.start() }
        XCTAssertEqual(task.failureCount, 1)
        XCTAssertFalse(FileManager.default.fileExists(atPath: local.appendingPathComponent("escape").path))
    }
}
