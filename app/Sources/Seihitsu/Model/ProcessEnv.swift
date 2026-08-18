import Foundation

/// A minimal, predictable environment for spawned CLIs. Deliberately omits a parent
/// process's staging/proxy auth vars (ANTHROPIC_BASE_URL, USE_*_OAUTH, CLAUDE_CODE_*),
/// so a subprocess authenticates against production with its own stored credentials.
enum ProcessEnv {
    static func base() -> [String: String] {
        let parent = ProcessInfo.processInfo.environment
        var env: [String: String] = [:]
        for key in ["HOME", "USER", "LOGNAME", "LANG", "LC_ALL", "TERM", "TMPDIR", "SHELL",
                    "SSL_CERT_FILE", "__CF_USER_TEXT_ENCODING"] {
            if let v = parent[key] { env[key] = v }
        }
        let path = parent["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin"
        env["PATH"] = "\(NSHomeDirectory())/.local/bin:/opt/homebrew/bin:/usr/local/bin:\(path)"
        return env
    }
}
