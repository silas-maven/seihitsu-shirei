import AppKit

/// Full-screen drag-to-select overlay for defining the area Seihitsu reads with ⌥V.
/// Calls the completion with the chosen rect in main-screen points (bottom-left origin), or
/// `nil` if the user cancelled (Esc) or drew nothing meaningful. The overlay is itself
/// `sharingType = .none`, so it never leaks into a capture.
@MainActor
final class RegionPicker {
    private var window: NSWindow?
    private var completion: ((CGRect?) -> Void)?

    func present(_ done: @escaping (CGRect?) -> Void) {
        guard window == nil, let screen = NSScreen.main else { done(nil); return }
        completion = done

        let view = RegionSelectView(frame: NSRect(origin: .zero, size: screen.frame.size))
        view.onFinish = { [weak self] rect in self?.finish(rect, screen: screen) }

        let win = KeyableBorderlessWindow(contentRect: screen.frame, styleMask: [.borderless],
                                          backing: .buffered, defer: false)
        win.isOpaque = false
        win.backgroundColor = .clear
        win.level = .screenSaver
        win.sharingType = .none
        win.ignoresMouseEvents = false
        win.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        win.contentView = view
        win.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window = win
    }

    private func finish(_ rectInWindow: CGRect?, screen: NSScreen) {
        window?.orderOut(nil)
        window = nil
        let done = completion
        completion = nil
        guard let rectInWindow, rectInWindow.width > 4, rectInWindow.height > 4 else { done?(nil); return }
        // The window covers screen.frame, so its coordinates share the screen's origin.
        let screenRect = CGRect(x: screen.frame.origin.x + rectInWindow.origin.x,
                                y: screen.frame.origin.y + rectInWindow.origin.y,
                                width: rectInWindow.width, height: rectInWindow.height)
        done?(screenRect)
    }
}

/// Borderless windows cannot become key by default, which would block the Esc keyDown.
private final class KeyableBorderlessWindow: NSWindow {
    override var canBecomeKey: Bool { true }
}

private final class RegionSelectView: NSView {
    var onFinish: ((CGRect?) -> Void)?
    private var start: NSPoint?
    private var current: NSRect = .zero
    private let accent = NSColor(calibratedRed: 0.13, green: 0.83, blue: 0.93, alpha: 1)

    override var acceptsFirstResponder: Bool { true }
    override func viewDidMoveToWindow() { window?.makeFirstResponder(self) }

    override func draw(_ dirtyRect: NSRect) {
        NSColor.black.withAlphaComponent(0.35).setFill()
        NSBezierPath(rect: bounds).fill()

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .medium),
            .foregroundColor: NSColor.white.withAlphaComponent(0.92),
        ]
        let hint = NSAttributedString(string: "Drag the area Seihitsu should read.  Esc to cancel.", attributes: attrs)
        hint.draw(at: NSPoint(x: bounds.midX - hint.size().width / 2, y: bounds.maxY - 64))

        if current.width > 0, current.height > 0 {
            NSColor.white.withAlphaComponent(0.10).setFill()
            NSBezierPath(rect: current).fill()
            accent.setStroke()
            let path = NSBezierPath(rect: current)
            path.lineWidth = 2
            path.stroke()
            let dims = NSAttributedString(string: "\(Int(current.width)) × \(Int(current.height))", attributes: attrs)
            dims.draw(at: NSPoint(x: current.minX + 4, y: current.maxY + 4))
        }
    }

    override func mouseDown(with e: NSEvent) {
        start = convert(e.locationInWindow, from: nil)
        current = .zero
        needsDisplay = true
    }

    override func mouseDragged(with e: NSEvent) {
        guard let s = start else { return }
        let p = convert(e.locationInWindow, from: nil)
        current = NSRect(x: min(s.x, p.x), y: min(s.y, p.y),
                         width: abs(p.x - s.x), height: abs(p.y - s.y))
        needsDisplay = true
    }

    override func mouseUp(with e: NSEvent) {
        onFinish?(current.width > 4 && current.height > 4 ? current : nil)
    }

    override func keyDown(with e: NSEvent) {
        if e.keyCode == 53 { onFinish?(nil) }   // Esc
    }
}
