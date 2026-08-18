import AppKit
import SwiftUI

/// Owns the panel + its SwiftUI view model. Thin surface the AppDelegate/menu/hotkeys drive.
@MainActor
final class HUDController {
    var onStateChange: ((GlyphState) -> Void)?

    static let size = NSSize(width: 560, height: 380)
    static let corner: CGFloat = 20

    private let vm: HUDViewModel
    private let panel: HUDPanel
    private let router: ModelRouter
    private var clickThrough = false

    init(router: ModelRouter) {
        self.router = router
        let vm = HUDViewModel(resolveBackend: { router.backend() })
        self.vm = vm
        vm.modelName = router.active.name

        // Glass base: a behind-window vibrancy view provides the frosted blur of whatever
        // sits behind the panel. The SwiftUI content renders transparently on top.
        let bounds = NSRect(origin: .zero, size: Self.size)
        let glass = NSVisualEffectView(frame: bounds)
        glass.material = .hudWindow
        glass.blendingMode = .behindWindow
        glass.state = .active
        glass.wantsLayer = true
        glass.layer?.cornerRadius = Self.corner
        glass.layer?.masksToBounds = true

        // NSHostingView renders transparently, so the vibrancy shows through behind it.
        let host = NSHostingView(rootView: HUDView(vm: vm))
        host.frame = bounds
        host.autoresizingMask = [.width, .height]
        glass.addSubview(host)

        panel = HUDPanel(contentView: glass)
        vm.onGlyph = { [weak self] g in self?.onStateChange?(g) }
    }

    // MARK: HUD visibility

    func toggle() {
        if panel.isVisible { panel.orderOut(nil) } else { show() }
    }

    func show() {
        centre()
        panel.orderFrontRegardless()
        panel.makeKey()
        vm.requestFocus()
    }

    func toggleClickThrough() {
        clickThrough.toggle()
        panel.ignoresMouseEvents = clickThrough
        vm.clickThrough = clickThrough
    }

    /// Reflect the active provider name in the HUD (called after a switch).
    func refreshModel() { vm.modelName = router.active.name }

    // MARK: Selection capture

    /// Grab the current selection (in whatever app is frontmost) then act on it. Capture runs
    /// off the main thread because the synthetic-copy fallback briefly waits on the pasteboard.
    func captureAndRoute() {
        Task.detached {
            let captured = SelectionCapture.capture()
            await MainActor.run { [weak self] in self?.route(captured) }
        }
    }

    private func route(_ captured: CapturedSelection?) {
        show()
        guard let captured else {
            if !SelectionCapture.isTrusted(prompt: true) {
                vm.answer = "Grant Accessibility to Seihitsu:\nSystem Settings > Privacy & Security > Accessibility.\nThen highlight text and press ⌘⇧Return again."
                vm.statusLine = "Needs Accessibility permission"
            } else {
                vm.statusLine = "No text selected."
            }
            return
        }
        if captured.looksLikeQuestion {
            vm.answerCapturedQuestion(captured.text, source: captured.source)
        } else {
            vm.loadContext(captured.text, kind: captured.looksLikeCode ? .code : .selection, source: captured.source)
        }
    }

    // MARK: Self-test

    func runCaptureSelfTest() {
        if !panel.isVisible { show() }
        vm.answer = "Running capture self-test…"
        Task { @MainActor in
            vm.answer = await CaptureSelfTest.run()
        }
    }

    private func centre() {
        guard let screen = NSScreen.main else { return }
        let f = screen.visibleFrame
        let size = panel.frame.size
        let origin = NSPoint(x: f.midX - size.width / 2, y: f.midY - size.height / 2 + 120)
        panel.setFrameOrigin(origin)
    }
}
