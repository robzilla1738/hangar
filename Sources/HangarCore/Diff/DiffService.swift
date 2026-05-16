// DiffService — line-level diff between a file's current content and a
// reference baseline (HEAD blob or empty string for new files). Uses
// CollectionDifference for a stable, dependency-free implementation.

import Foundation

public enum HunkLineKind: Sendable, Equatable {
    case added
    case removed
    case context
}

public struct HunkLine: Sendable, Equatable {
    public let number: Int
    public let kind: HunkLineKind
    public let content: String

    public init(number: Int, kind: HunkLineKind, content: String) {
        self.number = number
        self.kind = kind
        self.content = content
    }
}

public struct Hunk: Sendable, Equatable {
    public let lineStart: Int
    public let lineEnd: Int
    public let lines: [HunkLine]

    public init(lineStart: Int, lineEnd: Int, lines: [HunkLine]) {
        self.lineStart = lineStart
        self.lineEnd = lineEnd
        self.lines = lines
    }

    public var additions: Int { lines.filter { $0.kind == .added }.count }
    public var removals: Int { lines.filter { $0.kind == .removed }.count }
}

public struct Diff: Sendable, Equatable {
    public let path: URL
    public let hunks: [Hunk]

    public init(path: URL, hunks: [Hunk] = []) {
        self.path = path
        self.hunks = hunks
    }

    public var isEmpty: Bool { hunks.isEmpty }
    public var totalAdditions: Int { hunks.map(\.additions).reduce(0, +) }
    public var totalRemovals: Int { hunks.map(\.removals).reduce(0, +) }
}

public enum DiffService {
    /// Compare two strings and return a single hunk capturing every change.
    public static func compare(baseline: String, current: String, path: URL) -> Diff {
        let baselineLines = baseline.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        let currentLines = current.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)

        if baselineLines == currentLines {
            return Diff(path: path)
        }

        let difference = currentLines.difference(from: baselineLines)
        var lines: [HunkLine] = []
        for change in difference {
            switch change {
            case .insert(let offset, let element, _):
                lines.append(HunkLine(number: offset + 1, kind: .added, content: element))
            case .remove(let offset, let element, _):
                lines.append(HunkLine(number: offset + 1, kind: .removed, content: element))
            }
        }
        let firstLine = lines.map(\.number).min() ?? 1
        let lastLine = lines.map(\.number).max() ?? firstLine
        let hunk = Hunk(lineStart: firstLine, lineEnd: lastLine, lines: lines)
        return Diff(path: path, hunks: [hunk])
    }
}
