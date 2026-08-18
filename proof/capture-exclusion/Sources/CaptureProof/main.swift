// Capture-exclusion proof for Seihitsu Shirei.
//
// Puts two solid-colour panels on screen:
//   - MAGENTA panel with sharingType = .none      -> the "HUD". Should VANISH from captures.
//   - GREEN   panel with sharingType = .readOnly   -> a control. Should APPEAR in captures.
//
// Then captures the screen three ways and counts how many magenta / green pixels each
// capture contains:
//   1. screencapture(8)  -> the local system screenshot path (Cmd-Shift-3/4/5)
//   2. ScreenCaptureKit  -> the path Zoom / Meet / Teams / recorders use for screen shares
//   3. CGDisplayCreateImage -> legacy programmatic path (deprecated, best-effort)
//
// The control window is the whole point: if GREEN shows up and MAGENTA does not, we have
// isolated the effect to sharingType, not to "the capture silently failed".

import AppKit
import ScreenCaptureKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// MARK: - Markers

let magenta = (r: 255, g: 0, b: 255)   // the .none HUD
let green   = (r: 0, g: 255, b: 0)     // the control
let tolerance = 55                     // colour-management wiggle room
let presentThreshold = 500             // matching pixels above this => "present"

let panelSize = NSSize(width: 320, height: 200)
let outDir = (FileManager.default.currentDirectoryPath as NSString)
    .appendingPathComponent("captures")

// MARK: - Panels

func makePanel(color: NSColor, sharing: NSWindow.SharingType, at origin: NSPoint, label: String) -> NSPanel {
    let frame = NSRect(origin: origin, size: panelSize)
    let panel = NSPanel(contentRect: frame,
                        styleMask: [.borderless, .nonactivatingPanel],
                        backing: .buffered, defer: false)
    panel.isOpaque = true
    panel.backgroundColor = color
    panel.hasShadow = false
    panel.level = .screenSaver
    panel.sharingType = sharing
    panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]

    let text = NSTextField(labelWithString: label)
    text.textColor = .black
    text.font = .boldSystemFont(ofSize: 15)
    text.frame = NSRect(x: 12, y: panelSize.height / 2 - 12, width: panelSize.width - 24, height: 40)
    text.maximumNumberOfLines = 2
    panel.contentView?.addSubview(text)

    panel.orderFrontRegardless()
    return panel
}

// MARK: - Pixel counting

func countColors(in image: CGImage) -> (magenta: Int, green: Int) {
    let w = image.width, h = image.height
    let bytesPerRow = w * 4
    var buf = [UInt8](repeating: 0, count: h * bytesPerRow)
    let cs = CGColorSpaceCreateDeviceRGB()
    guard let ctx = CGContext(data: &buf, width: w, height: h,
                              bitsPerComponent: 8, bytesPerRow: bytesPerRow,
                              space: cs,
                              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
        return (-1, -1)
    }
    ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))

    func matches(_ r: Int, _ g: Int, _ b: Int, _ t: (r: Int, g: Int, b: Int)) -> Bool {
        abs(r - t.r) <= tolerance && abs(g - t.g) <= tolerance && abs(b - t.b) <= tolerance
    }

    var mCount = 0, gCount = 0
    var i = 0
    let total = w * h
    while i < total {
        let o = i * 4
        let r = Int(buf[o]), g = Int(buf[o + 1]), b = Int(buf[o + 2])
        if matches(r, g, b, magenta) { mCount += 1 }
        else if matches(r, g, b, green) { gCount += 1 }
        i += 1
    }
    return (mCount, gCount)
}

func savePNG(_ image: CGImage, named name: String) {
    try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)
    let path = (outDir as NSString).appendingPathComponent(name)
    guard let dest = CGImageDestinationCreateWithURL(
        URL(fileURLWithPath: path) as CFURL, UTType.png.identifier as CFString, 1, nil) else { return }
    CGImageDestinationAddImage(dest, image, nil)
    CGImageDestinationFinalize(dest)
}

// MARK: - Capture methods

