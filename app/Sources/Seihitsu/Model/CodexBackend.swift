import Foundation

/// Drives the OpenAI Codex CLI as a subprocess, authed by its own login (ChatGPT/API).
/// Runs `codex exec` in a read-only sandbox so it never executes model-proposed commands,
/// and reads the final message from `-o <file>` for a clean, deterministic answer.
///
/// Not token-streamed (Codex is a secondary backend; Claude Code is the streaming daily
/// driver). The full answer is emitted on completion.
final class CodexBackend: ModelBackend {
    let id: String
    let capabilities = Capabilities(streaming: false, agentic: true, sessions: false, vision: false, tools: false)

    private let binary: String
    private let model: String

    init(id: String = "codex", binary: String = "/opt/homebrew/bin/codex", model: String = "") {
        self.id = id
        self.binary = binary
        self.model = model
    }

    func send(_ req: Prompt) -> AsyncThrowingStream<Chunk, Error> {
        AsyncThrowingStream { continuation in
            let tmp = (NSTemporaryDirectory() as NSString).appendingPathComponent("seihitsu-codex-\(UUID().uuidString).txt")
            let process = Process()
            process.executableURL = URL(fileURLWithPath: binary)
            var args = ["exec", "-s", "read-only", "--skip-git-repo-check", "--color", "never",
                        "-o", tmp]
            let chosen = req.model ?? model
            if !chosen.isEmpty { args.append(contentsOf: ["-m", chosen]) }
            args.append(req.wireText())
            process.arguments = args
            process.environment = ProcessEnv.base()

            let errPipe = Pipe(), outPipe = Pipe()
            process.standardError = errPipe
            process.standardOutput = outPipe

            process.terminationHandler = { proc in
                let answer = (try? String(contentsOfFile: tmp, encoding: .utf8))?
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                try? FileManager.default.removeItem(atPath: tmp)
                if !answer.isEmpty {
                    continuation.yield(.text(answer))
                } else if proc.terminationStatus != 0 {
                    let e = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                    let detail = e.trimmingCharacters(in: .whitespacesAndNewlines)
                    continuation.yield(.text("[codex exited \(proc.terminationStatus)] \(detail.isEmpty ? "no output (is `codex` logged in?)" : detail)"))
                }
                continuation.yield(.done)
                continuation.finish()
            }

            do { try process.run() } catch {
                continuation.finish(throwing: error)
                return
            }
            continuation.onTermination = { _ in if process.isRunning { process.terminate() } }
        }
    }
}
