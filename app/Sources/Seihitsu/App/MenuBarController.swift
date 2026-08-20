import AppKit

/// The menu-bar status item and its menu. Glyph reflects idle/thinking; the Model submenu
/// switches the active provider; the Speed submenu switches answer length.
final class MenuBarController: NSObject, NSMenuDelegate {
    var onToggleHUD: (() -> Void)?
    var onCaptureSelection: (() -> Void)?
    var onReadScreen: (() -> Void)?
    var onSeeScreen: (() -> Void)?
    var onAutoRead: (() -> Void)?
    var isAutoReadOn: () -> Bool = { false }
    var onSetRegion: (() -> Void)?
    var onClearRegion: (() -> Void)?
    var onListen: (() -> Void)?
    var onRunSelfTest: (() -> Void)?
    var onOpenSettings: (() -> Void)?
    var onGrantAccessibility: (() -> Void)?
    var onRevealLogs: (() -> Void)?
    var onToggleReveal: (() -> Void)?
    var onQuit: (() -> Void)?

    /// Provider list + selection, supplied by the router.
    var providerList: () -> [(id: String, name: String, active: Bool)] = { [] }
    var onSelectProvider: ((String) -> Void)?

    /// Answer-speed list + selection, supplied by the HUD (Full / Brief / Blitz).
    var modeList: () -> [(id: String, name: String, active: Bool)] = { [] }
    var onSelectMode: ((String) -> Void)?

    /// Code-handling list + selection, supplied by the HUD (Explain / Fix).
    var codeList: () -> [(id: String, name: String, active: Bool)] = { [] }
    var onSelectCode: ((String) -> Void)?

    private var statusItem: NSStatusItem?
    private let modelMenu = NSMenu()
    private let speedMenu = NSMenu()
    private let codeMenu = NSMenu()
    private weak var autoItem: NSMenuItem?

    func install() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem = item
        applyGlyph(.idle)

