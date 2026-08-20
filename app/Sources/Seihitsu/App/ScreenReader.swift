import AppKit
import ScreenCaptureKit
import CoreGraphics
import Vision

/// Reads text off the screen: capture a region -> on-device Vision OCR -> plain text.
///
/// This is the answer for apps that block text selection or copy (terminals, some Electron
/// and remote-desktop apps): instead of grabbing the selection, we photograph the pixels and
/// read them. It uses **Screen Recording** permission, which is a different grant from the
/// Accessibility one the highlight path needs. The HUD is `sharingType = .none`, so it is
/// excluded from this capture and never reads its own previous answer back.
///
/// OCR is on-device (Apple Vision). Nothing is written to disk and no image leaves the machine;
/// only the recognised text is sent to the model.
@MainActor
enum ScreenReader {
    /// True if Screen Recording is granted. Prompts once (system dialog) if not.
    static func ensurePermission() -> Bool {
        if CGPreflightScreenCaptureAccess() { return true }
        Log.log("screen-read: Screen Recording not granted; requesting")
        return CGRequestScreenCaptureAccess()
    }

    /// Capture the given region (or the whole main display if `nil`), OCR it, return the text.
    /// Returns `nil` if capture failed or no readable text was found.
    static func read(region: CGRect?) async -> String? {
        guard let image = await capture(region: region) else { return nil }
        let text = await recognise(image)
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : text
    }

    /// Capture the given region as a JPEG, for sending to a vision model (⌥⇧V). Downscaled so the
    /// payload stays small. Returns `nil` if capture failed.
    static func readImage(region: CGRect?) async -> Data? {
        guard let image = await capture(region: region) else { return nil }
        return jpegData(image, maxDim: 1400, quality: 0.85)
    }

    // MARK: Capture

    private static func capture(region: CGRect?) async -> CGImage? {
        do {
            let content = try await SCShareableContent.current
            guard let display = content.displays.first else { return nil }
            let scale = NSScreen.main?.backingScaleFactor ?? 2

            let filter = SCContentFilter(display: display, excludingWindows: [])
            let cfg = SCStreamConfiguration()
            cfg.width = Int(CGFloat(display.width) * scale)   // native pixels -> crisper OCR
            cfg.height = Int(CGFloat(display.height) * scale)
            cfg.showsCursor = false
            let full = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: cfg)

            guard let region else { return full }

            // Map region (screen points, bottom-left origin) to a pixel rect (top-left origin)
            // inside `full`. Single main display for now.
            let screen = NSScreen.main?.frame ?? .zero
            let xPts = region.origin.x - screen.origin.x
            let yTopPts = screen.height - (region.origin.y - screen.origin.y) - region.height
            var px = CGRect(x: xPts * scale, y: yTopPts * scale,
                            width: region.width * scale, height: region.height * scale).integral
            px = px.intersection(CGRect(x: 0, y: 0, width: full.width, height: full.height))
            guard !px.isNull, px.width >= 1, px.height >= 1, let cropped = full.cropping(to: px) else {
                return full
            }
            return cropped
        } catch {
            Log.log("screen-read: capture failed: \(error.localizedDescription)")
            return nil
        }
    }

    /// CGImage -> JPEG Data, downscaling so the longest side is at most `maxDim`.
    private static func jpegData(_ cg: CGImage, maxDim: CGFloat, quality: CGFloat) -> Data? {
        let w = CGFloat(cg.width), h = CGFloat(cg.height)
        let scale = min(1, maxDim / max(w, h))
        let rep: NSBitmapImageRep
        if scale < 1 {
            let nw = max(1, Int(w * scale)), nh = max(1, Int(h * scale))
            guard let ctx = CGContext(data: nil, width: nw, height: nh, bitsPerComponent: 8,
                                      bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return nil }
            ctx.interpolationQuality = .high
            ctx.draw(cg, in: CGRect(x: 0, y: 0, width: nw, height: nh))
            guard let scaled = ctx.makeImage() else { return nil }
            rep = NSBitmapImageRep(cgImage: scaled)
        } else {
            rep = NSBitmapImageRep(cgImage: cg)
        }
        return rep.representation(using: .jpeg, properties: [.compressionFactor: quality])
    }

    // MARK: OCR (on-device Vision, off the main thread)

    private static func recognise(_ image: CGImage) async -> String {
        await withCheckedContinuation { (cont: CheckedContinuation<String, Never>) in
            DispatchQueue.global(qos: .userInitiated).async {
                let request = VNRecognizeTextRequest()
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true
                let handler = VNImageRequestHandler(cgImage: image, options: [:])
                do {
                    try handler.perform([request])
                    let obs: [VNRecognizedTextObservation] = request.results ?? []
                    // Reconstruct reading order. Vision uses a normalised bottom-left origin,
                    // so a higher midY is higher on screen. Group into lines top-to-bottom,
                    // then left-to-right within a line.
                    let sorted = obs.sorted { a, b in
                        if abs(a.boundingBox.midY - b.boundingBox.midY) > 0.012 {
                            return a.boundingBox.midY > b.boundingBox.midY
                        }
                        return a.boundingBox.minX < b.boundingBox.minX
                    }
                    let lines = sorted.compactMap { $0.topCandidates(1).first?.string }
                    cont.resume(returning: lines.joined(separator: "\n"))
                } catch {
                    cont.resume(returning: "")
                }
            }
        }
    }
}
