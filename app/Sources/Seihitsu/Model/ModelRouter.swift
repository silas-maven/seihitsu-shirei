import Foundation

/// Resolves the active provider to a concrete `ModelBackend`. The HUD asks for a backend per
/// request, so switching providers takes effect on the next message.
@MainActor
final class ModelRouter: ObservableObject {
    @Published private(set) var activeID: String
    var onChange: (() -> Void)?

    private let registry: ProviderRegistry
    private var cache: [String: ModelBackend] = [:]

    init(registry: ProviderRegistry = ProviderRegistry()) {
        self.registry = registry
        self.activeID = registry.activeID
    }

    var providers: [Provider] { registry.enabledProviders }
    var active: Provider { registry.active }

    func setActive(_ id: String) {
        registry.setActive(id)
        activeID = registry.activeID
        onChange?()
    }

    func setProviderEnabled(_ id: String, _ enabled: Bool) {
        registry.setEnabled(id, enabled)
        onChange?()
    }

    /// A backend for the active provider (cached per provider id).
    func backend() -> ModelBackend { backend(for: registry.active) }

    func backend(for provider: Provider) -> ModelBackend {
        if let cached = cache[provider.id] { return cached }
        let made = make(provider)
        cache[provider.id] = made
        return made
    }

    private func make(_ p: Provider) -> ModelBackend {
        switch p.kind {
        case .claudeCLI:
            return ClaudeCodeBackend(model: p.model.isEmpty ? "sonnet" : p.model)
        case .codexCLI:
            return CodexBackend(id: p.id, model: p.model)
        case .anthropicAPI:
            return AnthropicAPIBackend(id: p.id, model: p.model, apiKeyAccount: p.keychainAccount ?? "anthropic")
        case .geminiAPI:
            return GeminiAPIBackend(id: p.id, model: p.model, apiKeyAccount: p.keychainAccount ?? "gemini")
        case .openaiCompatible:
            return OpenAICompatibleBackend(id: p.id, model: p.model,
                                           baseURL: p.baseURL ?? "https://api.openai.com/v1",
                                           apiKeyAccount: p.keychainAccount)
        }
    }
}
