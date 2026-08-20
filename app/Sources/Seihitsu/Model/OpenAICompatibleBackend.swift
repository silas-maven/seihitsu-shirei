import Foundation

/// OpenAI Chat Completions (streaming). Covers OpenAI itself and any OpenAI-compatible
/// endpoint (LM Studio, Ollama, OpenRouter, Groq, ...) via a configurable base URL.
/// A local endpoint may need no key, so a missing key is allowed when the host is loopback.
final class OpenAICompatibleBackend: ModelBackend {
    let id: String
    let capabilities: Capabilities

    private let model: String
    private let baseURL: String
    private let apiKeyAccount: String?

    init(id: String, model: String, baseURL: String, apiKeyAccount: String?, vision: Bool = true) {
        self.id = id
        self.model = model
        self.baseURL = baseURL.hasSuffix("/") ? String(baseURL.dropLast()) : baseURL
        self.apiKeyAccount = apiKeyAccount
        // The OpenAI chat wire format carries images (data URLs); whether the chosen model can
        // actually see them is the model's business. We advertise vision so the ⌥⇧V path is allowed.
        self.capabilities = Capabilities(streaming: true, agentic: false, sessions: false, vision: vision, tools: false)
    }

    func send(_ req: Prompt) -> AsyncThrowingStream<Chunk, Error> {
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            return singleMessageStream("[\(id)] Bad base URL: \(baseURL)")
        }
        let key = apiKeyAccount.flatMap { Keychain.read(service: "Seihitsu.apikeys", account: $0) }
        let isLoopback = baseURL.contains("localhost") || baseURL.contains("127.0.0.1")
        if (key == nil || key?.isEmpty == true) && !isLoopback, let acct = apiKeyAccount {
            return singleMessageStream("[\(id)] No API key. Add one:\n  security add-generic-password -s Seihitsu.apikeys -a \(acct) -w YOUR_KEY")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let key, !key.isEmpty { request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization") }

        // User content is a bare string, unless there is an image, in which case it becomes the
        // OpenAI multimodal array [text, image_url(data URL)].
        let userContent: Any
        if let img = req.imageData {
            userContent = [
                ["type": "text", "text": req.wireText()],
                ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(img.base64EncodedString())"]],
            ]
        } else {
            userContent = req.wireText()
        }
        let messages: [[String: Any]] = [
            ["role": "system", "content": req.system ?? HUDPrompts.system],
            ["role": "user", "content": userContent],
        ]
        let body: [String: Any] = [
            "model": req.model ?? model,
            "stream": true,
            "max_tokens": req.maxTokens ?? 1500,
            "messages": messages,
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        return SSEStream.run(request) { payload in
            guard let obj = SSEStream.json(payload),
                  let choices = obj["choices"] as? [[String: Any]],
                  let delta = choices.first?["delta"] as? [String: Any] else { return nil }
            return delta["content"] as? String
        }
    }
}
