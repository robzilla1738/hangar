// ShellCommandDetector — heuristically spots the first token of a user-typed
// shell command in PTY output. Used by PaneViewModel to swap agent profiles
// when the user runs `claude`, `codex`, `hermes`, or any other registered
// binary, without depending on shell integration (OSC 133).
//
// The detector buffers up to ~512 bytes across chunks so commands split
// across feed calls still resolve. v0.3 will swap to a true OSC 133 parser.

import Foundation

public struct ShellCommandDetector: Sendable {
    /// Maximum tail bytes kept across calls to handle line splits.
    private static let maxBufferBytes = 512

    /// Matches a shell prompt followed by a command.
    ///
    /// E.g. `% claude` or `robert@host /path $ codex --help`. Captures the
    /// first token after the prompt sigil. The regex is intentionally
    /// conservative; trailing space or newline required so chunks split
    /// mid-word don't produce partial matches.
    private static let pattern: NSRegularExpression = makePattern()

    private static func makePattern() -> NSRegularExpression {
        let raw = #"(?m)(?:^|\n)[^\n]*?(?:\$|%|❯|>|#) ([A-Za-z][A-Za-z0-9_\-]+)(?: |\n)"#
        do {
            return try NSRegularExpression(pattern: raw)
        } catch {
            fatalError("ShellCommandDetector pattern failed to compile: \(error)")
        }
    }

    private var buffer: String = ""

    public init() {}

    /// Feed a fresh chunk of text from the PTY; returns command names
    /// observed since the last call (in order of appearance, deduplicated).
    public mutating func consume(_ text: String) -> [String] {
        buffer.append(text)
        if buffer.count > Self.maxBufferBytes * 2 {
            let drop = buffer.count - Self.maxBufferBytes
            buffer.removeFirst(drop)
        }

        let nsBuffer = buffer as NSString
        let range = NSRange(location: 0, length: nsBuffer.length)
        var seen: [String] = []
        var matchedEnd = 0

        Self.pattern.enumerateMatches(in: buffer, options: [], range: range) { match, _, _ in
            guard let match, match.numberOfRanges >= 2 else { return }
            let cmdRange = match.range(at: 1)
            guard cmdRange.location != NSNotFound else { return }
            let cmd = nsBuffer.substring(with: cmdRange)
            // Skip env-var assignments and obvious noise
            if cmd.contains("=") { return }
            if !seen.contains(cmd) {
                seen.append(cmd)
            }
            matchedEnd = match.range.location + match.range.length
        }

        // Trim consumed buffer; keep the unmatched tail so a split prompt
        // can complete on the next feed.
        if matchedEnd > 0, matchedEnd < nsBuffer.length {
            buffer = nsBuffer.substring(from: matchedEnd)
        } else if matchedEnd >= nsBuffer.length {
            buffer = ""
        }

        return seen
    }
}
