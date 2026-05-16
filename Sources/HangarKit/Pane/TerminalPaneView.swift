// TerminalPaneView — SwiftUI host for a TerminalEmulator's NSView.
// One pane = one PaneViewModel = one TerminalEmulator instance.
//
// The terminal NSView is wrapped in a container that:
// - resizes its child to fill the available space (SwiftUI sizing).
// - makes the terminal first responder on appearance so keystrokes
//   are accepted immediately without needing to click first.

import AppKit
import HangarCore
import SwiftUI

public struct TerminalPaneView: NSViewRepresentable {
    private let viewModel: PaneViewModel

    public init(viewModel: PaneViewModel) {
        self.viewModel = viewModel
    }

    public func makeNSView(context: Context) -> TerminalHostView {
        let host = TerminalHostView()
        host.embed(viewModel.emulator.view)
        return host
    }

    public func updateNSView(_ host: TerminalHostView, context: Context) {
        host.embed(viewModel.emulator.view)
    }
}

/// AppKit container that owns the terminal NSView, pins it to its bounds,
/// and grabs first responder so keyboard input works on first launch.
public final class TerminalHostView: NSView {
    private weak var embedded: NSView?

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
        autoresizingMask = [.width, .height]
        translatesAutoresizingMaskIntoConstraints = true
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
    }

    func embed(_ child: NSView) {
        if child === embedded { return }
        embedded?.removeFromSuperview()
        child.translatesAutoresizingMaskIntoConstraints = false
        addSubview(child)
        NSLayoutConstraint.activate([
            child.leadingAnchor.constraint(equalTo: leadingAnchor),
            child.trailingAnchor.constraint(equalTo: trailingAnchor),
            child.topAnchor.constraint(equalTo: topAnchor),
            child.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        embedded = child
    }

    public override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let window, let target = embedded else { return }
        DispatchQueue.main.async {
            window.makeFirstResponder(target)
        }
    }

    public override var acceptsFirstResponder: Bool { true }

    public override func mouseDown(with event: NSEvent) {
        if let target = embedded, let window {
            window.makeFirstResponder(target)
        }
        super.mouseDown(with: event)
    }
}
