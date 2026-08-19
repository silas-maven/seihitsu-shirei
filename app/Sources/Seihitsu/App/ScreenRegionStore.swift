import Foundation
import CoreGraphics

/// Persists the screen area Seihitsu reads, in main-screen points (bottom-left origin, the
/// same space NSScreen/NSWindow use). `nil` means read the whole main display.
///
/// The user sets this once by dragging a rectangle (see RegionPicker); ⌥V then reads exactly
/// that area every time, so the model only ever sees what the user chose to expose.
enum ScreenRegionStore {
    private static let key = "Seihitsu.screenRegion"

    static var region: CGRect? {
        get {
            guard let a = UserDefaults.standard.array(forKey: key) as? [Double],
                  a.count == 4, a[2] > 1, a[3] > 1 else { return nil }
            return CGRect(x: a[0], y: a[1], width: a[2], height: a[3])
        }
        set {
            if let r = newValue, r.width > 1, r.height > 1 {
                UserDefaults.standard.set([Double(r.origin.x), Double(r.origin.y),
                                           Double(r.width), Double(r.height)], forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }

    /// Human-readable summary for the HUD/status line.
    static var describe: String {
        if let r = region { return "\(Int(r.width))×\(Int(r.height)) region" }
        return "full screen"
    }
}
