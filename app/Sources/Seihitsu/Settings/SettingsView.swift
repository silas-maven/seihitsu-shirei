import SwiftUI
import AppKit
import ApplicationServices
import CoreGraphics
import AVFoundation
import Speech

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var claudeToken = ""
    @Published var openrouterKey = ""
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
            "openrouter": has(service: "Seihitsu.apikeys", account: "openrouter"),
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
        for (value, account, label) in [(openrouterKey, "openrouter", "OpenRouter"),
                                        (anthropicKey, "anthropic", "Anthropic"),
                                        (openaiKey, "openai", "OpenAI"),
                                        (geminiKey, "gemini", "Gemini")] {
            let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                Keychain.write(service: "Seihitsu.apikeys", account: account, value: trimmed)
                saved.append(label)
            }
        }
        status = saved.isEmpty ? "Nothing to save." : "Saved: \(saved.joined(separator: ", "))"
        claudeToken = ""; openrouterKey = ""; anthropicKey = ""; openaiKey = ""; geminiKey = ""
        refreshFlags()
        onSaved()
    }
}

struct SettingsView: View {
    @ObservedObject var vm: SettingsViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Credentials").font(.headline)
                Text("Stored in the macOS Keychain, never on disk in plaintext. Fields clear after saving.")
                    .font(.caption).foregroundStyle(.secondary)

                field("OpenRouter API key", note: "current default provider", key: "openrouter", text: $vm.openrouterKey)
                field("Claude Code token", note: "from `claude setup-token`", key: "claude", text: $vm.claudeToken)
                field("Anthropic API key", note: "enables Anthropic API", key: "anthropic", text: $vm.anthropicKey)
                field("OpenAI API key", note: "enables OpenAI API", key: "openai", text: $vm.openaiKey)
                field("Gemini API key", note: "enables Gemini API", key: "gemini", text: $vm.geminiKey)

                HStack {
                    Button("Save") { vm.save() }.keyboardShortcut(.defaultAction)
                    Text(vm.status).font(.caption).foregroundStyle(.secondary)
                    Spacer()
                }

                Divider().padding(.vertical, 4)

                Text("Permissions").font(.headline)
                permissionRow("Accessibility", granted: AXIsProcessTrusted(),
                              pane: "Privacy_Accessibility", note: "highlight-to-act (⌥C)")
                permissionRow("Microphone", granted: AVCaptureDevice.authorizationStatus(for: .audio) == .authorized,
                              pane: "Privacy_Microphone", note: "voice input (Listen, ⌥L)")
                permissionRow("Speech Recognition", granted: SFSpeechRecognizer.authorizationStatus() == .authorized,
                              pane: "Privacy_SpeechRecognition", note: "on-device transcription")
                permissionRow("Screen Recording", granted: CGPreflightScreenCaptureAccess(),
                              pane: "Privacy_ScreenCapture", note: "capture self-test / future OCR")
                Text("First press of Listen (⌥L) will pop the Microphone and Speech prompts; click Allow. After granting, quit and relaunch Seihitsu. Ad-hoc builds may need re-granting after a rebuild.")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            .padding(20)
        }
        .frame(width: 480, height: 600)
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

    private func permissionRow(_ title: String, granted: Bool, pane: String, note: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: granted ? "checkmark.circle.fill" : "exclamationmark.circle")
                .foregroundStyle(granted ? .green : .orange)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).font(.subheadline.bold())
                Text(note).font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            Button("Open") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(pane)") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
}
