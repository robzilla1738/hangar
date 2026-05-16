// TerminalEmulator — protocol abstracting the underlying terminal renderer / PTY
// orchestrator. v0.1 ships with the SwiftTermEmulator implementation; libghostty
// or a custom Metal renderer can swap in via this same protocol in v0.2.

import AppKit
import Foundation

/// Abstracts the terminal emulator and its PTY connection.
///
/// The conforming implementation owns:
/// - the NSView that renders the terminal
/// - the PTY-attached child process
/// - the byte stream into and out of the child
///
/// Concrete implementations may have additional @MainActor constraints.
@MainActor
public protocol TerminalEmulator: AnyObject {
    /// The unique identifier for this emulator instance.
    var id: UUID { get }

    /// The AppKit view that renders the terminal buffer.
    ///
    /// Returned as `NSView` rather than the concrete SwiftTerm view so the
    /// protocol can host alternative renderers (libghostty, Metal-direct).
    var view: NSView { get }

    /// The PID of the child process, if running.
    var attachedProcessID: pid_t? { get }

    /// The exit code of the child process, if it has exited.
    var exitCode: Int32? { get }

    /// Whether the emulator has been started.
    var isRunning: Bool { get }

    /// Stream of raw PTY output bytes.
    ///
    /// `PaneViewModel.startObserving` iterates this stream to drive agent
    /// detection (via `ShellCommandDetector`), status updates (via
    /// `AgentRegexParser`), and cost accounting.
    var outputStream: AsyncStream<Data> { get }

    /// Start the child process inside the PTY.
    ///
    /// - Parameters:
    ///   - command: Absolute path or PATH-resolvable command.
    ///   - args: Command arguments.
    ///   - env: Environment overrides; merged with the user's environment.
    ///   - cwd: Working directory for the child; defaults to the user's home.
    func start(command: String, args: [String], env: [String: String], cwd: URL?)

    /// Send text to the child's stdin via the PTY.
    func send(_ text: String)

    /// Resize the PTY to the given column/row dimensions.
    ///
    /// Should also send SIGWINCH to the child so curses-style apps redraw.
    func resize(cols: Int, rows: Int)

    /// Recent rendered lines from the terminal scrollback.
    ///
    /// Used by Mission Control tiles and inbox previews. May be empty if the
    /// terminal has not yet been started.
    func recentLines(_ count: Int) -> [String]

    /// Terminate the child process (sends SIGTERM, then SIGKILL after timeout).
    func terminate()
}

/// Configuration applied at start-time.
public struct TerminalStartConfig: Sendable, Equatable {
    public var command: String
    public var args: [String]
    public var env: [String: String]
    public var cwd: URL?
    public var initialCols: Int
    public var initialRows: Int

    public init(
        command: String,
        args: [String] = [],
        env: [String: String] = [:],
        cwd: URL? = nil,
        initialCols: Int = 80,
        initialRows: Int = 24
    ) {
        self.command = command
        self.args = args
        self.env = env
        self.cwd = cwd
        self.initialCols = initialCols
        self.initialRows = initialRows
    }

    /// Default zsh login shell startup config.
    public static var zshLogin: TerminalStartConfig {
        TerminalStartConfig(
            command: "/bin/zsh",
            args: ["-l"],
            env: ["TERM": "xterm-256color", "LANG": "en_US.UTF-8"]
        )
    }
}
