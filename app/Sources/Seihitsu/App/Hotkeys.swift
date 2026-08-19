import AppKit
import Carbon.HIToolbox

/// Global hotkeys via Carbon RegisterEventHotKey. This path does NOT require the
/// Accessibility or Input Monitoring permission (unlike a CGEventTap).
///   Option-Space : summon / hide the HUD
///   Option-C     : capture the current selection and act on it
///   Option-V     : read the saved screen region (OCR) and answer it
///   Option-L     : start / stop voice listening
///   Option-Shift-C : toggle click-through
///   Option-Shift-S : cycle answer speed (Full / Brief / Blitz)
final class Hotkeys {
    var onSummon: (() -> Void)?
    var onCapture: (() -> Void)?
    var onReadScreen: (() -> Void)?
    var onListen: (() -> Void)?
    var onToggleClickThrough: (() -> Void)?
    var onCycleSpeed: (() -> Void)?

    private var eventHandler: EventHandlerRef?
    private var refs: [EventHotKeyRef?] = []
    private var actions: [UInt32: () -> Void] = [:]

    func register() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                 eventKind: UInt32(kEventHotKeyPressed))
        // Non-capturing closure -> convertible to a C function pointer. Context via userData.
        let callback: EventHandlerUPP = { _, event, userData in
            guard let userData, let event else { return noErr }
            let me = Unmanaged<Hotkeys>.fromOpaque(userData).takeUnretainedValue()
            var hkID = EventHotKeyID()
            let err = GetEventParameter(event, EventParamName(kEventParamDirectObject),
                                        EventParamType(typeEventHotKeyID), nil,
                                        MemoryLayout<EventHotKeyID>.size, nil, &hkID)
            if err == noErr { me.actions[hkID.id]?() }
            return noErr
        }
        InstallEventHandler(GetApplicationEventTarget(), callback, 1, &spec,
                            Unmanaged.passUnretained(self).toOpaque(), &eventHandler)

        add(id: 1, keyCode: UInt32(kVK_Space), mods: UInt32(optionKey)) { [weak self] in self?.onSummon?() }
        add(id: 2, keyCode: UInt32(kVK_ANSI_C), mods: UInt32(optionKey)) { [weak self] in self?.onCapture?() }
        add(id: 3, keyCode: UInt32(kVK_ANSI_C), mods: UInt32(optionKey | shiftKey)) { [weak self] in self?.onToggleClickThrough?() }
        add(id: 4, keyCode: UInt32(kVK_ANSI_L), mods: UInt32(optionKey)) { [weak self] in self?.onListen?() }
        add(id: 5, keyCode: UInt32(kVK_ANSI_V), mods: UInt32(optionKey)) { [weak self] in self?.onReadScreen?() }
        add(id: 6, keyCode: UInt32(kVK_ANSI_S), mods: UInt32(optionKey | shiftKey)) { [weak self] in self?.onCycleSpeed?() }
    }

    private func add(id: UInt32, keyCode: UInt32, mods: UInt32, action: @escaping () -> Void) {
        let hkID = EventHotKeyID(signature: fourCharCode("SSHI"), id: id)
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(keyCode, mods, hkID, GetApplicationEventTarget(), 0, &ref)
        if status == noErr {
            refs.append(ref)
            actions[id] = action
            Log.log("hotkey id=\(id) registered")
        } else {
            Log.log("hotkey id=\(id) FAILED to register (status=\(status); another app may own this combo)")
        }
    }
}

private func fourCharCode(_ s: String) -> FourCharCode {
    var result: FourCharCode = 0
    for byte in s.utf8.prefix(4) { result = (result << 8) + FourCharCode(byte) }
    return result
}
