import SwiftUI
import AppKit

enum GlyphState: Equatable { case idle, thinking }

@MainActor
final class HUDViewModel: ObservableObject {
    enum State: Equatable { case idle, thinking, error }

    @Published var prompt = ""
    @Published var answer = ""
    @Published var state: State = .idle
    @Published var statusLine = "Ready"
    @Published var clickThrough = false
    @Published var focusPulse = 0
    /// Highlighted text/code captured from another app, held until the user gives an instruction.
    @Published var context: Attachment?
    /// Name of the active provider, shown in the header.
    @Published var modelName = ""
    /// True while the microphone is capturing for speech-to-text.
    @Published var isListening = false

    var onGlyph: ((GlyphState) -> Void)?
    /// Set by the controller; the Capture button forwards to it (capture reads the frontmost
    /// app's selection, which the controller owns).
    var onCaptureRequested: (() -> Void)?
    func requestCapture() { onCaptureRequested?() }

    private let resolveBackend: () -> ModelBackend
    private let listener = SpeechListener()
    private var task: Task<Void, Never>?

    init(resolveBackend: @escaping () -> ModelBackend) { self.resolveBackend = resolveBackend }

    // MARK: Listen (voice)

    func toggleListen() {
        if isListening {
            isListening = false          // reset immediately so the button flips back even if no transcript
            statusLine = "Transcribing…"
            listener.stop()
            return
        }
        listener.requestAuthorization { [weak self] granted in
            guard let self else { return }
            guard granted else {
                self.statusLine = "Needs Microphone + Speech Recognition"
                self.answer = "Listening needs Microphone and Speech Recognition permission.\nSystem Settings > Privacy & Security, then try again."
                return
            }
            self.beginListening()
        }
    }

    private func beginListening() {
        answer = ""
        prompt = ""
        isListening = true
        statusLine = "Listening… (⌥L to stop)"
        onGlyph?(.thinking)
        listener.onPartial = { [weak self] text in self?.prompt = text }
        listener.onFinal = { [weak self] text in self?.endListening(text) }
        listener.onError = { [weak self] message in
            self?.isListening = false
            self?.statusLine = message
            self?.onGlyph?(.idle)
        }
        listener.start()
    }

    private func endListening(_ text: String) {
        isListening = false
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            statusLine = "Didn't catch that"
            onGlyph?(.idle)
            return
        }
        prompt = trimmed
        submit()
    }

    /// Bumping this asks the view to move keyboard focus into the prompt field.
    func requestFocus() { focusPulse &+= 1 }

    func clearContext() { context = nil }

    /// A captured question is answered immediately, with no typing.
    func answerCapturedQuestion(_ text: String, source: String?) {
        context = nil
        prompt = ""
        run(Prompt(text: text))
        statusLine = "Answering highlighted question…"
    }

    /// Highlighted code is fixed immediately with a concise default instruction.
    func fixCapturedCode(_ code: String, source: String?) {
        let att = Attachment(kind: .code, content: code, source: source)
        context = att
        prompt = ""
        run(Prompt(text: HUDPrompts.fixCode, attachments: [att]))
        statusLine = "Fixing highlighted code from \(source ?? "screen")…"
    }

    /// Copy the current answer to the pasteboard.
    func copyAnswer() {
        guard !answer.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(answer, forType: .string)
        statusLine = "Answer copied"
    }

    /// Captured code/other is held as context; the user types what to do with it.
    func loadContext(_ text: String, kind: Attachment.Kind, source: String?) {
        context = Attachment(kind: kind, content: text, source: source)
        answer = ""
        state = .idle
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).count
        statusLine = "Captured \(lines) line\(lines == 1 ? "" : "s") from \(source ?? "screen"). Type an instruction."
        requestFocus()
    }

    /// User pressed Enter in the prompt field.
    func submit() {
        let q = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard state != .thinking else { return }
        guard !q.isEmpty || context != nil else { return }
        let req = Prompt(text: q, attachments: context.map { [$0] } ?? [])
        run(req)
    }

    private func run(_ req: Prompt) {
        answer = ""
        state = .thinking
        statusLine = "Thinking…"
        onGlyph?(.thinking)
        let backend = resolveBackend()
        let started = Date()
        Log.log("request: backend=\(backend.id) chars=\(req.wireText().count) attachments=\(req.attachments.count)")
        task?.cancel()
        task = Task { [weak self] in
            guard let self else { return }
            do {
                for try await chunk in backend.send(req) {
                    switch chunk {
                    case .text(let t): self.answer += t
                    case .done: break
                    }
                }
                Log.log("request: done backend=\(backend.id) answer=\(self.answer.count) chars in \(String(format: "%.1f", Date().timeIntervalSince(started)))s")
                self.finish(ok: true)
            } catch {
                Log.log("request: error backend=\(backend.id): \(error.localizedDescription)")
                self.answer += "\n[error] \(error.localizedDescription)"
                self.finish(ok: false)
            }
        }
    }

    private func finish(ok: Bool) {
        state = ok ? .idle : .error
        statusLine = ok ? "Done" : "Error"
        context = nil          // context is consumed once a request completes
        onGlyph?(.idle)
    }
}
