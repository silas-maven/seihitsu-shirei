import Foundation

/// Shared system guidance. The HUD is a small overlay, so brevity is the default posture.
enum HUDPrompts {
    static let system = """
    You are a concise heads-up assistant shown in a small always-on-top overlay. Answer in \
    the fewest words that are fully correct. No preamble, no restating the question, no \
    sign-off. For code, be specific: point to the exact problem and the precise fix. Prefer \
    short answers; expand only when essential.
    """

    /// Highlighted code, "Fix" mode: return the corrected version.
    static let fixCode = "Find the problem in this code and output a corrected version. Be concise: show the fixed code, then one short line on what was wrong."

    /// Highlighted code, "Explain" mode (the default): explain the fault and the fix, without
    /// pasting a full rewrite. For reviewing a snippet you have to talk about.
    static let explainCode = "This is a code snippet. Explain specifically what is wrong with it and how to fix it: name the exact line or token at fault and state the change needed, in a few short lines. Do NOT paste a full corrected version of the code; describe the fix precisely. If nothing is wrong, say in one or two lines what the code does."

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

/// What to do when captured content is code. Explain (the default) reviews it, naming the fault
/// and the fix without a full rewrite; Fix returns the corrected code. Persisted; set in the menu.
enum CodeAction: String, CaseIterable {
    case explain, fix

    var label: String {
        switch self {
        case .explain: return "Explain"
        case .fix:     return "Fix (rewrite)"
        }
    }

    var instruction: String {
        switch self {
        case .explain: return HUDPrompts.explainCode
        case .fix:     return HUDPrompts.fixCode
        }
    }
}

/// A use-case preset. Selecting one snaps the speed and code mode and adds a short persona line to
/// the system prompt. `standard` is exactly how the app behaves with no profile chosen. Persisted.
enum Profile: String, CaseIterable {
    case standard, mcq, solve, review, coding, systemDesign, fde, behavioural, meeting

    var label: String {
        switch self {
        case .standard:     return "Standard"
        case .mcq:          return "Exam / MCQ"
        case .solve:        return "Coding assessment"
        case .review:       return "Code review"
        case .coding:       return "Coding interview"
        case .systemDesign: return "System design"
        case .fde:          return "FDE interview"
        case .behavioural:  return "Behavioural"
        case .meeting:      return "Meeting / call"
        }
    }

    var answerMode: AnswerMode {
        switch self {
        case .mcq:                             return .blitz
        case .coding, .fde, .behavioural, .meeting: return .brief
        case .standard, .solve, .review, .systemDesign: return .full
        }
    }

    var codeAction: CodeAction {
        switch self {
        case .solve: return .fix          // an assessment wants the full working solution
        default:     return .explain
        }
    }

    /// Persona/context appended to the system prompt. nil for `standard` (unchanged behaviour).
    var systemAddendum: String? {
        switch self {
        case .standard:
            return nil
        case .mcq:
            return "You are answering timed multiple-choice or exam questions. Give only the correct option or answer."
        case .solve:
            return "You are in a coding assessment. Produce a complete, correct, runnable solution including the code."
        case .review:
            return "You are reviewing code in a live technical assessment. Identify the bug or issue and how to fix it specifically. If several files or snippets are attached, reason about them together."
        case .coding:
            return "You are assisting in a live coding interview. Give concise talking points: the approach and the reasoning to say out loud."
        case .systemDesign:
            return "You are assisting in a system design interview. Answer in structured, concise points: requirements, high-level design, key components, data model, trade-offs, and how it scales."
        case .fde:
            return "You are assisting in a Forward Deployed Engineer interview, a mix of live coding, debugging, and customer-facing system design. Be concise, practical, and specific."
        case .behavioural:
            return "You are assisting in a behavioural interview. Suggest a concise, confident answer using the STAR structure (Situation, Task, Action, Result)."
        case .meeting:
            return "You are assisting in a live meeting or sales call. Offer concise, useful talking points and answers as the conversation moves."
        }
    }
}
