import AppKit
import SwiftUI

/// A normal titled window (not the .none HUD) for pasting credentials. The app is an
/// accessory, so we activate it explicitly to bring the window forward.
@MainActor
final class SettingsController {
    var onSaved: (() -> Void)?

    private var window: NSWindow?

    func show() {
        if window == nil {
            let vm = SettingsViewModel(onSaved: { [weak self] in self?.onSaved?() })
            let host = NSHostingController(rootView: SettingsView(vm: vm))
            let w = NSWindow(contentViewController: host)
            w.title = "Seihitsu Settings"
            w.styleMask = [.titled, .closable]
            w.isReleasedWhenClosed = false
            w.setContentSize(NSSize(width: 480, height: 600))
            window = w
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.center()
        window?.makeKeyAndOrderFront(nil)
    }
}
