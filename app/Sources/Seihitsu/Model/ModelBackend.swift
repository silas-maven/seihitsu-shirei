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

    /// The text actually sent to the model: attachment blocks first, then the instruction.
    /// A bare question (no attachments) passes through unchanged.
    func wireText() -> String {
        guard !attachments.isEmpty else { return text }
        var parts: [String] = []
        for a in attachments {
            let src = a.source.map { " from \($0)" } ?? ""
            let header = (a.kind == .code) ? "Highlighted code\(src):" : "Highlighted text\(src):"
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
