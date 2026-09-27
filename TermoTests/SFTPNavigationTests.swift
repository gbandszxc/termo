import AppKit
import XCTest
@testable import Termo

@MainActor
final class SFTPNavigationTests: XCTestCase {
    func testNavigationWithoutCompletionLoadsDirectory() async {
        let listed = expectation(description: "真正调用目录读取")
        let state = BrowserState(fs: RemoteFS(SSHConnection()), listDirectory: { path in
            XCTAssertEqual(path, "/var/log")
            listed.fulfill()
            return .success([])
        })
        state.navigate(to: "/var/log")
        await fulfillment(of: [listed], timeout: 2)
        XCTAssertEqual(state.path, "/var/log")
        XCTAssertEqual(state.phase, .loaded)
    }

    func testPathsRemainRemoteAndLiteral() {
        XCTAssertEqual(BrowserState.resolvePath("/var/log", current: "/root", home: "/home/user"), "/var/log")
        XCTAssertEqual(BrowserState.resolvePath("~/项目", current: "/root", home: "/home/user"), "/home/user/项目")
        XCTAssertEqual(BrowserState.resolvePath("~", current: "/root", home: "/home/user"), "/home/user")
        XCTAssertEqual(BrowserState.resolvePath("../log", current: "/link", home: ""), "/link/../log")
        XCTAssertEqual(BrowserState.resolvePath("a b", current: "/", home: ""), "/a b")
        XCTAssertEqual(BrowserState.resolvePath("$(pwd)", current: "", home: "/home/user"), "/home/user/$(pwd)")
        for invalid in ["", "/tmp\nnext", "/tmp\u{0}"] {
            XCTAssertNil(BrowserState.resolvePath(invalid, current: "/root", home: "/home/user"))
        }
    }

    func testInvalidInputPreservesCurrentDirectoryWithoutConnecting() {
        let state = BrowserState(fs: RemoteFS(SSHConnection()))
        state.path = "/root"
        state.phase = .loaded
        state.entries = [RemoteFile(name: "file", path: "/root/file", kind: .file, size: 0, modified: nil)]
        state.navigate(to: "") { XCTAssertFalse($0) }
        XCTAssertEqual(state.path, "/root")
        XCTAssertEqual(state.entries.count, 1)
        XCTAssertEqual(state.phase, .loaded)
        XCTAssertNotNil(state.navigationError)
    }

    func testMissingAndDeniedDirectoriesPreserveListingAndHistory() {
        let state = BrowserState(fs: RemoteFS(SSHConnection()))
        let file = RemoteFile(name: "file", path: "/root/file", kind: .file, size: 0, modified: nil)
        XCTAssertTrue(state.finishNavigation(.success([file]), to: "/root", pushBack: true, from: "/"))
        state.selection = [file.path]
        for error in ["目录不存在", "没有访问权限", "路径不是目录"] {
            XCTAssertFalse(state.finishNavigation(.failure(RemoteFSError(message: error)), to: "/invalid", pushBack: true, from: "/root"))
            XCTAssertEqual(state.path, "/root")
            XCTAssertEqual(state.entries.map(\.path), [file.path])
            XCTAssertEqual(state.selection, [file.path])
            XCTAssertTrue(state.canGoBack)
            XCTAssertEqual(state.phase, .loaded)
            XCTAssertEqual(state.navigationError, error)
        }
    }

    func testTerminalMenuOnlyOffersSFTPForSSH() {
        let title = String(localized: "在 SFTP 中打开当前目录")
        XCTAssertFalse(TerminalSurface.buildContextMenu().items.contains { $0.title == title })
        var opened = false
        let menu = TerminalSurface.buildContextMenu(onOpenSFTP: { opened = true })
        let item = menu.items.first { $0.title == title }
        XCTAssertNotNil(item)
        if let item, let action = item.action { _ = NSApplication.shared.sendAction(action, to: item.target, from: item) }
        XCTAssertTrue(opened)
    }

    func testOSCCurrentDirectoryPreservesShellPath() {
        // 本仓库 shell 钩子直接上报 $PWD，不能把字面 %20 解码成空格。
        XCTAssertEqual(TerminalSessionDelegate.parsePath("file://server/root/a b/中文#?/%20"), "/root/a b/中文#?/%20")
        XCTAssertEqual(TerminalSessionDelegate.parsePath("/root/a%20b"), "/root/a%20b")
        XCTAssertNil(TerminalSessionDelegate.parsePath("file://server"))
    }
}
