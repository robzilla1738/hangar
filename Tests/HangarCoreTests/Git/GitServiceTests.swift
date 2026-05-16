// GitServiceTests — sanitizer + porcelain parser; real git interactions
// covered by an integration test that creates a temp repo.

import Foundation
import XCTest

@testable import HangarCore

final class GitServiceTests: XCTestCase {
    func testSanitizerReplacesSlashes() async {
        let service = GitService()
        let name = await service.sanitizedDirectoryName(repoName: "hangar", branch: "feat/cool/thing")
        XCTAssertEqual(name, "hangar-feat-cool-thing")
    }

    func testSanitizerKeepsAlphanumericsHyphensUnderscores() async {
        let service = GitService()
        let name = await service.sanitizedDirectoryName(repoName: "my_repo", branch: "rc-1.0")
        XCTAssertEqual(name, "my_repo-rc-1-0")
    }

    func testParseWorktreePorcelainSingleEntry() async {
        let service = GitService()
        let raw = """
            worktree /Users/me/work/hangar
            HEAD abc123def456
            branch refs/heads/main

            """
        let result = await service.parseWorktreePorcelain(raw)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.branch, "main")
        XCTAssertEqual(result.first?.headSHA, "abc123def456")
        XCTAssertEqual(result.first?.path.path, "/Users/me/work/hangar")
    }

    func testParseWorktreePorcelainMultipleEntries() async {
        let service = GitService()
        let raw = """
            worktree /Users/me/work/hangar
            HEAD aaa
            branch refs/heads/main

            worktree /Users/me/Hangar/Worktrees/hangar-feat
            HEAD bbb
            branch refs/heads/feat/cool

            """
        let result = await service.parseWorktreePorcelain(raw)
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.map(\.branch), ["main", "feat/cool"])
    }

    func testParseDetachedWorktree() async {
        let service = GitService()
        let raw = """
            worktree /tmp/wt
            HEAD ccc
            detached

            """
        let result = await service.parseWorktreePorcelain(raw)
        XCTAssertEqual(result.first?.branch, "(detached)")
    }
}
