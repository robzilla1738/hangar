// GitService — thin wrapper around shelling out to `git` for worktree operations.
// v0.1 uses Process; v0.2 may swap to libgit2 / SwiftGit2 for richer status
// without subprocess overhead.

import Foundation

public struct Worktree: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let path: URL
    public let branch: String
    public let headSHA: String
    public let isDirty: Bool
    public let aheadCount: Int
    public let behindCount: Int

    public init(
        id: UUID = UUID(),
        path: URL,
        branch: String,
        headSHA: String,
        isDirty: Bool = false,
        aheadCount: Int = 0,
        behindCount: Int = 0
    ) {
        self.id = id
        self.path = path
        self.branch = branch
        self.headSHA = headSHA
        self.isDirty = isDirty
        self.aheadCount = aheadCount
        self.behindCount = behindCount
    }
}

public enum GitError: Error, Sendable {
    case commandFailed(command: String, exitCode: Int32, stderr: String)
    case parseFailure(message: String)
}

public actor GitService {
    public init() {}

    /// List worktrees for the repo containing `repoRoot`.
    public func worktrees(in repoRoot: URL) throws -> [Worktree] {
        let output = try run(["worktree", "list", "--porcelain"], cwd: repoRoot)
        return parseWorktreePorcelain(output)
    }

    /// Create a new worktree at `path` from `baseRef` checked out as `branch`.
    public func createWorktree(
        repoRoot: URL,
        at path: URL,
        branch: String,
        baseRef: String = "HEAD"
    ) throws {
        let parent = path.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
        let args = ["worktree", "add", "-b", branch, path.path, baseRef]
        _ = try run(args, cwd: repoRoot)
    }

    /// Remove an existing worktree at `path`.
    public func removeWorktree(repoRoot: URL, at path: URL) throws {
        _ = try run(["worktree", "remove", path.path], cwd: repoRoot)
    }

    // MARK: - Internal

    private func run(_ args: [String], cwd: URL) throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        process.arguments = ["git"] + args
        process.currentDirectoryURL = cwd

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()
        process.waitUntilExit()

        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
        let stderr = String(data: stderrData, encoding: .utf8) ?? ""

        if process.terminationStatus != 0 {
            throw GitError.commandFailed(
                command: "git " + args.joined(separator: " "),
                exitCode: process.terminationStatus,
                stderr: stderr
            )
        }
        return stdout
    }

    /// Parse `git worktree list --porcelain` output.
    func parseWorktreePorcelain(_ raw: String) -> [Worktree] {
        var worktrees: [Worktree] = []
        var current = PorcelainAccumulator()

        for line in raw.split(separator: "\n", omittingEmptySubsequences: false) {
            let trimmed = String(line)
            if trimmed.hasPrefix("worktree ") {
                current.flush(into: &worktrees)
                current.path = URL(fileURLWithPath: String(trimmed.dropFirst("worktree ".count)))
            } else if trimmed.hasPrefix("HEAD ") {
                current.head = String(trimmed.dropFirst("HEAD ".count))
            } else if trimmed.hasPrefix("branch refs/heads/") {
                current.branch = String(trimmed.dropFirst("branch refs/heads/".count))
            } else if trimmed.hasPrefix("detached") {
                current.branch = "(detached)"
            } else if trimmed.isEmpty {
                current.flush(into: &worktrees)
            }
        }
        current.flush(into: &worktrees)
        return worktrees
    }

    private struct PorcelainAccumulator {
        var path: URL?
        var head: String?
        var branch: String?

        mutating func flush(into worktrees: inout [Worktree]) {
            defer { reset() }
            guard let path, let head, let branch else { return }
            worktrees.append(Worktree(path: path, branch: branch, headSHA: head))
        }

        private mutating func reset() {
            path = nil
            head = nil
            branch = nil
        }
    }

    /// Sanitize a branch name into a directory-safe slug.
    public func sanitizedDirectoryName(repoName: String, branch: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(.init(charactersIn: "-_"))
        let safeRepo = repoName.unicodeScalars
            .map { allowed.contains($0) ? String($0) : "-" }
            .joined()
        let safeBranch = branch.unicodeScalars
            .map { allowed.contains($0) ? String($0) : "-" }
            .joined()
        return "\(safeRepo)-\(safeBranch)"
    }
}
