# Hangar 0.1.1

Bug-fix release on top of v0.1.0.

## What changed

**Terminal now renders on launch.** v0.1.0 shipped with a broken view hierarchy where the SwiftTerm `NSView` never appeared and the window opened empty. v0.1.1 wraps the terminal in a `TerminalHostView` container that:

- pins the terminal `NSView` to its bounds with Auto Layout constraints
- grabs first responder when the window appears, so keystrokes are accepted immediately without needing to click first
- routes mouse-down clicks back to the terminal view

The chrome is also cleaner:

- Transparent title bar with proper traffic-light strip (no more overlap with the prompt)
- Dark window background that matches the terminal so the chrome blends edge-to-edge
- 28pt top padding inside the content area so the first line of output sits clear of the title bar
- Window opens centered at a sensible 960×600 default

## Install

```bash
brew upgrade --cask hangar
# or fresh:
brew tap robzilla1738/hangar
brew install --cask hangar
```

Or grab `Hangar-0.1.1.dmg` from this release and drag to `/Applications`.

## Verify

```
shasum -a 256 Hangar-0.1.1.dmg
# 2160a54f15992f7c35f177925140042707e16ca06e8cd10cb9616bea932c26ed
```

Signed and notarized under Developer ID `9F2JXY8TCK` (Robert Courson).

---

🤖 Generated with [Claude Code](https://claude.com/claude-code)
