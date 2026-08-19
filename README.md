# Seihitsu Shirei

**静謐司令 - "quiet command."** A private, native macOS AI copilot HUD: a menu-bar
controlled, borderless, always-on-top glass panel that stays **out of screenshots and
screen shares** (`NSWindow.sharingType = .none`), reads whatever you highlight, and
streams an answer in a surface only you can see.

Highlight a question anywhere, press a hotkey, and the answer appears in a floating panel
that does not show up when you screenshot or share your screen. Highlight code and it
returns a fix. Speak and it transcribes on-device.

Capture-exclusion is proven three ways (system screenshot, ScreenCaptureKit screen-share
path, legacy CG path); see `proof/capture-exclusion/`.

---

## Requirements

- **macOS 14 (Sonoma) or newer.** Built and run on macOS 26.
- **Swift toolchain 5.9+** - either Xcode, or the Command Line Tools:
  ```bash
  xcode-select --install
  ```
- **A model provider key** (for answers). The default provider is OpenRouter
  (`meta-llama/llama-4-scout`); you paste the key into Settings after first launch. Any of
  OpenAI / Anthropic / Gemini / an OpenAI-compatible endpoint (LM Studio, Ollama, Groq)
  works too, or a logged-in Claude Code / Codex CLI.

---

## Quick start (the clean path)

Run these from the repository root. This is the whole setup, and it avoids the
permission churn described below.

```bash
app/Scripts/fix-permissions.sh
```

That one script does everything in order:

1. **Creates a stable code-signing identity** (`Seihitsu Self-Signed`, added to your login
   keychain). Approve the keychain dialog if one appears.
2. **Builds and installs** the app to `~/Applications/Seihitsu.app` (Spotlight-searchable
   as "Seihitsu").
3. **Launches it.** A menu-bar icon appears.

Then, one time only:

4. **Add a model key.** Menu-bar icon -> Settings (or `⌘,`), paste your OpenRouter (or
   other provider) key, and it auto-enables that provider.
5. **Grant permissions when asked.** Press `⌥C` over some highlighted text to trigger the
   Accessibility prompt; press `⌥L` to trigger the Microphone + Speech prompt. Allow both.
   If a keychain dialog asks about `Seihitsu.apikeys`, click **Always Allow** (that is just
   the app reading the key you saved).

Because the signing identity is stable, **this is the last time you will be asked for
permissions.** That is the whole point of step 1, see below.

### Or, step by step

```bash
app/Scripts/setup-signing.sh   # once: stable signing identity (approve keychain prompt)
app/Scripts/bundle.sh          # build + install to ~/Applications/Seihitsu.app
open ~/Applications/Seihitsu.app
```

Rebuilding later is just `app/Scripts/bundle.sh` again. Grants survive rebuilds as long as
the signing identity is unchanged.

---

## Why the signing step matters (read this once)

This is the trap that cost us days, so you do not have to hit it.

**Ad-hoc code signing changes the app's identity (its code hash) on every single build.**
macOS ties every TCC permission grant (Accessibility, Microphone, Speech, Screen
Recording) to that identity. So with ad-hoc signing, every rebuild looks like a brand new
app and macOS silently forgets every grant. Symptom: "I already granted this, why is it
asking again," and capture that never works.

`setup-signing.sh` creates **one stable self-signed certificate** used only to sign this
app locally. With a stable identity, the grants stick across rebuilds. Do this once and
forget it.

- The certificate and its private key are **one identity**. Do **not** delete either from
  Keychain Access, including anything that looks like a "duplicate" - removing the
  duplicate removes the whole identity and signing silently falls back to ad-hoc.
- To remove it cleanly later: `security delete-identity -c "Seihitsu Self-Signed"`.

---

## Hotkeys

| Shortcut | Action |
|---|---|
| `⌥Space` | Summon / hide the HUD |
| `⌥C` | Capture the current selection and act on it (answer a question, fix code) |
| `⌥L` | Listen (voice) - speak, it transcribes on-device and submits |
| `⌥⇧C` | Toggle click-through (let clicks pass under the HUD) |
| `Esc` | Dismiss the HUD |

There are matching menu-bar items and in-HUD **Capture** / **Listen** / **Copy** buttons
if you prefer clicking. The HUD is draggable and resizable, and stays where you put it.

