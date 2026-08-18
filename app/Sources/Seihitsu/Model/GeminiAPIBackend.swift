import Foundation

/// Google Gemini streamGenerateContent (SSE). Key from Keychain service "Seihitsu.apikeys".
final class GeminiAPIBackend: ModelBackend {
    let id: String
    let capabilities = Capabilities(streaming: true, agentic: false, sessions: false, vision: true, tools: false)

    private let model: String
    private let apiKeyAccount: String

    init(id: String = "gemini", model: String = "gemini-2.5-pro", apiKeyAccount: String = "gemini") {
        self.id = id
        self.model = model
        self.apiKeyAccount = apiKeyAccount
    }

    func send(_ req: Prompt) -> AsyncThrowingStream<Chunk, Error> {
        guard let key = Keychain.read(service: "Seihitsu.apikeys", account: apiKeyAccount), !key.isEmpty else {
            return singleMessageStream("[\(id)] No API key. Add one:\n  security add-generic-password -s Seihitsu.apikeys -a \(apiKeyAccount) -w YOUR_KEY")
        }
        let chosen = req.model ?? model
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(chosen):streamGenerateContent?alt=sse&key=\(key)"
        guard let url = URL(string: urlString) else {
            return singleMessageStream("[\(id)] Bad model name: \(chosen)")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [
            "contents": [["role": "user", "parts": [["text": req.wireText()]]]],
        ]
        body["systemInstruction"] = ["parts": [["text": req.system ?? "You are a concise heads-up assistant. Answer directly in plain text."]]]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        return SSEStream.run(request) { payload in
            guard let obj = SSEStream.json(payload),
                  let candidates = obj["candidates"] as? [[String: Any]],
                  let content = candidates.first?["content"] as? [String: Any],
                  let parts = content["parts"] as? [[String: Any]] else { return nil }
            return parts.compactMap { $0["text"] as? String }.joined()
        }
    }
}
