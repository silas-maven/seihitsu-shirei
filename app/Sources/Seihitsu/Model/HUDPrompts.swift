import Foundation

/// Shared system guidance. The HUD is a small overlay, so brevity is the default posture.
enum HUDPrompts {
    static let system = """
    You are a concise heads-up assistant shown in a small always-on-top overlay. Answer in \
    the fewest words that are fully correct. No preamble, no restating the question, no \
    sign-off. For code, output the corrected code first (in a fenced block), then at most one \
    short line explaining the fix. Prefer short answers; expand only when essential.
    """

    /// Default instruction when the user highlights code and wants it fixed.
    static let fixCode = "Find the problem in this code and output a corrected version. Be concise: show the fixed code, then one short line on what was wrong."

    /// Instruction paired with text read off the screen via OCR (⌥V). The captured text is
    /// attached above this line, so the model answers the question it finds without the user
    /// typing anything.
    static let answerScreen = "The text above was read from the user's screen. It contains a question or a task. Answer it directly in a few short lines. If it is a technical how-to (for example a Docker, git, or shell issue), give the concrete steps or commands. Do not describe the screenshot or restate the question; just answer it. If the text has no question in it, say so in one line."

    /// Brief mode: one or two lines, for when you are moving quickly.
    static let brief = """
    You are answering under time pressure in a small overlay. Give only the answer, in one \
    or two short lines. No preamble, no restating the question, no explanation unless a single \
    clause is essential. For code, output only the corrected line(s).
    """

    /// Blitz mode: the answer only, for a question with a countdown timer.
    static let blitz = """
    You are answering a question that has a countdown timer. Output ONLY the answer itself, in \
    the fewest characters possible, and nothing else. For multiple choice, output only the \
    correct option (its letter and/or its text). No preamble, no explanation, no restating the \
    question, no trailing notes. If you are unsure, give your single best guess only.
    """
}

/// How much to say and how fast to finish. Drives both the system prompt and a hard output cap.
/// Persisted across launches; set in the HUD or cycled with ⌥⇧S.
enum AnswerMode: String, CaseIterable {
    case full, brief, blitz

    var label: String {
        switch self {
        case .full:  return "Full"
        case .brief: return "Brief"
        case .blitz: return "Blitz"
        }
    }

    /// nil keeps the default concise system prompt (and each backend's default cap).
    var system: String? {
        switch self {
        case .full:  return nil
        case .brief: return HUDPrompts.brief
        case .blitz: return HUDPrompts.blitz
        }
    }

    var maxTokens: Int? {
        switch self {
        case .full:  return nil    // backend default (~1500)
        case .brief: return 220
        case .blitz: return 40
        }
    }
}
