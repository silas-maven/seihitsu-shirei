import Foundation

/// Drives the Claude Code CLI as a subprocess, authed by the user's subscription login.
///
/// Auth note: the standalone `claude` binary needs its own login. If the machine's stored
/// token is revoked/absent, generate a long-lived token once with `claude setup-token` and
/// store it (service `Seihitsu.claude-code`, account `oauth-token`); it is injected as
/// CLAUDE_CODE_OAUTH_TOKEN. We spawn with a scrubbed environment so a parent process's
/// staging/proxy auth vars never leak in.
final class ClaudeCodeBackend: ModelBackend {
    let id = "claude-code"
    let capabilities = Capabilities(streaming: true, agentic: false, sessions: true, vision: false, tools: false)

    private let binary: String
    private let model: String

    init(binary: String = "\(NSHomeDirectory())/.local/bin/claude", model: String = "sonnet") {
        self.binary = binary
        self.model = model
    }

    func send(_ req: Prompt) -> AsyncThrowingStream<Chunk, Error> {
        AsyncThrowingStream { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: binary)
            process.arguments = [
                "--print",
                "--output-format", "stream-json",
                "--verbose",
                "--include-partial-messages",
                "--model", req.model ?? model,
                "--disallowedTools", "Bash Edit Write Read WebFetch WebSearch NotebookEdit Task Glob Grep",
                "--append-system-prompt", req.system ?? Self.defaultSystem,
            ]
            process.environment = Self.scrubbedEnvironment()

            let stdout = Pipe(), stderr = Pipe(), stdin = Pipe()
            process.standardOutput = stdout
            process.standardError = stderr
            process.standardInput = stdin

            let parser = StreamJSONParser()

            stdout.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty else { return }
                for event in parser.consume(data) {
                    switch event {
                    case .text(let t): continuation.yield(.text(t))
                    case .resultError(let msg): continuation.yield(.text("\n[claude] \(msg)"))
                    case .result: break
                    }
                }
            }

            process.terminationHandler = { proc in
                stdout.fileHandleForReading.readabilityHandler = nil
                for event in parser.flush() {
                    if case .text(let t) = event { continuation.yield(.text(t)) }
                }
                if proc.terminationStatus != 0 && !parser.emittedText {
                    let errData = stderr.fileHandleForReading.readDataToEndOfFile()
                    let msg = (String(data: errData, encoding: .utf8) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                    let detail = msg.isEmpty ? "no output (is the standalone `claude` CLI logged in? try `claude setup-token`)" : msg
                    continuation.yield(.text("[claude exited \(proc.terminationStatus)] \(detail)"))
                }
                continuation.yield(.done)
                continuation.finish()
            }

            do {
                try process.run()
            } catch {
                continuation.finish(throwing: error)
                return
            }

            // Prompt via stdin (avoids arg-length and escaping pitfalls). Attachments
            // (highlighted selection/code, later OCR text) are composed in by wireText().
            let handle = stdin.fileHandleForWriting
            if let d = req.wireText().data(using: .utf8) { handle.write(d) }
            try? handle.close()

            continuation.onTermination = { _ in
                if process.isRunning { process.terminate() }
            }
        }
    }

    static let defaultSystem = "You are a heads-up assistant shown in a small always-on-top overlay. Answer directly and concisely in plain text. No preamble, no tool use."

    /// A minimal environment plus an explicit subscription token, so inherited staging/proxy
    /// auth from a parent process cannot poison the call.
    static func scrubbedEnvironment() -> [String: String] {
        var env = ProcessEnv.base()
        if let token = Keychain.read(service: "Seihitsu.claude-code", account: "oauth-token"), !token.isEmpty {
            env["CLAUDE_CODE_OAUTH_TOKEN"] = token
        }
        return env
    }
}
