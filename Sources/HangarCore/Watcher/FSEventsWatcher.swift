// FSEventsWatcher — wraps macOS FSEventStreamCreate to stream file changes
// from a root directory. Debounces bursts (default 250ms) and skips common
// ignore-paths (.git, node_modules, DerivedData).

import Foundation

public struct FileChange: Sendable, Equatable {
    public enum Kind: Sendable, Equatable {
        case created
        case modified
        case removed
        case renamed
    }

    public let path: URL
    public let kind: Kind
    public let detectedAt: Date

    public init(path: URL, kind: Kind, detectedAt: Date = Date()) {
        self.path = path
        self.kind = kind
        self.detectedAt = detectedAt
    }
}

/// Per-root file watcher. v0.1 uses callback-driven polling at a 250ms cadence
/// so a real FSEvents-stream integration isn't blocking phase progress; the
/// API is identical so the implementation swaps in transparently in Phase 11.
public actor FSEventsWatcher {
    public let updates: AsyncStream<[FileChange]>
    private let continuation: AsyncStream<[FileChange]>.Continuation
    private let root: URL
    private let debounceMS: UInt64
    private let ignorePatterns: [String]
    private var watching = false
    private var pollTask: Task<Void, Never>?
    private var lastSnapshot: [URL: Date] = [:]

    public init(
        root: URL,
        debounceMilliseconds: UInt64 = 250,
        ignorePatterns: [String] = [".git", "node_modules", "DerivedData", ".build", ".swiftpm"]
    ) {
        self.root = root
        self.debounceMS = debounceMilliseconds
        self.ignorePatterns = ignorePatterns
        let (stream, continuation) = AsyncStream<[FileChange]>.makeStream()
        self.updates = stream
        self.continuation = continuation
    }

    deinit {
        pollTask?.cancel()
        continuation.finish()
    }

    public func start() {
        guard !watching else { return }
        watching = true
        lastSnapshot = snapshotCurrent()
        let interval = debounceMS
        let task = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: interval * 1_000_000)
                await self?.tick()
            }
        }
        pollTask = task
    }

    public func stop() {
        watching = false
        pollTask?.cancel()
        pollTask = nil
    }

    private func tick() {
        guard watching else { return }
        let current = snapshotCurrent()
        var changes: [FileChange] = []
        for (path, mtime) in current {
            if let prior = lastSnapshot[path] {
                if mtime != prior {
                    changes.append(FileChange(path: path, kind: .modified))
                }
            } else {
                changes.append(FileChange(path: path, kind: .created))
            }
        }
        for path in lastSnapshot.keys where current[path] == nil {
            changes.append(FileChange(path: path, kind: .removed))
        }
        lastSnapshot = current
        guard !changes.isEmpty else { return }
        continuation.yield(changes)
    }

    private func snapshotCurrent() -> [URL: Date] {
        var result: [URL: Date] = [:]
        let manager = FileManager.default
        guard
            let enumerator = manager.enumerator(
                at: root,
                includingPropertiesForKeys: [.contentModificationDateKey, .isDirectoryKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            )
        else {
            return result
        }
        while let url = enumerator.nextObject() as? URL {
            let relativeComponents = url.pathComponents
            if relativeComponents.contains(where: { ignorePatterns.contains($0) }) {
                enumerator.skipDescendants()
                continue
            }
            let values = try? url.resourceValues(forKeys: [.contentModificationDateKey, .isDirectoryKey])
            if values?.isDirectory == true { continue }
            if let mtime = values?.contentModificationDate {
                result[url] = mtime
            }
        }
        return result
    }
}
