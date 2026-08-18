import Foundation

/// Parses Claude Code's `--output-format stream-json` output: one JSON object per line.
///
/// Verified event shapes (claude 2.1.170):
///   {"type":"system","subtype":"init"|"hook_started"|...}          -> ignored
///   {"type":"assistant","message":{"content":[{"type":"text","text":...}]}}
///   {"type":"content_block_delta","delta":{"type":"text_delta","text":...}}   (partial mode)
///   {"type":"stream_event","event":{ ...content_block_delta... }}             (partial wrapper)
///   {"type":"result","subtype":"success","is_error":false,"result":"..."}
///
/// With `--include-partial-messages`, text streams as deltas. To avoid double-emitting, once
/// any delta text is seen we suppress the final full `assistant` message text.
final class StreamJSONParser {
    enum Event { case text(String); case result; case resultError(String) }

    private var buffer = Data()
    private var streamedDeltas = false
    private(set) var emittedText = false

    func consume(_ data: Data) -> [Event] {
        buffer.append(data)
        var events: [Event] = []
        while let nl = buffer.firstIndex(of: 0x0A) {
            let line = buffer.subdata(in: buffer.startIndex..<nl)
            buffer.removeSubrange(buffer.startIndex...nl)
            events.append(contentsOf: parse(line))
        }
        return events
    }

    func flush() -> [Event] {
        guard !buffer.isEmpty else { return [] }
        let line = buffer
        buffer.removeAll()
        return parse(line)
    }

    private func parse(_ data: Data) -> [Event] {
        guard !data.isEmpty,
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = obj["type"] as? String else { return [] }

        switch type {
        case "assistant":
            guard !streamedDeltas,
                  let message = obj["message"] as? [String: Any],
                  let content = message["content"] as? [[String: Any]] else { return [] }
            var out: [Event] = []
            for block in content where (block["type"] as? String) == "text" {
                if let t = block["text"] as? String, !t.isEmpty {
                    out.append(.text(t)); emittedText = true
                }
            }
            return out

        case "content_block_delta":
            return delta(from: obj)

        case "stream_event":
            if let event = obj["event"] as? [String: Any] { return delta(from: event) }
            return []

        case "result":
            if let isErr = obj["is_error"] as? Bool, isErr {
                return [.resultError((obj["result"] as? String) ?? "unknown error")]
            }
            return [.result]

        default:
            return []
        }
    }

    private func delta(from obj: [String: Any]) -> [Event] {
        guard (obj["type"] as? String) == "content_block_delta",
              let delta = obj["delta"] as? [String: Any],
              (delta["type"] as? String) == "text_delta",
              let t = delta["text"] as? String, !t.isEmpty else { return [] }
        streamedDeltas = true
        emittedText = true
        return [.text(t)]
    }
}
