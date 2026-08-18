import AppKit

/// The menu-bar status item and its menu. Glyph reflects idle/thinking; the Model submenu
/// switches the active provider.
final class MenuBarController: NSObject {
    var onToggleHUD: (() -> Void)?
    var onRunSelfTest: (() -> Void)?
    var onOpenSettings: (() -> Void)?
    var onQuit: (() -> Void)?

    /// Provider list + selection, supplied by the router.
    var providerList: () -> [(id: String, name: String, active: Bool)] = { [] }
    var onSelectProvider: ((String) -> Void)?

    private var statusItem: NSStatusItem?
    private let modelMenu = NSMenu()

    func install() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem = item
        applyGlyph(.idle)

        let menu = NSMenu()
        menu.addItem(withTitle: "Show / Hide HUD", action: #selector(toggleHUD), keyEquivalent: "").target = self

        let modelItem = NSMenuItem(title: "Model", action: nil, keyEquivalent: "")
        modelItem.submenu = modelMenu
        menu.addItem(modelItem)

        menu.addItem(.separator())
        menu.addItem(withTitle: "Settings…", action: #selector(openSettings), keyEquivalent: ",").target = self
        menu.addItem(withTitle: "Run capture self-test", action: #selector(runSelfTest), keyEquivalent: "").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Seihitsu", action: #selector(quit), keyEquivalent: "q").target = self
        item.menu = menu

        rebuildProviderMenu()
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
    @objc private func runSelfTest() { onRunSelfTest?() }
    @objc private func openSettings() { onOpenSettings?() }
    @objc private func quit() { onQuit?() }
    @objc private func selectProvider(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String else { return }
        onSelectProvider?(id)
        rebuildProviderMenu()
    }
}
