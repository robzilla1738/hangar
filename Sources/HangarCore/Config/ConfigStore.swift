// ConfigStore — owns the on-disk Hangar config and broadcasts changes.
// Watches ~/.config/hangar/config.json5 via DispatchSourceFileSystemObject;
// emits a fresh HangarConfig snapshot whenever the file is written or replaced.

import Foundation

/// Errors surfaced from the config pipeline.
public enum ConfigError: Error, Sendable {
    case parseFailure(message: String)
    case ioFailure(underlying: Error)
}

/// Default-template JSON5 written on first launch.
public enum ConfigTemplate {
    public static let defaultContents: String = """
        // Hangar configuration — see https://github.com/robzilla1738/hangar/blob/main/docs/config.md
        {
            general: {
                startup: "new_window"
            },
            appearance: {
                theme: "hangar-dark",
                transparency: 0.05,
                titlebar_style: "unified"
            },
            fonts: {
                family: "SF Mono",
                size: 13,
                line_height: 1.2
            },
            agents: {
                claude_code: { binary: "claude" },
                codex:       { binary: "codex" },
                hermes:      { binary: "hermes" },
                extra: []
            },
            keybindings: {
                mission_control: "cmd+0",
                approval_inbox:  "cmd+shift+a",
                new_worktree:    "cmd+shift+w"
            },
            costs: {
                warn_at_usd: 20.0,
                hard_stop_at_usd: null
            },
            worktree: {
                base_dir: "~/Hangar/Worktrees"
            },
            experimental: {
                use_libghostty: false
            }
        }
        """
}

/// Resolves the canonical config path.
///
/// Honors $HANGAR_CONFIG_HOME for tests.
public enum ConfigPaths {
    public static var configHomeDirectory: URL {
        if let override = ProcessInfo.processInfo.environment["HANGAR_CONFIG_HOME"] {
            return URL(fileURLWithPath: override, isDirectory: true)
        }
        return URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true)
            .appendingPathComponent(".config", isDirectory: true)
            .appendingPathComponent("hangar", isDirectory: true)
    }

    public static var configFileURL: URL {
        configHomeDirectory.appendingPathComponent("config.json5")
    }
}

/// Actor that owns the live config snapshot and broadcasts updates.
public actor ConfigStore {
    /// Current snapshot.
    ///
    /// Reads are cheap. Updated atomically.
    public private(set) var current: HangarConfig

    /// Stream of every accepted snapshot, including the initial load.
    public let changes: AsyncStream<HangarConfig>
    private let changesContinuation: AsyncStream<HangarConfig>.Continuation

    /// Path being watched.
    public let fileURL: URL

    /// Underlying GCD file-watcher token; nil if not watching.
    private var watcher: DispatchSourceFileSystemObject?
    private var watchedDescriptor: Int32 = -1

    public init(fileURL: URL = ConfigPaths.configFileURL) {
        self.fileURL = fileURL
        self.current = .defaults
        let (stream, continuation) = AsyncStream<HangarConfig>.makeStream()
        self.changes = stream
        self.changesContinuation = continuation
    }

    deinit {
        watcher?.cancel()
        if watchedDescriptor >= 0 { close(watchedDescriptor) }
        changesContinuation.finish()
    }

    /// Read (and if needed, write) the on-disk config.
    ///
    /// Always returns a valid snapshot.
    public func load() throws -> HangarConfig {
        try ensureFileExists()
        let snapshot = try readAndDecode()
        current = snapshot
        changesContinuation.yield(snapshot)
        return snapshot
    }

    /// Start watching for changes.
    ///
    /// Calling again restarts the watch.
    public func watch() throws {
        watcher?.cancel()
        if watchedDescriptor >= 0 {
            close(watchedDescriptor)
            watchedDescriptor = -1
        }

        try ensureFileExists()
        let fd = open(fileURL.path, O_EVTONLY)
        guard fd >= 0 else {
            throw ConfigError.ioFailure(
                underlying: NSError(domain: NSPOSIXErrorDomain, code: Int(errno))
            )
        }
        watchedDescriptor = fd

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .delete, .rename, .extend],
            queue: .global(qos: .userInitiated)
        )
        watcher = source

        let store = HangarConfigWatcherProxy(store: self)
        source.setEventHandler { [store] in
            Task { await store.fileDidChange() }
        }
        source.setCancelHandler { [fd] in
            if fd >= 0 { close(fd) }
        }
        source.resume()
    }

    /// Stop watching.
    ///
    /// Idempotent.
    public func stopWatching() {
        watcher?.cancel()
        watcher = nil
        if watchedDescriptor >= 0 {
            close(watchedDescriptor)
            watchedDescriptor = -1
        }
    }

    /// Called by the file-watcher callback when the file changes.
    ///
    /// Re-parses; on success publishes a new snapshot, on failure keeps the
    /// previous snapshot and yields nothing.
    public func reload() {
        do {
            let snapshot = try readAndDecode()
            current = snapshot
            changesContinuation.yield(snapshot)
        } catch {
            // Swallow: keep prior snapshot, signal via a future error stream
            // when banner UI lands in Phase 11.
        }
    }

    // MARK: - Private

    private func ensureFileExists() throws {
        let manager = FileManager.default
        let dir = fileURL.deletingLastPathComponent()
        if !manager.fileExists(atPath: dir.path) {
            try manager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        if !manager.fileExists(atPath: fileURL.path) {
            try ConfigTemplate.defaultContents.write(
                to: fileURL,
                atomically: true,
                encoding: .utf8
            )
        }
    }

    private func readAndDecode() throws -> HangarConfig {
        do {
            let data = try Data(contentsOf: fileURL)
            let any = try JSONSerialization.jsonObject(with: data, options: [.json5Allowed])
            let normalized = try JSONSerialization.data(withJSONObject: any)
            let decoder = JSONDecoder()
            return try decoder.decode(HangarConfig.self, from: normalized)
        } catch let error as ConfigError {
            throw error
        } catch {
            throw ConfigError.parseFailure(message: String(describing: error))
        }
    }
}

/// Holds a weak-ish reference for the DispatchSource event handler so we can
/// avoid retaining the actor across thread boundaries.
private actor HangarConfigWatcherProxy {
    weak var store: ConfigStore?

    init(store: ConfigStore) {
        self.store = store
    }

    func fileDidChange() async {
        await store?.reload()
    }
}
