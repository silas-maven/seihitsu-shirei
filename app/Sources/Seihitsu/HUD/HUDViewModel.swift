import SwiftUI

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

    var onGlyph: ((GlyphState) -> Void)?

    private let resolveBackend: () -> ModelBackend
    private var task: Task<Void, Never>?

    init(resolveBackend: @escaping () -> ModelBackend) { self.resolveBackend = resolveBackend }

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
                self.finish(ok: true)
            } catch {
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
