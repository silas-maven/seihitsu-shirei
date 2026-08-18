import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var claudeToken = ""
    @Published var anthropicKey = ""
    @Published var openaiKey = ""
    @Published var geminiKey = ""
    @Published var status = ""
    @Published var setFlags: [String: Bool] = [:]

    let onSaved: () -> Void

    init(onSaved: @escaping () -> Void) {
        self.onSaved = onSaved
        refreshFlags()
    }

    func isSet(_ label: String) -> Bool { setFlags[label] ?? false }

    private func refreshFlags() {
        setFlags = [
            "claude": has(service: "Seihitsu.claude-code", account: "oauth-token"),
            "anthropic": has(service: "Seihitsu.apikeys", account: "anthropic"),
            "openai": has(service: "Seihitsu.apikeys", account: "openai"),
            "gemini": has(service: "Seihitsu.apikeys", account: "gemini"),
        ]
    }

    private func has(service: String, account: String) -> Bool {
        (Keychain.read(service: service, account: account)?.isEmpty == false)
    }

    func save() {
        var saved: [String] = []
        if !claudeToken.isEmpty {
            Keychain.write(service: "Seihitsu.claude-code", account: "oauth-token", value: claudeToken.trimmingCharacters(in: .whitespacesAndNewlines))
            saved.append("Claude token")
        }
        for (value, account, label) in [(anthropicKey, "anthropic", "Anthropic"),
                                        (openaiKey, "openai", "OpenAI"),
                                        (geminiKey, "gemini", "Gemini")] {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                Keychain.write(service: "Seihitsu.apikeys", account: account, value: trimmed)
                saved.append(label)
            }
        }
        status = saved.isEmpty ? "Nothing to save." : "Saved: \(saved.joined(separator: ", "))"
        claudeToken = ""; anthropicKey = ""; openaiKey = ""; geminiKey = ""
        refreshFlags()
        onSaved()
    }
}

struct SettingsView: View {
    @ObservedObject var vm: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Credentials").font(.headline)
            Text("Values are stored in the macOS Keychain and never written to disk in plaintext. Fields clear after saving.")
                .font(.caption).foregroundStyle(.secondary)

            field("Claude Code token", note: "from `claude setup-token`", key: "claude", text: $vm.claudeToken)
            field("Anthropic API key", note: "enables Anthropic API", key: "anthropic", text: $vm.anthropicKey)
            field("OpenAI API key", note: "enables OpenAI API", key: "openai", text: $vm.openaiKey)
            field("Gemini API key", note: "enables Gemini API", key: "gemini", text: $vm.geminiKey)

            HStack {
                Button("Save") { vm.save() }.keyboardShortcut(.defaultAction)
                Text(vm.status).font(.caption).foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding(20)
        .frame(width: 480, height: 420, alignment: .topLeading)
    }

    private func field(_ title: String, note: String, key: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Text(title).font(.subheadline.bold())
                if vm.isSet(key) {
                    Label("set", systemImage: "checkmark.circle.fill")
                        .labelStyle(.titleAndIcon).font(.caption2).foregroundStyle(.green)
                }
                Spacer()
                Text(note).font(.caption2).foregroundStyle(.secondary)
            }
            SecureField(vm.isSet(key) ? "•••••••• (saved, type to replace)" : "paste here", text: text)
                .textFieldStyle(.roundedBorder)
        }
    }
}
