import AppKit
import ScreenCaptureKit
import CoreGraphics

/// On-demand proof that `.none` exclusion still holds on the current macOS. Spins a transient
/// magenta `.none` probe and a green `.readOnly` control, captures via ScreenCaptureKit (the
/// screen-share path), and asserts the control is present but the probe is absent. Ported from
/// `proof/capture-exclusion`.
@MainActor
enum CaptureSelfTest {
    static func run() async -> String {
        let magenta = makeProbe(color: .magenta, sharing: .none, dx: 0)
        let green = makeProbe(color: .green, sharing: .readOnly, dx: 360)
        magenta.orderFrontRegardless()
        green.orderFrontRegardless()
        defer { magenta.orderOut(nil); green.orderOut(nil) }

        try? await Task.sleep(nanoseconds: 500_000_000)

        guard let image = await capture() else {
            return "Capture self-test: could not capture the screen.\nGrant Screen Recording to Seihitsu in System Settings > Privacy & Security, then retry."
        }
        let hud = countColor(image, r: 255, g: 0, b: 255, tol: 60)     // magenta = the .none probe
        let control = countColor(image, r: 0, g: 255, b: 0, tol: 60)   // green = the control

        if control < 500 {
            return "Capture self-test: INCONCLUSIVE\nControl window was not captured (permission?). magenta=\(hud) green=\(control)"
        }
        if hud < 500 {
            return "Capture self-test: PASS ✓\nThe .none overlay is excluded from screen capture on this macOS.\ncontrol green=\(control), hidden magenta=\(hud)"
        }
        return "Capture self-test: FAIL ✗\nThe overlay WAS captured (magenta=\(hud)). Do not rely on invisibility here."
    }

    private static func makeProbe(color: NSColor, sharing: NSWindow.SharingType, dx: CGFloat) -> NSPanel {
        let size = NSSize(width: 320, height: 200)
        let screen = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let origin = NSPoint(x: screen.minX + 80 + dx, y: screen.maxY - size.height - 80)
        let p = NSPanel(contentRect: NSRect(origin: origin, size: size),
                        styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        p.isOpaque = true
        p.backgroundColor = color
        p.hasShadow = false
        p.level = .screenSaver
        p.sharingType = sharing
        p.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        return p
    }

    private static func capture() async -> CGImage? {
        do {
            let content = try await SCShareableContent.current
            guard let display = content.displays.first else { return nil }
            let filter = SCContentFilter(display: display, excludingWindows: [])
            let cfg = SCStreamConfiguration()
            cfg.width = display.width
            cfg.height = display.height
            cfg.showsCursor = false
            return try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: cfg)
        } catch {
            return nil
        }
    }

    private static func countColor(_ image: CGImage, r tr: Int, g tg: Int, b tb: Int, tol: Int) -> Int {
        let w = image.width, h = image.height
        let bpr = w * 4
        var buf = [UInt8](repeating: 0, count: h * bpr)
        let cs = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(data: &buf, width: w, height: h, bitsPerComponent: 8,
                                  bytesPerRow: bpr, space: cs,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return -1 }
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        var count = 0, i = 0
        let total = w * h
        while i < total {
            let o = i * 4
            if abs(Int(buf[o]) - tr) <= tol, abs(Int(buf[o + 1]) - tg) <= tol, abs(Int(buf[o + 2]) - tb) <= tol {
                count += 1
            }
            i += 1
        }
        return count
    }
}
