import Foundation

/// Shared Server-Sent-Events driver for the HTTP API backends. Streams `data:` payloads,
/// hands each to a provider-specific `decode` that pulls out the incremental text.
enum SSEStream {
    static func run(_ request: URLRequest, decode: @escaping (String) -> String?) -> AsyncThrowingStream<Chunk, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
                        var body = ""
                        for try await line in bytes.lines {
                            body += line + "\n"
                            if body.count > 4000 { break }
                        }
                        continuation.yield(.text("[HTTP \(http.statusCode)] \(body.trimmingCharacters(in: .whitespacesAndNewlines))"))
                        continuation.yield(.done)
                        continuation.finish()
                        return
                    }
                    for try await line in bytes.lines {
                        guard line.hasPrefix("data:") else { continue }
                        let payload = String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                        if payload.isEmpty { continue }
                        if payload == "[DONE]" { break }
                        if let text = decode(payload) { continuation.yield(.text(text)) }
                    }
                    continuation.yield(.done)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Convenience: parse a `data:` payload as a JSON object.
    static func json(_ payload: String) -> [String: Any]? {
        guard let data = payload.data(using: .utf8) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }
}

/// An error surfaced as a single chunk (e.g. a missing API key), so the HUD shows it inline.
struct BackendMessageError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

/// Returns a stream that just emits one text line and finishes. Used for pre-flight errors.
func singleMessageStream(_ text: String) -> AsyncThrowingStream<Chunk, Error> {
    AsyncThrowingStream { continuation in
        continuation.yield(.text(text))
        continuation.yield(.done)
        continuation.finish()
    }
}
