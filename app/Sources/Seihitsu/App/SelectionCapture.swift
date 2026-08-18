import AppKit
import ApplicationServices

/// The current on-screen selection, plus a cheap classification so the HUD can decide
/// whether to answer it directly (a question) or hold it as context (code/other).
struct CapturedSelection {
    var text: String
    var source: String?          // frontmost app name
    var looksLikeCode: Bool
    var looksLikeQuestion: Bool
}

/// Reads the highlighted text from whatever app is frontmost, without disturbing the user.
///
/// Tier 1: Accessibility `kAXSelectedTextAttribute` on the focused element (no clipboard
///         touch, works in native text views and many web views).
/// Tier 2: synthetic Cmd-C, reading the pasteboard and restoring its prior contents.
///
/// Both require the app to be trusted for Accessibility. Capture must run BEFORE the HUD
/// takes focus, so the frontmost app is still the one holding the selection.
enum SelectionCapture {
    @discardableResult
    static func isTrusted(prompt: Bool) -> Bool {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        return AXIsProcessTrustedWithOptions([key: prompt] as CFDictionary)
    }

    static func capture() -> CapturedSelection? {
        let source = NSWorkspace.shared.frontmostApplication?.localizedName
        if let t = axSelectedText(), !t.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return classify(t, source: source)
        }
        if let t = syntheticCopy(), !t.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return classify(t, source: source)
        }
        return nil
    }

    // MARK: Tier 1 - Accessibility

    private static func axSelectedText() -> String? {
        let system = AXUIElementCreateSystemWide()
        var focused: CFTypeRef?
        guard AXUIElementCopyAttributeValue(system, kAXFocusedUIElementAttribute as CFString, &focused) == .success,
              let raw = focused, CFGetTypeID(raw) == AXUIElementGetTypeID() else { return nil }
        let element = raw as! AXUIElement
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXSelectedTextAttribute as CFString, &value) == .success,
              let s = value as? String else { return nil }
        return s
    }

    // MARK: Tier 2 - synthetic copy with pasteboard save/restore

    private static func syntheticCopy() -> String? {
        let pb = NSPasteboard.general
        let saved = snapshot(pb)
        let before = pb.changeCount

        guard let src = CGEventSource(stateID: .combinedSessionState) else { return nil }
        let vKeyC: CGKeyCode = 0x08 // 'c'
        let down = CGEvent(keyboardEventSource: src, virtualKey: vKeyC, keyDown: true)
        down?.flags = .maskCommand
        let up = CGEvent(keyboardEventSource: src, virtualKey: vKeyC, keyDown: false)
        up?.flags = .maskCommand
        down?.post(tap: .cghidEventTap)
        up?.post(tap: .cghidEventTap)

        var waited = 0
        while pb.changeCount == before && waited < 40 { usleep(10_000); waited += 1 } // up to ~400ms
        let copied = pb.string(forType: .string)

        restore(saved, to: pb)
        return copied
    }

    private static func snapshot(_ pb: NSPasteboard) -> [[NSPasteboard.PasteboardType: Data]] {
        (pb.pasteboardItems ?? []).map { item in
            var dict: [NSPasteboard.PasteboardType: Data] = [:]
            for type in item.types { if let d = item.data(forType: type) { dict[type] = d } }
            return dict
        }
    }

    private static func restore(_ items: [[NSPasteboard.PasteboardType: Data]], to pb: NSPasteboard) {
        pb.clearContents()
        guard !items.isEmpty else { return }
        var restored: [NSPasteboardItem] = []
        for dict in items {
            let item = NSPasteboardItem()
            for (type, data) in dict { item.setData(data, forType: type) }
            restored.append(item)
        }
        pb.writeObjects(restored)
    }

    // MARK: Classification

    private static func classify(_ text: String, source: String?) -> CapturedSelection {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let isCode = looksLikeCode(trimmed)
        let isQuestion = !isCode && (trimmed.hasSuffix("?") || startsWithQuestionWord(trimmed))
        return CapturedSelection(text: text, source: source, looksLikeCode: isCode, looksLikeQuestion: isQuestion)
    }

    private static func startsWithQuestionWord(_ s: String) -> Bool {
        let lower = s.lowercased()
        let starts = ["what", "why", "how", "when", "where", "who ", "which", "is ", "are ",
                      "can ", "could ", "should ", "do ", "does ", "did ", "will ", "would ",
                      "explain", "summarize", "summarise", "define", "translate"]
        return starts.contains { lower.hasPrefix($0) }
    }

    private static func looksLikeCode(_ s: String) -> Bool {
        let tokens = ["{", "}", ";", "=>", "()", "def ", "func ", "class ", "import ",
                      "const ", "let ", "var ", "return ", "public ", "private ", "#include",
                      "</", "/>", "==", "!=", "->"]
        let hits = tokens.reduce(0) { $0 + (s.contains($1) ? 1 : 0) }
        let lines = s.split(separator: "\n", omittingEmptySubsequences: false)
        let indented = lines.filter { $0.hasPrefix("  ") || $0.hasPrefix("\t") }.count
        return hits >= 3 || (lines.count >= 3 && indented >= 2)
    }
}
