import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBar: MenuBarController?
    private var hud: HUDController?
    private var router: ModelRouter?
    private let settings = SettingsController()
    private let hotkeys = Hotkeys()

    func applicationDidFinishLaunching(_ notification: Notification) {
        Log.log("launch: Seihitsu starting")
        let router = ModelRouter()
        self.router = router
        Log.log("launch: active provider=\(router.active.name)")

        let hud = HUDController(router: router)
        self.hud = hud

        let menuBar = MenuBarController()
        menuBar.onToggleHUD = { [weak hud] in hud?.toggle() }
        menuBar.onCaptureSelection = { [weak hud] in hud?.captureAndRoute() }
        menuBar.onReadScreen = { [weak hud] in hud?.readScreenAndRoute() }
        menuBar.onSeeScreen = { [weak hud] in hud?.seeScreenAndRoute() }
        menuBar.onAutoRead = { [weak hud] in hud?.toggleAutoRead() }
        menuBar.isAutoReadOn = { [weak hud] in hud?.autoReadOn ?? false }
        menuBar.onSetRegion = { [weak hud] in hud?.pickRegion() }
        menuBar.onClearRegion = { [weak hud] in hud?.clearRegion() }
        menuBar.onListen = { [weak hud] in hud?.toggleListen() }
        menuBar.onRunSelfTest = { [weak hud] in hud?.runCaptureSelfTest() }
        // Hide the HUD before the auth prompt so it can't float over System Settings.
        menuBar.onGrantAccessibility = { [weak hud] in
            hud?.hide()
            Log.log("accessibility: prompting for trust")
            SelectionCapture.isTrusted(prompt: true)
        }
        menuBar.onRevealLogs = {
            NSWorkspace.shared.selectFile(Log.fileURL.path,
                                          inFileViewerRootedAtPath: Log.fileURL.deletingLastPathComponent().path)
        }
        menuBar.onToggleReveal = { [weak hud] in hud?.toggleCaptureVisibility() }
        menuBar.onQuit = { NSApp.terminate(nil) }
        menuBar.providerList = { [weak router] in
            guard let router else { return [] }
            return router.providers.map { (id: $0.id, name: $0.name, active: $0.id == router.activeID) }
        }
        menuBar.onSelectProvider = { [weak router, weak hud] id in
            router?.setActive(id)
            hud?.refreshModel()
        }
        menuBar.modeList = { [weak hud] in
            guard let hud else { return [] }
            return AnswerMode.allCases.map { (id: $0.rawValue, name: $0.label, active: $0.rawValue == hud.currentModeRaw) }
        }
        menuBar.onSelectMode = { [weak hud] raw in hud?.setMode(raw) }
        menuBar.codeList = { [weak hud] in
            guard let hud else { return [] }
            return CodeAction.allCases.map { (id: $0.rawValue, name: $0.label, active: $0.rawValue == hud.currentCodeActionRaw) }
        }
        menuBar.onSelectCode = { [weak hud] raw in hud?.setCodeAction(raw) }
        menuBar.profileList = { [weak hud] in
            guard let hud else { return [] }
            return Profile.allCases.map { (id: $0.rawValue, name: $0.label, active: $0.rawValue == hud.currentProfileRaw) }
        }
        menuBar.onSelectProfile = { [weak hud] raw in hud?.setProfile(raw) }
        menuBar.onToggleCollect = { [weak hud] in hud?.toggleCollect() }
        menuBar.isCollectingOn = { [weak hud] in hud?.collectingOn ?? false }
        menuBar.onOpenSettings = { [weak self] in self?.hud?.hide(); self?.settings.show() }
        menuBar.install()
        self.menuBar = menuBar

        // When keys are saved, enable the matching API providers and refresh the switcher.
        settings.onSaved = { [weak router, weak menuBar] in
            for (account, providerID) in [("anthropic", "anthropic"), ("openai", "openai"), ("gemini", "gemini")] {
                if let key = Keychain.read(service: "Seihitsu.apikeys", account: account), !key.isEmpty {
                    router?.setProviderEnabled(providerID, true)
                }
            }
            menuBar?.rebuildProviderMenu()
        }

        hud.onStateChange = { [weak menuBar] glyph in menuBar?.setGlyph(glyph) }
        router.onChange = { [weak hud] in hud?.refreshModel() }

        hotkeys.onSummon = { [weak hud] in hud?.toggle() }
        hotkeys.onCapture = { [weak hud] in hud?.captureAndRoute() }
        hotkeys.onReadScreen = { [weak hud] in hud?.readScreenAndRoute() }
        hotkeys.onSeeScreen = { [weak hud] in hud?.seeScreenAndRoute() }
        hotkeys.onAutoRead = { [weak hud] in hud?.toggleAutoRead() }
        hotkeys.onListen = { [weak hud] in hud?.toggleListen() }
        hotkeys.onToggleClickThrough = { [weak hud] in hud?.toggleClickThrough() }
        hotkeys.onCycleSpeed = { [weak hud] in hud?.cycleSpeed() }
        hotkeys.register()

        installMainMenu()
        repairKeychainAccessOnce()

        // Debug aid: SEIHITSU_AUTOSHOW=1 opens the HUD on launch (used to exercise the
        // render path headlessly; the HUD itself is excluded from screen capture).
        if ProcessInfo.processInfo.environment["SEIHITSU_AUTOSHOW"] == "1" {
            hud.show()
        }
    }

    /// One-time migration: rewrite existing API keys so they carry the non-interactive ACL, ending
    /// the "enter your login keychain password" prompt on every launch. Prompts at most once (to
    /// read the existing key); after that the rewritten item never challenges again. The flag is
    /// only set on a clean pass, so a cancelled prompt just retries next launch.
    private func repairKeychainAccessOnce() {
        let flag = "Seihitsu.keychainRepaired.v1"
        guard !UserDefaults.standard.bool(forKey: flag) else { return }
        // Off the main thread: reading an item with a stale ACL shows a modal keychain prompt, and
        // the SecItem call blocks until it is answered. We must not freeze the UI while it is up.
        DispatchQueue.global(qos: .utility).async {
            let ok = Keychain.repairAccess(service: "Seihitsu.apikeys",
                                           accounts: ["openrouter", "openai", "anthropic", "gemini"])
            if ok { UserDefaults.standard.set(true, forKey: flag) }
            Log.log("keychain: repair pass completed=\(ok)")
        }
    }

    /// Even a menu-bar accessory needs a main menu with an Edit menu, otherwise the standard
    /// editing shortcuts (Cmd-C / Cmd-V / Cmd-X / Cmd-A / Cmd-Z) do nothing in the HUD.
    private func installMainMenu() {
        let mainMenu = NSMenu()

        let appItem = NSMenuItem()
        mainMenu.addItem(appItem)
        let appMenu = NSMenu()
        appItem.submenu = appMenu
        appMenu.addItem(withTitle: "Settings…", action: #selector(openSettingsFromMenu), keyEquivalent: ",").target = self
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit Seihitsu", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        let editItem = NSMenuItem()
        mainMenu.addItem(editItem)
        let editMenu = NSMenu(title: "Edit")
        editItem.submenu = editMenu
        editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")

        NSApp.mainMenu = mainMenu
    }

    @objc private func openSettingsFromMenu() { hud?.hide(); settings.show() }
}
