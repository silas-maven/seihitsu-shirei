import AppKit

/// Menu-bar-only agent entry point. `main()` is main-actor isolated so it can construct the
/// AppKit objects directly.
@main
struct SeihitsuApp {
    @MainActor static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        // Keep the delegate alive for the process lifetime (NSApplication.delegate is weak).
        objc_setAssociatedObject(app, &delegateKey, delegate, .OBJC_ASSOCIATION_RETAIN)
        app.run()
    }
}

private nonisolated(unsafe) var delegateKey: UInt8 = 0
