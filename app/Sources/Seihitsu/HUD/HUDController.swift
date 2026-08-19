import AppKit
import SwiftUI

/// Owns the panel + its SwiftUI view model. Thin surface the AppDelegate/menu/hotkeys drive.
@MainActor
final class HUDController {
    var onStateChange: ((GlyphState) -> Void)?

    static let size = NSSize(width: 620, height: 460)
    static let corner: CGFloat = 20

    private let vm: HUDViewModel
    private let panel: HUDPanel
    private let router: ModelRouter
    private var clickThrough = false
    private var hasPositioned = false   // center only on first show; then keep where the user moved it

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
        // self is fully initialized here, so it is safe to capture.
        vm.onCaptureRequested = { [weak self] in self?.captureAndRoute() }
    }

    // MARK: HUD visibility

    func toggle() {
        if panel.isVisible { hide() } else { show() }
    }

    func show() {
        if !hasPositioned { centre(); hasPositioned = true }   // keep the user's position after the first open
        panel.orderFrontRegardless()
        panel.makeKey()
        vm.requestFocus()
        Log.log("HUD shown (level=floating, key=\(panel.isKeyWindow))")
    }

    func hide() {
        panel.orderOut(nil)
        Log.log("HUD hidden")
    }

    /// Toggle voice listening (shows the HUD if hidden).
    func toggleListen() {
        if !panel.isVisible { show() }
        vm.toggleListen()
    }

    func toggleClickThrough() {
        clickThrough.toggle()
        panel.ignoresMouseEvents = clickThrough
        vm.clickThrough = clickThrough
    }

    /// Reflect the active provider name in the HUD (called after a switch).
    func refreshModel() { vm.modelName = router.active.name }

    /// Debug: flip the HUD out of `.none` so it appears in screenshots/screen shares, for
    /// troubleshooting. Toggling back restores capture exclusion.
    private var revealed = false
    func toggleCaptureVisibility() {
        revealed.toggle()
        panel.sharingType = revealed ? .readOnly : .none
        if !panel.isVisible { show() }
        vm.statusLine = revealed ? "VISIBLE TO CAPTURE (debug) — screenshot now, then toggle off" : "hidden from capture again"
        Log.log("capture-visibility: \(revealed ? "readOnly (revealed)" : "none (hidden)")")
    }

    // MARK: Selection capture

    /// Grab the current selection (in whatever app is frontmost) then act on it. Capture runs
    /// off the main thread because the synthetic-copy fallback briefly waits on the pasteboard.
    func captureAndRoute() {
        Log.log("capture: triggered; AX trusted=\(SelectionCapture.isTrusted(prompt: false))")
        Task.detached {
            let captured = SelectionCapture.capture()
            await MainActor.run { [weak self] in
                Log.log("capture: result=\(captured.map { "\($0.text.count) chars code=\($0.looksLikeCode) q=\($0.looksLikeQuestion) src=\($0.source ?? "?")" } ?? "nil")")
                self?.route(captured)
            }
        }
    }

    private func route(_ captured: CapturedSelection?) {
        show()
        guard let captured else {
            if !SelectionCapture.isTrusted(prompt: true) {
                vm.answer = "Grant Accessibility to Seihitsu:\nSystem Settings > Privacy & Security > Accessibility.\nThen highlight text and press ⌥C again."
                vm.statusLine = "Needs Accessibility permission"
            } else {
                vm.statusLine = "No text selected."
            }
            return
        }
        if captured.looksLikeQuestion {
            vm.answerCapturedQuestion(captured.text, source: captured.source)
        } else if captured.looksLikeCode {
            vm.fixCapturedCode(captured.text, source: captured.source)
        } else {
            vm.loadContext(captured.text, kind: .selection, source: captured.source)
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