        let menu = NSMenu()
        menu.delegate = self   // keep the Auto-read checkmark current when the menu opens
        menu.addItem(withTitle: "Show / Hide HUD  (⌥Space)", action: #selector(toggleHUD), keyEquivalent: "").target = self
        menu.addItem(withTitle: "Capture selection  (⌥C)", action: #selector(captureSelection), keyEquivalent: "").target = self
        menu.addItem(withTitle: "Read screen  (⌥V)", action: #selector(readScreen), keyEquivalent: "").target = self
        menu.addItem(withTitle: "See screen as image  (⌥⇧V)", action: #selector(seeScreen), keyEquivalent: "").target = self
        let auto = NSMenuItem(title: "Auto-read region  (⌥A)", action: #selector(autoRead), keyEquivalent: "")
        auto.target = self
        auto.state = isAutoReadOn() ? .on : .off
        menu.addItem(auto)
        autoItem = auto
        menu.addItem(withTitle: "Listen  (⌥L)", action: #selector(listen), keyEquivalent: "").target = self

        let modelItem = NSMenuItem(title: "Model", action: nil, keyEquivalent: "")
        modelItem.submenu = modelMenu
        menu.addItem(modelItem)

        let speedItem = NSMenuItem(title: "Speed  (⌥⇧S)", action: nil, keyEquivalent: "")
        speedItem.submenu = speedMenu
        speedMenu.delegate = self     // rebuild on open so the checkmark reflects HUD/hotkey changes
        menu.addItem(speedItem)

        let codeItem = NSMenuItem(title: "Code", action: nil, keyEquivalent: "")
        codeItem.submenu = codeMenu
        codeMenu.delegate = self
        menu.addItem(codeItem)

        menu.addItem(.separator())
        menu.addItem(withTitle: "Set screen region…", action: #selector(setRegion), keyEquivalent: "").target = self
        menu.addItem(withTitle: "Clear screen region", action: #selector(clearRegion), keyEquivalent: "").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Settings…", action: #selector(openSettings), keyEquivalent: "").target = self
        menu.addItem(withTitle: "Grant Accessibility…", action: #selector(grantAccessibility), keyEquivalent: "").target = self
        menu.addItem(withTitle: "Run capture self-test", action: #selector(runSelfTest), keyEquivalent: "").target = self
        menu.addItem(withTitle: "Reveal Logs in Finder", action: #selector(revealLogs), keyEquivalent: "").target = self
        menu.addItem(withTitle: "Reveal HUD in Screenshots (debug)", action: #selector(toggleReveal), keyEquivalent: "").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Seihitsu", action: #selector(quit), keyEquivalent: "q").target = self
        item.menu = menu

        rebuildProviderMenu()
        rebuildSpeedMenu()
        rebuildCodeMenu()
    }

    func rebuildSpeedMenu() { fill(speedMenu, from: modeList(), action: #selector(selectMode(_:))) }
    func rebuildCodeMenu()  { fill(codeMenu, from: codeList(), action: #selector(selectCode(_:))) }

    private func fill(_ menu: NSMenu, from rows: [(id: String, name: String, active: Bool)], action: Selector) {
        menu.removeAllItems()
        for r in rows {
            let it = NSMenuItem(title: r.name, action: action, keyEquivalent: "")
            it.target = self
            it.representedObject = r.id
            it.state = r.active ? .on : .off
            menu.addItem(it)
        }
        if menu.items.isEmpty {
            let empty = NSMenuItem(title: "—", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            menu.addItem(empty)
        }
    }

    /// Keep the Speed, Code, and Auto-read state current whether it was changed here, in the HUD,
    /// or via a hotkey.
    func menuNeedsUpdate(_ menu: NSMenu) {
        if menu === speedMenu { rebuildSpeedMenu() }
        else if menu === codeMenu { rebuildCodeMenu() }
        else { autoItem?.state = isAutoReadOn() ? .on : .off }
    }

    func rebuildProviderMenu() {
        modelMenu.removeAllItems()
        for p in providerList() {
            let it = NSMenuItem(title: p.name, action: #selector(selectProvider(_:)), keyEquivalent: "")
            it.target = self
            it.representedObject = p.id
            it.state = p.active ? .on : .off
            modelMenu.addItem(it)
        }
        if modelMenu.items.isEmpty {
            let empty = NSMenuItem(title: "No providers", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            modelMenu.addItem(empty)
        }
    }

    func setGlyph(_ g: GlyphState) { applyGlyph(g) }

    private func applyGlyph(_ g: GlyphState) {
        guard let button = statusItem?.button else { return }
        let name = (g == .thinking) ? "hourglass" : "brain"
        if let img = NSImage(systemSymbolName: name, accessibilityDescription: "Seihitsu") {
            img.isTemplate = true
            button.image = img
            button.title = ""
        } else {
            button.image = nil
            button.title = (g == .thinking) ? "…" : "S"
        }
    }

    @objc private func toggleHUD() { onToggleHUD?() }
    @objc private func captureSelection() { onCaptureSelection?() }
    @objc private func readScreen() { onReadScreen?() }
    @objc private func seeScreen() { onSeeScreen?() }
    @objc private func autoRead() { onAutoRead?() }
    @objc private func setRegion() { onSetRegion?() }
    @objc private func clearRegion() { onClearRegion?() }
    @objc private func listen() { onListen?() }
    @objc private func runSelfTest() { onRunSelfTest?() }
    @objc private func openSettings() { onOpenSettings?() }
    @objc private func grantAccessibility() { onGrantAccessibility?() }
    @objc private func revealLogs() { onRevealLogs?() }
    @objc private func toggleReveal() { onToggleReveal?() }
    @objc private func quit() { onQuit?() }
    @objc private func selectProvider(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String else { return }
        onSelectProvider?(id)
        rebuildProviderMenu()
    }
    @objc private func selectMode(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String else { return }
        onSelectMode?(id)
        rebuildSpeedMenu()
    }
    @objc private func selectCode(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String else { return }
        onSelectCode?(id)
        rebuildCodeMenu()
    }
}
