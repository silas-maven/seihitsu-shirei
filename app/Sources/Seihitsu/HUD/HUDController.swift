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
    private let picker = RegionPicker()
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
        vm.onReadScreenRequested = { [weak self] in self?.readScreenAndRoute() }
        vm.onSeeScreenRequested = { [weak self] in self?.seeScreenAndRoute() }
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

    /// Cycle answer speed (Full / Brief / Blitz). Shows the HUD so the change is visible.
    func cycleSpeed() {
        if !panel.isVisible { show() }
        vm.cycleMode()
    }

    /// Current answer-speed mode (raw value), for the menu-bar Speed submenu.
    var currentModeRaw: String { vm.mode.rawValue }

    /// Set the answer-speed mode from the menu (no HUD popup).
    func setMode(_ raw: String) {
        guard let m = AnswerMode(rawValue: raw) else { return }
        vm.mode = m
        vm.statusLine = "Speed: \(m.label)"
    }

    /// Current code-handling mode (raw value), for the menu-bar Code submenu.
    var currentCodeActionRaw: String { vm.codeAction.rawValue }

    /// Set how captured code is handled (Explain vs Fix) from the menu.
    func setCodeAction(_ raw: String) {
        guard let a = CodeAction(rawValue: raw) else { return }
        vm.codeAction = a
        vm.statusLine = "Code: \(a.label)"
    }

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
            vm.reviewCode(captured.text, source: captured.source)
        } else {
            vm.loadContext(captured.text, kind: .selection, source: captured.source)
        }
    }

    // MARK: Screen reading (OCR)

    /// Screenshot the saved region, OCR it, and answer the question it contains. Works in apps
    /// that block text selection, and uses Screen Recording (not Accessibility).
    func readScreenAndRoute() {
        show()
        guard ScreenReader.ensurePermission() else {
            vm.answer = "Grant Screen Recording to Seihitsu:\nSystem Settings > Privacy & Security > Screen Recording.\nThen relaunch and press ⌥V."
            vm.statusLine = "Needs Screen Recording permission"
            Log.log("screen-read: blocked, no Screen Recording permission")
            return
        }
        let region = ScreenRegionStore.region
        vm.beginScreenRead(region: ScreenRegionStore.describe)
        Log.log("screen-read: triggered; region=\(ScreenRegionStore.describe)")
        Task { @MainActor in
            let text = await ScreenReader.read(region: region)
            if let text {
                if SelectionCapture.looksLikeCode(text) {
                    Log.log("screen-read: OCR \(text.count) chars (code -> review)")
                    vm.reviewCode(text, source: nil)
                } else {
                    Log.log("screen-read: OCR \(text.count) chars")
                    vm.answerScreenText(text, source: nil)
                }
            } else {
                Log.log("screen-read: no readable text")
                vm.screenReadEmpty()
            }
        }
    }

    /// Send the region screenshot to a vision model (⌥⇧V), instead of OCR. For diagrams/images.
    func seeScreenAndRoute() {
        show()
        guard ScreenReader.ensurePermission() else {
            vm.answer = "Grant Screen Recording to Seihitsu:\nSystem Settings > Privacy & Security > Screen Recording.\nThen relaunch and press ⌥⇧V."
            vm.statusLine = "Needs Screen Recording permission"
            return
        }
        let region = ScreenRegionStore.region
        vm.beginScreenRead(region: ScreenRegionStore.describe + " (image)")
        Log.log("screen-see: triggered; region=\(ScreenRegionStore.describe)")
        Task { @MainActor in
            if let img = await ScreenReader.readImage(region: region) {
                Log.log("screen-see: image \(img.count) bytes")
                vm.answerScreenImage(img, source: nil)
            } else {
                Log.log("screen-see: capture failed")
                vm.screenReadEmpty()
            }
        }
    }

    // MARK: Auto-read (watch the region, answer new questions)

    private var autoTask: Task<Void, Never>?
    private var lastAutoText = ""       // last OCR reading seen (for stability)
    private var lastAnsweredText = ""   // last text actually answered (avoid repeats)
    private var autoStable = 0

    var autoReadOn: Bool { vm.autoReading }

    /// Toggle auto-read. When on, the saved region is polled locally and a new, settled question
    /// is answered automatically. OCR is on-device, so polling is free; only a genuine change
    /// spends a model call.
    func toggleAutoRead() {
        if vm.autoReading { stopAutoRead() } else { startAutoRead() }
    }

    private func startAutoRead() {
        guard ScreenReader.ensurePermission() else {
            show()
            vm.answer = "Grant Screen Recording to Seihitsu, then relaunch and turn Auto-read on again."
            vm.statusLine = "Needs Screen Recording permission"
            return
        }
        show()
        vm.autoReading = true
        lastAutoText = ""; lastAnsweredText = ""; autoStable = 0
        vm.statusLine = "Auto-read ON (\(ScreenRegionStore.describe))"
        Log.log("auto-read: ON region=\(ScreenRegionStore.describe)")
        autoTask = Task { @MainActor in
            while self.vm.autoReading && !Task.isCancelled {
                await self.autoTick()
                try? await Task.sleep(nanoseconds: 1_000_000_000)   // ~1s poll
            }
        }
    }

    private func stopAutoRead() {
        vm.autoReading = false
        autoTask?.cancel(); autoTask = nil
        vm.statusLine = "Auto-read off"
        Log.log("auto-read: OFF")
    }

    private func autoTick() async {
        guard vm.state != .thinking else { return }         // don't overlap a request
        guard let text = await ScreenReader.read(region: ScreenRegionStore.region) else { return }
        let norm = Self.normalise(text)
        guard norm.count >= 6 else { return }               // ignore stray fragments
        // Require the reading to be the same twice running, so we don't answer a mid-render frame.
        if norm == lastAutoText { autoStable += 1 } else { autoStable = 0; lastAutoText = norm }
        guard autoStable >= 1 else { return }
        guard norm != lastAnsweredText else { return }      // same question already answered
        lastAnsweredText = norm
        Log.log("auto-read: new question \(norm.count) chars -> answering")
        vm.answerScreenText(text, source: nil)
    }

    private static func normalise(_ s: String) -> String {
        s.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    /// Let the user drag out the area Seihitsu reads. Saved and reused by ⌥V. Cancelling (Esc)
    /// leaves the current region unchanged.
    func pickRegion() {
        hide()
        picker.present { [weak self] rect in
            guard let self else { return }
            self.show()
            if let rect {
                ScreenRegionStore.region = rect
                self.vm.statusLine = "Screen region set: \(ScreenRegionStore.describe)"
                Log.log("screen-read: region set to \(ScreenRegionStore.describe)")
            } else {
                self.vm.statusLine = "Region unchanged (\(ScreenRegionStore.describe))"
            }
        }
    }

    /// Clear the saved region so ⌥V reads the whole display again.
    func clearRegion() {
        ScreenRegionStore.region = nil
        if !panel.isVisible { show() }
        vm.statusLine = "Screen region cleared (reads full screen)"
        Log.log("screen-read: region cleared")
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
