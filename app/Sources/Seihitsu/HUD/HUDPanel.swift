import AppKit

/// The overlay window. `sharingType = .none` is the load-bearing property: it keeps the
/// panel out of screenshots and screen shares while still compositing to the display.
final class HUDPanel: NSPanel {
    init(contentView: NSView) {
        super.init(contentRect: NSRect(origin: .zero, size: contentView.frame.size),
                   styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
                   backing: .buffered, defer: false)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        level = .screenSaver
        sharingType = .none
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        isMovableByWindowBackground = true
        isFloatingPanel = true
        hidesOnDeactivate = false
        becomesKeyOnlyIfNeeded = false
        self.contentView = contentView
    }

    // A borderless panel must opt in to key status to receive typed input.
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
