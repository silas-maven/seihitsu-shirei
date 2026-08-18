import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBar: MenuBarController?
    private var hud: HUDController?
    private var router: ModelRouter?
    private let settings = SettingsController()
    private let hotkeys = Hotkeys()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let router = ModelRouter()
        self.router = router

        let hud = HUDController(router: router)
        self.hud = hud

        let menuBar = MenuBarController()
        menuBar.onToggleHUD = { [weak hud] in hud?.toggle() }
        menuBar.onRunSelfTest = { [weak hud] in hud?.runCaptureSelfTest() }
        menuBar.onQuit = { NSApp.terminate(nil) }
        menuBar.providerList = { [weak router] in
            guard let router else { return [] }
            return router.providers.map { (id: $0.id, name: $0.name, active: $0.id == router.activeID) }
        }
        menuBar.onSelectProvider = { [weak router, weak hud] id in
            router?.setActive(id)
            hud?.refreshModel()
        }
        menuBar.onOpenSettings = { [weak self] in self?.settings.show() }
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
        hotkeys.onToggleClickThrough = { [weak hud] in hud?.toggleClickThrough() }
        hotkeys.register()

        // Debug aid: SEIHITSU_AUTOSHOW=1 opens the HUD on launch (used to exercise the
        // render path headlessly; the HUD itself is excluded from screen capture).
        if ProcessInfo.processInfo.environment["SEIHITSU_AUTOSHOW"] == "1" {
            hud.show()
        }
    }
}
