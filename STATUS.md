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

### 2026-08-19f (claude-2 / Vladimir) - committed + pushed; clean-setup README
- Hamza: "commit this and push to repo." Committed the full body of uncommitted `app/`
  work (native HUD, highlight-to-act capture, glass, P2 model layer, Settings +
  permissions, Listen, reveal toggle, file logging, icon, signing scripts) + STATUS.md on
  branch `claude/project-familiarization-45fead`; pushed to origin (branch only, not main).
- Rewrote `README.md` from the scaffold-only stub into a clean setup guide: quick start
  via `fix-permissions.sh`, why stable signing matters (do NOT delete the cert), hotkey
  table, features, and troubleshooting (incl. the `tccutil reset Accessibility
  com.jarvis.seihitsu` cure for the stale-TCC capture failure).
- No code changes this session. Capture remains the one broken feature, pending Hamza's
  tccutil reset (a blocked write for the agent).

### 2026-08-19c (claude-2 / Vladimir) - Listen render fix; signing cert deleted
- Fixed Listen "blinks and stops": removed forced on-device recognition (errors instantly
  when the model isn't ready); tap now uses hardware inputFormat + validation; logs errors.
- Capture "feels like copy-paste": resolved by the Accessibility grant (⌥C auto-copies the
  selection). One function, no code change.
- **Signing cert was deleted** (removing the "duplicate" removed the only identity) -> builds
  fell back to ad-hoc -> permissions reset. Stopped rebuilding. Added `Scripts/fix-permissions.sh`
  (one-shot: recreate cert + rebuild stable + relaunch). Hamza must run it once on wake.

### 2026-08-19b (claude-2 / Vladimir) - Listen-stop fix + stable signing
- Fixed Listen not stopping (deterministic teardown in SpeechListener.stop + VM resets
  isListening). Fixed stale ⌘⇧Return message -> ⌥C.
- Root-caused permission re-prompts = ad-hoc signing (code hash changes each rebuild ->
  TCC forgets grants). Added `Scripts/setup-signing.sh` (self-signed identity; Hamza runs
  it - keychain writes are blocked for the agent). `bundle.sh` uses it when present.

### 2026-08-19 (claude-2 / Vladimir) - capture clipboard bug, reveal toggle, icon
- Fixed capture returning STALE clipboard when Cmd-C copied nothing (now checks
  `pb.changeCount`). Added capture-tier logging.
- Added "Reveal HUD in Screenshots (debug)" menu toggle (.none <-> .readOnly) for
  troubleshooting.
- Swapped in Hamza's own icon (purple Rinnegan) at `Resources/AppIcon-source.png`.

### 2026-08-18 late (claude-2 / Vladimir) - voice, HUD buttons, recenter fix
- Fixed HUD snapping back to center on capture (now centers only on first open).
- Added Capture + Listen buttons in the HUD + ⌥L shortcut + menu item.
- Voice input: `App/SpeechListener.swift` (Apple on-device Speech). Speak -> transcript ->
  auto-submit. Needs Mic + Speech Recognition perms.
- Icon swap is now a one-file drop: replace `Resources/AppIcon-source.png`, rerun bundle.sh.

### 2026-08-18 eve (claude-2 / Vladimir) - stickiness, logging, icon
- HUD window level `.screenSaver` -> `.floating` (was blocking the menu bar + System
  Settings; that's why auth required hiding the HUD). Esc dismisses; Settings/Grant hide
  the HUD first.
- File logger at ~/Library/Logs/Seihitsu/seihitsu.log (menu "Reveal Logs"). Confirmed all
  3 hotkeys register and ⌥C fires - the capture failure was the missing Accessibility grant.
- App icon via Higgsfield -> Resources/AppIcon.icns, wired into the bundle.

### 2026-08-18 pm (claude-2 / Vladimir) - real-use feedback pass
- Fixed copy/paste (accessory app needs an Edit menu; added NSApp.mainMenu) + Copy button.
- Added OpenRouter provider (llama-4-scout), made it default; registry now merges new
  default providers into saved state. Settings gained an OpenRouter field + Permissions panel.
- Hotkeys -> Option-based (⌥Space / ⌥C / ⌥⇧C) + menu-bar fallbacks (Capture, Grant
  Accessibility). Highlight-to-act: code auto-fixes, questions auto-answer.
- Concise output (shared system prompt + max_tokens). HUD now resizable + larger.
- bundle.sh installs to ~/Applications (Spotlight "Seihitsu"). Installed + running.

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
