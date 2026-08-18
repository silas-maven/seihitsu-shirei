# Seihitsu Shirei - Architecture & Build Plan

Private macOS AI copilot HUD. A menu-bar-controlled, borderless, always-on-top panel
that stays out of screenshots and screen shares (`NSWindow.sharingType = .none`), reads
a question, and streams an answer in a surface only the operator sees.

Capture-exclusion is proven (see `proof/capture-exclusion/`): a `.none` panel is omitted
from the local system screenshot, ScreenCaptureKit (the screen-share path), and the
legacy CG path, while a `.readOnly` control panel beside it is captured normally.
Verified on macOS 26.5.

## Locked decisions

See `docs/collab/DECISIONS.md` for the reasoning. In short:

1. **All-Swift single app.** No sidecar service, no daemon, nothing on a port by
   default, one self-contained binary. The model/routing brain lives inside the app.
2. **Subscription CLI wired first.** P1's first model backend is the Claude Code CLI,
   driven as a subprocess and authed by the existing subscription login. Zero API keys
   needed to reach a working MVP.

## Topology (all-Swift)

```
menu-bar agent (.accessory, NSStatusItem)
  ├─ HUD: borderless NSPanel, sharingType = .none, SwiftUI content
  ├─ global hotkeys (summon/hide, listen toggle, click-through)
  ├─ Brain (in-process)
  │    ├─ ModelRouter
  │    ├─ ModelBackend adapters (see below)
  │    ├─ ProviderRegistry (config) + Keychain (secrets)
  │    ├─ SessionStore (SQLite)
  │    └─ STT abstraction            [P4]
  ├─ ScreenContext: capture + Vision OCR   [P5]
  ├─ AudioCapture: mic + system audio      [P4]
  └─ ControlAPI: localhost 127.0.0.1 HTTP/WS, token-auth   [P3]
         └─ client: Nexus tab "Seihitsu" (control center)
```

The brain is in-process. Nexus does not host it; Nexus is a *client* of the app's
ControlAPI. The HUD works whether or not Nexus is open.

## The model layer (the load-bearing abstraction)

One internal streaming type. Every backend normalizes to it. The HUD and ControlAPI
only ever see `ModelBackend`. Adding a provider is one adapter plus one registry row;
nothing else changes.

```swift
protocol ModelBackend {
    var id: String { get }
    var capabilities: Capabilities { get }   // agentic, sessions, vision, tools, streaming
    func send(_ req: Prompt) -> AsyncThrowingStream<Chunk, Error>
}
```

Two auth worlds, same interface:

| Family | Adapters | Auth | Notes |
|---|---|---|---|
| **Subscription CLI** | `ClaudeCodeBackend` (P1), `CodexBackend` (P2) | existing login | subprocess; agentic/session-capable; ~free at margin; flags are a moving target, isolate them |
| **API providers** | `AnthropicAPIBackend`, `OpenAIAPIBackend`, `GeminiAPIBackend`, `OpenAICompatibleBackend` (P2) | API key in Keychain | HTTP + SSE; `OpenAICompatible` covers LM Studio / Ollama / OpenRouter / Groq etc. |

Backends' differences are `capabilities` flags, not separate code paths. The HUD Q&A use
case wants single-shot low latency, so CLI backends run in their simplest print/exec
mode with tools off; agentic mode is a later capability, not the default.

### Grounded CLI invocations (verified installed)

- Claude Code `2.1.170` at `~/.local/bin/claude`:
  `claude --print --output-format stream-json --verbose --model <alias> "<prompt>"`
  emits line-delimited JSON events; parse assistant text, stream to HUD.
- Codex `0.145.0` at `/opt/homebrew/bin/codex`: `codex exec` for non-interactive runs.

## Native building blocks

- **Menu bar / lifecycle:** `NSApplication` `.accessory`, `NSStatusItem`.
- **HUD:** borderless `NSPanel` (`.nonactivatingPanel`), `sharingType = .none`,
  `level = .screenSaver`, `collectionBehavior` all-spaces, `ignoresMouseEvents` for
  click-through. SwiftUI content hosted via `NSHostingView`.
- **Global hotkeys:** `KeyboardShortcuts` (Sindre Sorhus SPM lib) or Carbon
  `RegisterEventHotKey`. Needs Input Monitoring / Accessibility.
- **Secrets:** Keychain. Never plaintext, never in code.
- **Persistence:** SQLite (GRDB or SQLite.swift); JSON files acceptable for the earliest
  cut.
- **ControlAPI:** small embedded HTTP/WS server (Network.framework, or Swifter /
  Hummingbird). Bind 127.0.0.1 only, local token auth.

## Listen / voice control (P4)

State machine surfaced in the menu-bar icon and the panel:
`idle → listening → transcribing → sending → responding`. Listen/stop are HUD buttons
plus global hotkeys. Wires to mic (AVAudioEngine) and system audio (ScreenCaptureKit
audio), feeding a streaming STT that is abstracted exactly like `ModelBackend` (local
Whisper vs cloud is a swap, not a rewrite).

## Permissions (TCC)

Screen Recording (capture/OCR, system audio), Microphone (voice), Accessibility / Input
Monitoring (global hotkeys, reading other apps). Each prompts the user. Ship a runtime
self-test that asserts "verified hidden on this OS version" rather than assuming, since
`.none` semantics are OS-version-sensitive.

## Phasing

- **P0 - proof** ✅ capture-exclusion verified three ways.
- **P1 - native shell MVP.** Menu-bar agent, `.none` HUD panel, global hotkey
  summon/hide, click-through toggle, text input, `ClaudeCodeBackend` streaming an answer
  into the HUD. **Done =** type a question, watch it stream in, panel absent from a
  screenshot. No keys, no daemon.
- **P2 - model layer.** `ModelBackend` protocol + `ModelRouter`, ProviderRegistry,
  Keychain, add `CodexBackend` + the API adapters, model switcher in the HUD.
- **P3 - control center + Nexus.** ControlAPI in the app; Nexus tab "Seihitsu" as its
  client (dark / cyan / Roboto Mono, matching Nexus).
- **P4 - listen / voice.** Audio capture + STT + the toggles and state machine.
- **P5 - screen context.** Capture + Vision OCR feeding the model; then meeting
  transcription + note-taking.

## Open questions (not blocking P1)

- Hotkey library: `KeyboardShortcuts` lib vs raw Carbon.
- Persistence: SQLite lib choice vs JSON for the first cut.
- ControlAPI transport: HTTP+SSE vs WebSocket for streaming to Nexus.
- STT engine for P4: on-device (Speech / whisper.cpp) vs cloud.
