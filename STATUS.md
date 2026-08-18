# Seihitsu Shirei - Status

## Current State
A working native macOS AI HUD. `app/` is a SwiftPM package (~1600 LOC, 24 files) that
bundles into `Seihitsu.app` and is running now as a menu-bar agent. Delivered:

- **Capture-excluded HUD** (`sharingType = .none`), verified against screenshots, screen
  shares (ScreenCaptureKit), and the legacy path. Glassmorphism look via NSVisualEffectView
  behind-window blur + a specular border.
- **Global hotkeys** (Carbon, no Accessibility needed for these): ⌘⇧Space summon/hide,
  ⌘⇧Return capture-selection, ⌘⇧C click-through.
- **Highlight-to-act**: ⌘⇧Return grabs the current selection from the frontmost app
  (Accessibility `kAXSelectedText`, falling back to a save/restore synthetic ⌘C). A
  highlighted question is answered with no typing; highlighted code/other is attached as
  context (shown as a chip) for an instruction.
- **Multi-model behind one `ModelBackend` interface**: Claude Code CLI + Codex CLI
  (subprocess) and Anthropic / OpenAI / Gemini / OpenAI-compatible (local, LM Studio) over
  HTTP+SSE. `ModelRouter` + `ProviderRegistry` (JSON in App Support); menu-bar Model
  submenu switches the active provider.
- **Settings window** (⌘, or menu): paste the Claude `setup-token` and API keys straight
  into the Keychain; saving a key auto-enables that provider in the switcher.
- **Capture self-test** (menu): live PASS/FAIL that the `.none` overlay is still excluded.

Build plan: `docs/ARCHITECTURE.md`. Decisions: `docs/collab/DECISIONS.md`.

## How to run
- Build + bundle: `app/Scripts/bundle.sh` then `open app/Seihitsu.app`.
- A live instance is already running (relaunched after the final build).

## Session Log

### 2026-08-16 to 18 (claude-2 / Vladimir)
- Proved capture-exclusion (`proof/capture-exclusion/`).
- Locked decisions: all-Swift single app; Claude Code CLI first backend.
- Built P1 native shell, then this session added: Prompt attachments, SelectionCapture,
  the ⌘⇧Return highlight-to-act flow + context chip, glassmorphism redesign, the full P2
  model layer (Codex + API adapters + router + registry), the model switcher, and a
  Settings window for credentials. All compiles clean; show-path and launch verified.

## Known Issues / not yet human-verified
- **Standalone `claude` CLI is not logged in** (revoked token). CLI backend returns an auth
  error until `claude setup-token` is run and the token is pasted into Settings (or the CLI
  is logged in). API backends need their keys pasted into Settings.
- Interactive flow (typing, focus, streaming render, live selection grab) is not
  human-verified yet - the HUD is `.none` so it cannot be screenshotted; only Hamza can see
  it. Show-path was exercised headlessly (no crash).
- Selection capture and API answers require permissions/keys: Accessibility (selection),
  Screen Recording (self-test), and API keys / the Claude token.
- Ad-hoc signing: TCC grants may reset on rebuild.

## Next Steps
1. Hamza: `claude setup-token` + paste into Settings; try ⌘⇧Space and ⌘⇧Return; report any
   HUD focus/render issues.
2. P3 - control center + Nexus tab. The in-app ControlAPI is buildable here; the Nexus tab
   is a cross-project edit (separate repo) that needs Hamza's go, per the plan.
3. P4 - voice (STT engine choice is a pause point). P5 - screen OCR (extends the Attachment
   path) + meeting notes.
