// SwiftTermEmulator — production TerminalEmulator backed by SwiftTerm's
// LocalProcessTerminalView (handles PTY, fork, exec, and rendering in one).
// Phase 2 ships this as the only emulator. Phase 11 polishes its chrome.
// Phase 5 layers an output-byte tap on top via LocalProcessDelegate.

import AppKit
import Foundation
import SwiftTerm

@MainActor
public final class SwiftTermEmulator: NSObject, TerminalEmulator {
    public let id = UUID()
    public private(set) var attachedProcessID: pid_t?
    public private(set) var exitCode: Int32?
    public private(set) var isRunning = false

    public var view: NSView { terminalView }

    /// Underlying SwiftTerm view; exposed `internal` so tests in the same
    /// module can poke at the buffer.
    let terminalView: LocalProcessTerminalView

    /// Stream of raw output bytes from the PTY.
    ///
    /// Driven by `processOutput`. Wired up to a continuation in `init`.
    /// Consumers iterate this in Phase 5 (agent profile parsing).
    public let outputStream: AsyncStream<Data>
    private let outputContinuation: AsyncStream<Data>.Continuation

    public init(font: NSFont = .monospacedSystemFont(ofSize: 13, weight: .regular)) {
        let (stream, continuation) = AsyncStream<Data>.makeStream()
        self.outputStream = stream
        self.outputContinuation = continuation

        let view = LocalProcessTerminalView(frame: .zero)
        view.font = font
        self.terminalView = view

        super.init()
        view.processDelegate = self
    }

    public func start(
        command: String,
        args: [String],
        env: [String: String],
        cwd: URL?
    ) {
        guard !isRunning else { return }

        let mergedEnv: [String] = mergedEnvironment(extra: env, cwd: cwd)
        let argList: [String] = args

        terminalView.startProcess(
            executable: command,
            args: argList,
            environment: mergedEnv,
            execName: nil
        )
        isRunning = true
    }

    public func send(_ text: String) {
        terminalView.send(txt: text)
    }

    public func resize(cols: Int, rows: Int) {
        // SwiftTerm computes columns/rows from font metrics on layout. We
        // expose this hook for callers that want to force a size; SwiftTerm
        // also re-emits SIGWINCH internally when its view bounds change.
        let terminal = terminalView.getTerminal()
        terminal.resize(cols: cols, rows: rows)
    }

    public func recentLines(_ count: Int) -> [String] {
        // SwiftTerm's Buffer.lines is internal; reading scrollback requires
        // either selection-based extraction or a fork of SwiftTerm. Mission
        // Control (Phase 7) is the only consumer; it'll wire this up via a
        // ring-buffer fed off `outputStream` rather than introspecting the
        // SwiftTerm buffer. Until then, return [].
        _ = count
        return []
    }

    public func terminate() {
        guard isRunning, let pid = attachedProcessID else {
            isRunning = false
            return
        }
        kill(pid, SIGTERM)
        isRunning = false
    }

    /// Merge user environment with the requested overrides plus `PWD` if cwd set.
    private func mergedEnvironment(extra: [String: String], cwd: URL?) -> [String] {
        var env = ProcessInfo.processInfo.environment
        for (key, value) in extra {
            env[key] = value
        }
        if let cwd {
            env["PWD"] = cwd.path
        }
        if env["TERM"] == nil {
            env["TERM"] = "xterm-256color"
        }
        return env.map { "\($0.key)=\($0.value)" }
    }
}

// MARK: - LocalProcessTerminalViewDelegate

extension SwiftTermEmulator: LocalProcessTerminalViewDelegate {
    nonisolated public func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {
        // SwiftTerm informs us; we don't need to act since the underlying
        // PTY already received SIGWINCH via the view's own bookkeeping.
        _ = (newCols, newRows)
    }

    nonisolated public func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
        // Phase 11 will surface this in the pane chrome.
        _ = title
    }

    nonisolated public func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {
        // Phase 5 will use OSC 7 directory updates to track agent cwd.
        _ = directory
    }

    nonisolated public func processTerminated(source: TerminalView, exitCode: Int32?) {
        let continuation = outputContinuation
        Task { @MainActor in
            self.exitCode = exitCode
            self.isRunning = false
            continuation.finish()
        }
    }

    nonisolated public func processOutput(source: LocalProcessTerminalView, data: ArraySlice<UInt8>) {
        // Mirror PTY output bytes for Phase 5+ consumers.
        let copy = Data(data)
        outputContinuation.yield(copy)
    }
}
