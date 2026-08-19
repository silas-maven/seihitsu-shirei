import AppKit

/// The overlay window. `sharingType = .none` is the load-bearing property: it keeps the
/// panel out of screenshots and screen shares while still compositing to the display.
final class HUDPanel: NSPanel {
    init(contentView: NSView) {
        super.init(contentRect: NSRect(origin: .zero, size: contentView.frame.size),
                   styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView, .resizable],
                   backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        // .floating sits above normal app windows but BELOW the menu bar and system
        // dialogs. .screenSaver (the old value) floated above everything and blocked
        // clicks to System Settings and other apps.
        level = .floating
        sharingType = .none
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        isMovableByWindowBackground = true
        isFloatingPanel = true
        hidesOnDeactivate = false
        becomesKeyOnlyIfNeeded = false
        minSize = NSSize(width: 420, height: 280)   // drag any edge to resize
        self.contentView = contentView
    }

    // A borderless panel must opt in to key status to receive typed input.
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    // Esc dismisses the HUD.
    override func cancelOperation(_ sender: Any?) { orderOut(nil) }
}