---

## Features

- **Capture-excluded glass HUD** - `sharingType = .none`, verified absent from
  screenshots and screen shares. Glassmorphism via `NSVisualEffectView`.
- **Highlight-to-act** - `⌥C` grabs the current selection (Accessibility `kAXSelectedText`,
  falling back to a save/restore synthetic `⌘C`). A highlighted question is answered with
  no typing; highlighted code is fixed; anything else is attached as context.
- **Multi-model, one interface** - a single `ModelBackend` protocol behind everything:
  OpenRouter / OpenAI / Anthropic / Gemini / any OpenAI-compatible endpoint over HTTP+SSE,
  plus the Claude Code and Codex CLIs driven as subprocesses. Switch the active model from
  the menu bar.
- **Settings window** - paste API keys or a Claude `setup-token` straight into the
  Keychain; saving a key auto-enables that provider.
- **Voice input** - Apple on-device Speech (no audio leaves the machine).
- **Reveal-for-screenshot toggle** (debug) and a **capture self-test** that asserts the
  overlay is still excluded on your OS version.
- **File logging** at `~/Library/Logs/Seihitsu/seihitsu.log` (menu -> Reveal Logs).

---

## Troubleshooting

**Permissions keep re-prompting, or capture never works (`AX trusted=false` in the log).**
This is a stale TCC binding: the Accessibility entry is bound to an old code identity
(from earlier ad-hoc builds). Re-toggling the switch cannot fix a binding that points at a
dead identity. Reset it once:

```bash
tccutil reset Accessibility com.jarvis.seihitsu
```

Then, in System Settings -> Privacy & Security -> Accessibility, remove any leftover
"Seihitsu" row with the **-** button, relaunch the app, press `⌥C`, and grant fresh. With
the stable identity in place, the new grant binds permanently.

**"MAC verification failed" when importing the certificate.** Already handled by
`setup-signing.sh` (it packages the p12 with a non-empty password and 3DES/SHA1, the
combination macOS `security import` accepts). If you scripted your own, do the same.

**No answer appears.** You have not added a provider key yet, or the active provider has no
key. Open Settings (`⌘,`) and paste one; it auto-enables.

**Copy / paste does nothing inside the HUD.** Fixed in-app - an accessory app has no menu
bar, so a standard Edit menu is installed at launch to make `⌘C` / `⌘V` / `⌘A` work. If you
forked and removed it, that is why.

**Where are the logs?** `~/Library/Logs/Seihitsu/seihitsu.log`, or menu -> Reveal Logs. The
capture tier it took (AX selection, synthetic copy, or nothing) is logged on every `⌥C`.

---

## Project layout

```
app/
  Package.swift            SwiftPM executable target (Seihitsu)
  Scripts/
    setup-signing.sh       create the stable self-signed identity (run once)
    bundle.sh              build + assemble Seihitsu.app + install to ~/Applications
    fix-permissions.sh     one-shot: setup-signing + bundle + relaunch
  Resources/
    Info.plist             LSUIElement agent, bundle id com.jarvis.seihitsu, TCC usage strings
    AppIcon-source.png     replace with your own square PNG, rerun bundle.sh to re-icon
  Sources/Seihitsu/
    App/                   Bootstrap(@main), AppDelegate, MenuBar, Hotkeys, SelectionCapture,
                           SpeechListener, CaptureSelfTest, Log
    HUD/                   HUDPanel (.none), HUDController, HUDViewModel, HUDView (glass)
    Model/                 ModelBackend + adapters, ModelRouter, ProviderRegistry, Keychain,
                           SSEStream, ProcessEnv, HUDPrompts
    Settings/              SettingsController + SettingsView
docs/                      ARCHITECTURE.md, PROJECT-BRIEF.md, collab/
proof/capture-exclusion/   the standalone capture-exclusion proof
STATUS.md                  running session log and current state
```

Design and phasing detail: `docs/ARCHITECTURE.md`. Locked decisions and their reasoning:
`docs/collab/DECISIONS.md`.

---

## Scope

Personal tool. Not a commercial release: no accounts, billing, analytics, or hosted
collaboration. Capture-exclusion depends on the active macOS capture API and sharing path,
so treat "hidden" as verified-on-this-OS (the self-test checks it), not as an absolute
guarantee against every possible capture method.