func captureViaScreencapture() -> CGImage? {
    let tmp = (NSTemporaryDirectory() as NSString).appendingPathComponent("seihitsu-cli.png")
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
    p.arguments = ["-x", "-m", "-t", "png", tmp] // -x silent, -m main display only
    do { try p.run() } catch { return nil }
    p.waitUntilExit()
    guard let img = NSImage(contentsOfFile: tmp) else { return nil }
    return img.cgImage(forProposedRect: nil, context: nil, hints: nil)
}

func captureViaScreenCaptureKit() async -> CGImage? {
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
        FileHandle.standardError.write("  [SCK] \(error.localizedDescription)\n".data(using: .utf8)!)
        return nil
    }
}

func captureViaLegacyCG() -> CGImage? {
    // Deprecated on modern macOS; may return nil. Included only to show the legacy path.
    CGDisplayCreateImage(CGMainDisplayID())
}

// MARK: - Report

func report(method: String, image: CGImage?, saveAs: String) {
    guard let image else {
        print("  \(method.padding(toLength: 22, withPad: " ", startingAt: 0)) unavailable (nil / permission?)")
        return
    }
    savePNG(image, named: saveAs)
    let (m, g) = countColors(in: image)
    let hudHidden = m < presentThreshold
    let controlSeen = g >= presentThreshold

    let verdict: String
    if !controlSeen {
        verdict = "INCONCLUSIVE  (control not captured -> grant Screen Recording, re-run)"
    } else if hudHidden {
        verdict = "PASS  HUD excluded, control visible"
    } else {
        verdict = "FAIL  HUD was captured"
    }
    print("  \(method.padding(toLength: 22, withPad: " ", startingAt: 0)) magenta(HUD)=\(m)  green(control)=\(g)   \(verdict)")
}

// MARK: - Main

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

guard let screen = NSScreen.main else {
    print("No main screen."); exit(1)
}
let sf = screen.frame
let top = sf.maxY - panelSize.height - 60
let noneOrigin = NSPoint(x: sf.minX + 80, y: top)
let ctrlOrigin = NSPoint(x: sf.minX + 80 + panelSize.width + 40, y: top)

// Retain the panels for the lifetime of the process.
let hudPanel = makePanel(color: .magenta, sharing: .none,
                         at: noneOrigin, label: "HUD  sharingType = .none\n(should VANISH)")
let controlPanel = makePanel(color: .green, sharing: .readOnly,
                             at: ctrlOrigin, label: "CONTROL  .readOnly\n(should APPEAR)")
_ = (hudPanel, controlPanel)

// Optional hold duration (seconds) so a human can take their own screenshot.
// Usage: CaptureProof [holdSeconds]   (default 30)
let holdSeconds: Int = CommandLine.arguments.dropFirst().first.flatMap { Int($0) } ?? 30

Task { @MainActor in
    // Let the window server composite the panels before we capture.
    try? await Task.sleep(nanoseconds: 900_000_000)

    print("\nSeihitsu Shirei - capture-exclusion proof")
    print("Markers: magenta = the .none HUD (want ABSENT), green = control (want PRESENT)")
    print("Saved captures -> \(outDir)\n")

    report(method: "1. screencapture CLI",  image: captureViaScreencapture(),          saveAs: "1-screencapture-cli.png")
    report(method: "2. ScreenCaptureKit",    image: await captureViaScreenCaptureKit(), saveAs: "2-screencapturekit.png")
    report(method: "3. CGDisplayCreateImage", image: captureViaLegacyCG(),              saveAs: "3-legacy-cg.png")

    print("\nRow reads PASS when the magenta HUD is missing but the green control is present.")

    // Human-screenshot window: keep both panels on screen, count down, then quit.
    print("\n>>> Panels are UP. Take your own screenshot now (Cmd-Shift-4 or Cmd-Shift-3).")
    print(">>> The GREEN panel should be in your shot; the MAGENTA one should NOT.")
    for remaining in stride(from: holdSeconds, through: 1, by: -1) {
        if remaining % 5 == 0 || remaining <= 3 {
            print(">>> closing in \(remaining)s ...")
        }
        try? await Task.sleep(nanoseconds: 1_000_000_000)
    }
    print(">>> done.\n")
    NSApp.terminate(nil)
}

app.run()
