import Foundation

/// One configured backend. Adding a provider is one row here (plus an adapter for a genuinely
/// new wire format). Persisted as JSON in Application Support.
struct Provider: Codable, Identifiable, Equatable {
    enum Kind: String, Codable {
        case claudeCLI, codexCLI, anthropicAPI, geminiAPI, openaiCompatible
    }
    var id: String
    var name: String
    var kind: Kind
    var model: String
    var baseURL: String? = nil        // API kinds
    var keychainAccount: String? = nil // account under Keychain service "Seihitsu.apikeys"
    var enabled: Bool = true
}

/// Loads/saves the provider list and remembers which one is active.
final class ProviderRegistry {
    private(set) var providers: [Provider]
    private(set) var activeID: String

    private let fileURL: URL

    init() {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Seihitsu", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("providers.json")

        if let data = try? Data(contentsOf: fileURL),
           let saved = try? JSONDecoder().decode(SavedState.self, from: data), !saved.providers.isEmpty {
            // Merge in any default providers added since this file was written (e.g. OpenRouter),
            // so upgrades surface new providers without wiping the user's edits.
            var merged = saved.providers
            for def in Self.defaults where !merged.contains(where: { $0.id == def.id }) {
                merged.append(def)
            }
            providers = merged
            activeID = saved.activeID
        } else {
            providers = Self.defaults
            activeID = Self.defaults.first?.id ?? "openrouter"
        }
        if !providers.contains(where: { $0.id == activeID }) {
            activeID = providers.first?.id ?? "openrouter"
        }
        save()
    }

    func setActive(_ id: String) {
        guard providers.contains(where: { $0.id == id }) else { return }
        activeID = id
        save()
    }

    func setEnabled(_ id: String, _ enabled: Bool) {
        guard let idx = providers.firstIndex(where: { $0.id == id }) else { return }
        providers[idx].enabled = enabled
        save()
    }

    var active: Provider {
        providers.first { $0.id == activeID } ?? providers[0]
    }

    var enabledProviders: [Provider] { providers.filter { $0.enabled } }

    private func save() {
        let state = SavedState(providers: providers, activeID: activeID)
        if let data = try? JSONEncoder().encode(state) { try? data.write(to: fileURL) }
    }

    private struct SavedState: Codable {
        var providers: [Provider]
        var activeID: String
    }

    static let defaults: [Provider] = [
        Provider(id: "openrouter", name: "OpenRouter (Llama 4 Scout)", kind: .openaiCompatible,
                 model: "meta-llama/llama-4-scout", baseURL: "https://openrouter.ai/api/v1",
                 keychainAccount: "openrouter", enabled: true),
        Provider(id: "claude-code", name: "Claude Code (sub)", kind: .claudeCLI, model: "sonnet"),
        Provider(id: "codex", name: "Codex (sub)", kind: .codexCLI, model: ""),
        Provider(id: "local", name: "Local (LM Studio)", kind: .openaiCompatible, model: "local-model",
                 baseURL: "http://localhost:1234/v1", keychainAccount: nil, enabled: true),
        Provider(id: "anthropic", name: "Anthropic API", kind: .anthropicAPI, model: "claude-sonnet-4-5",
                 keychainAccount: "anthropic", enabled: false),
        Provider(id: "openai", name: "OpenAI API", kind: .openaiCompatible, model: "gpt-5",
                 baseURL: "https://api.openai.com/v1", keychainAccount: "openai", enabled: false),
        Provider(id: "gemini", name: "Gemini API", kind: .geminiAPI, model: "gemini-2.5-pro",
                 keychainAccount: "gemini", enabled: false),
    ]
}
