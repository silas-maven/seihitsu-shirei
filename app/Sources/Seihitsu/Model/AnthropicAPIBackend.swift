import Foundation

/// Anthropic Messages API (streaming). Key from Keychain service "Seihitsu.apikeys".
final class AnthropicAPIBackend: ModelBackend {
    let id: String
    let capabilities = Capabilities(streaming: true, agentic: false, sessions: false, vision: true, tools: false)

    private let model: String
    private let apiKeyAccount: String
    private let maxTokens: Int

    init(id: String = "anthropic", model: String = "claude-sonnet-4-5", apiKeyAccount: String = "anthropic", maxTokens: Int = 2048) {
        self.id = id
        self.model = model
        self.apiKeyAccount = apiKeyAccount
        self.maxTokens = maxTokens
    }

    func send(_ req: Prompt) -> AsyncThrowingStream<Chunk, Error> {
        guard let key = Keychain.read(service: "Seihitsu.apikeys", account: apiKeyAccount), !key.isEmpty else {
            return singleMessageStream("[\(id)] No API key. Add one:\n  security add-generic-password -s Seihitsu.apikeys -a \(apiKeyAccount) -w YOUR_KEY")
        }
        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.setValue(key, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        var body: [String: Any] = [
            "model": req.model ?? model,
            "max_tokens": maxTokens,
            "stream": true,
            "messages": [["role": "user", "content": req.wireText()]],
        ]
        body["system"] = req.system ?? "You are a concise heads-up assistant. Answer directly in plain text."
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        return SSEStream.run(request) { payload in
            guard let obj = SSEStream.json(payload),
                  (obj["type"] as? String) == "content_block_delta",
                  let delta = obj["delta"] as? [String: Any],
                  (delta["type"] as? String) == "text_delta" else { return nil }
            return delta["text"] as? String
        }
    }
}
