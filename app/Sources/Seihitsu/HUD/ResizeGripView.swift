import AppKit

/// A reliably-grabbable resize handle for the borderless HUD. The OS resize border on a
/// borderless window is only a few pixels wide and easy to miss; this is a real 22pt target.
///
/// It overrides `mouseDownCanMoveWindow` to false so dragging it resizes the window (the panel
/// has `isMovableByWindowBackground`, which would otherwise move the window on any drag).
final class ResizeGripView: NSView {
    private var startFrame: NSRect = .zero
    private var startMouse: NSPoint = .zero
    private var hovering = false

    override var mouseDownCanMoveWindow: Bool { false }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        addTrackingArea(NSTrackingArea(rect: bounds,
                                       options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
                                       owner: self, userInfo: nil))
    }

    override func mouseEntered(with event: NSEvent) { hovering = true; needsDisplay = true }
    override func mouseExited(with event: NSEvent)  { hovering = false; needsDisplay = true }

    override func mouseDown(with event: NSEvent) {
        guard let w = window else { return }
        startFrame = w.frame
        startMouse = NSEvent.mouseLocation   // screen coordinates
    }

    override func mouseDragged(with event: NSEvent) {
        guard let w = window else { return }
        let now = NSEvent.mouseLocation
        let dx = now.x - startMouse.x
        let dy = now.y - startMouse.y                     // screen Y grows upward
        let newW = max(w.minSize.width, startFrame.width + dx)
        let newH = max(w.minSize.height, startFrame.height - dy)   // drag down -> taller
        let topY = startFrame.origin.y + startFrame.height          // keep the top edge pinned
        w.setFrame(NSRect(x: startFrame.origin.x, y: topY - newH, width: newW, height: newH),
                   display: true)
    }

    override func draw(_ dirtyRect: NSRect) {
        let cfg = NSImage.SymbolConfiguration(pointSize: 11, weight: .bold)
        guard let base = NSImage(systemSymbolName: "arrow.up.left.and.arrow.down.right",
                                 accessibilityDescription: "Resize")?.withSymbolConfiguration(cfg) else { return }
        let tint = NSColor.white.withAlphaComponent(hovering ? 0.85 : 0.4)
        let tinted = NSImage(size: base.size, flipped: false) { rect in
            base.draw(in: rect)
            tint.set()
            rect.fill(using: .sourceAtop)
            return true
        }
        let r = NSRect(x: bounds.midX - base.size.width / 2,
                       y: bounds.midY - base.size.height / 2,
                       width: base.size.width, height: base.size.height)
        tinted.draw(in: r)
    }
}
