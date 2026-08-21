import Foundation

/// A piece of context attached to a prompt, e.g. text/code the user highlighted on screen,
/// or (later) text pulled from a screenshot via OCR. Flows through one path for every source.
struct Attachment: Equatable {
    enum Kind: String, Equatable { case selection, code, screenText }
    var kind: Kind
    var content: String
    var source: String?   // the app the selection came from, if known
}

/// A single request to a model.
struct Prompt {
    var text: String
    var attachments: [Attachment] = []
    var system: String? = nil
    var model: String? = nil
    /// Hard cap on output tokens. nil = the backend's own default. Lowered in Brief/Blitz so a
    /// timed answer completes fast.
    var maxTokens: Int? = nil
    /// A screenshot (JPEG) to send alongside the text, for the vision path (⌥⇧V). Only backends
    /// whose `capabilities.vision` is true accept it.
    var imageData: Data? = nil

    /// The text actually sent to the model: attachment blocks first, then the instruction.
    /// A bare question (no attachments) passes through unchanged.
    func wireText() -> String {
        guard !attachments.isEmpty else { return text }
        let multi = attachments.count > 1   // numbered when it's a collect buffer of several snippets
        var parts: [String] = []
        for (i, a) in attachments.enumerated() {
            let src = a.source.map { " from \($0)" } ?? ""
            let n = multi ? " \(i + 1)" : ""
            let header: String
            switch a.kind {
            case .code:       header = "Code snippet\(n)\(src):"
            case .screenText: header = "Text read from the screen\(n)\(src):"
            case .selection:  header = "Highlighted text\(n)\(src):"
            }
            parts.append("\(header)\n\"\"\"\n\(a.content)\n\"\"\"")
        }
        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            parts.append(text)
        }
        return parts.joined(separator: "\n\n")
    }
}

/// A unit of streamed output. Every backend normalizes to this.
enum Chunk {
    case text(String)
    case done
}

/// What a backend can do. Differences between backends live here, not in new code paths.
struct Capabilities {
    var streaming: Bool = true
    var agentic: Bool = false
    var sessions: Bool = false
    var vision: Bool = false
    var tools: Bool = false
}

/// One uniform interface across subscription CLIs and HTTP API providers.
protocol ModelBackend {
    var id: String { get }
    var capabilities: Capabilities { get }
    func send(_ req: Prompt) -> AsyncThrowingStream<Chunk, Error>
}
