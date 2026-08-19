# Seihitsu Shirei

**静謐司令, "quiet command."** A private AI helper for your Mac that floats on screen,
answers what you highlight or point it at, and stays out of screenshots and screen shares.

You highlight a question anywhere and it answers in a little floating panel. You point it
at part of your screen and it reads the text and answers that. You can talk to it. And the
panel does not show up when you take a screenshot or share your screen, so only you see it.

This page gets you from nothing to a working app in about ten minutes, even if you have
never opened Terminal before. Follow it top to bottom.

---

## What it can do

- **Answer a question you highlight.** Select some text in any app, press a key, get an answer. No copy and paste.
- **Read part of your screen and answer it.** Useful when an app will not let you select or copy text. You choose the exact area it is allowed to look at.
- **Listen.** Speak a question, it types it out and answers.
- **Stay invisible to capture.** The panel is left out of screenshots and screen shares.
- **Answer fast when you are on the clock.** A speed switch (Full / Brief / Blitz) makes it reply with just the answer for timed questions.

---

## What you need

- A **Mac running macOS 14 (Sonoma) or newer**.
- About **ten minutes**.
- A free **AI key** from OpenRouter. We get it in step 5.
- Willingness to **paste three lines into Terminal**. We walk you through each one.

You do not need to know how to code.

---

## Install it (about ten minutes)

**Open Terminal first.** Press **Cmd and Space** together, type **Terminal**, press
**Return**. A plain window opens where you type. For each step below, click the command,
paste it in, press **Return**, and wait for it to finish before the next one.

### Step 1: Install Apple's developer tools

This is a one time thing that lets your Mac build the app.

```bash
xcode-select --install
```

A small window appears. Click **Install** and agree to the terms. It takes a few minutes.
If it says the tools are already installed, that is fine, move on.

### Step 2: Download Seihitsu

```bash
git clone https://github.com/silas-maven/seihitsu-shirei.git ~/seihitsu-shirei
```

This puts the project in a folder called `seihitsu-shirei` in your home folder.

> The project is private. If Terminal asks you to sign in, use the GitHub account that was
> given access. If instead someone handed you the project as a folder, skip this step and,
> in step 3, use the path to that folder in place of `~/seihitsu-shirei`.

### Step 3: Build and install it

```bash
~/seihitsu-shirei/app/Scripts/fix-permissions.sh
```

This one command does everything: it sets up a stable signature (the thing that stops
macOS from asking for permissions over and over), builds the app, installs it into your
Applications, and opens it. If a box asks for your Mac password or to allow a keychain
item, approve it, that is just macOS checking it is really you.

When it finishes you will see a small **brain icon in the menu bar** at the very top of
your screen. That is Seihitsu, running. 

---

## First run: allow it once

The first time you use each feature, macOS asks for permission. Because the app now has a
stable signature (step 3 handled that), **you allow each one once and it stays allowed.**

A note on the keys: **⌥ is the Option key** (it may be labelled **Alt**), and **⇧ is
Shift**. So "⌥C" means hold Option and press C.

- **To answer highlighted text**, press **⌥C**. The first time, macOS asks for
  **Accessibility**. Click **Open System Settings**, find **Seihitsu** in the list, and
  turn its switch **on**.
- **To read your screen**, press **⌥V**. The first time, macOS asks for **Screen
  Recording** (on newer macOS it may be called **Screen & System Audio Recording**). Turn
  **Seihitsu** on. If screen reading does not work right after this, **quit Seihitsu**
  (brain icon, Quit) and open it again, this one permission sometimes needs a restart.
- **To talk to it**, press **⌥L**. macOS asks for **Microphone** and **Speech
  Recognition**. Allow both.
- If a box ever asks about **"Seihitsu.apikeys"**, click **Always Allow**. That is just
  the app reading the AI key you save in the next step.

You only see each of these once.

---

## Step 5: Add your AI key (so it can actually answer)

1. Go to **openrouter.ai**, sign in, and create an **API key** (free to start). Copy it.
2. Click the **brain icon** in the menu bar, then **Settings**.
3. Paste your key into the **OpenRouter** box and click **Save**.

That is enough to start getting answers. If you prefer OpenAI, Anthropic, or Gemini, there
are boxes for those in the same Settings window; paste a key and pick it from the **Model**
menu.

---

## How to use it

Everything is a quick key combo. **⌥ is Option, ⇧ is Shift.**

| Press | What happens |
|---|---|
| **⌥Space** | Show or hide the floating panel |
| **⌥C** | Answer the text you have highlighted (or fix highlighted code) |
| **⌥V** | Read the screen area you chose, and answer the question in it |
| **⌥L** | Listen: speak, and it answers |
| **⌥⇧S** | Switch answer length: Full, Brief, Blitz |
| **Esc** | Hide the panel |

**Choosing what part of the screen it reads.** Click the brain icon, then **Set screen
region**, and drag a box over the spot where questions appear (press Esc to cancel). From
then on, **⌥V** reads exactly that area. **Clear screen region** goes back to the whole
screen.

**Answer speed, for timed questions.** Use the **Full / Brief / Blitz** switch in the
panel, the **Speed** menu, or press **⌥⇧S** to cycle:
- **Full**: a normal, complete answer.
- **Brief**: a line or two.
- **Blitz**: just the answer, nothing else. For a multiple choice question it gives only
  the option, so you can read and pick before the timer runs out.

**Staying hidden.** The panel does not appear in screenshots or screen shares. (There is a
"Reveal HUD in Screenshots" item in the menu if you ever want it visible for a photo.)

---

## Your privacy

- The screenshots taken by **⌥V** are read on your Mac, by Apple's built in text
  recognition. **The image is never saved and never sent anywhere.** Only the text it reads
  is passed to the AI you chose.
- Nothing else leaves your Mac except the text of the questions you send to your AI
  provider, exactly as if you had typed them into that provider yourself.
- Your AI key is kept in the Mac Keychain, not in a plain file.

---

## If something is not right

**It keeps asking for permission, or ⌥C does not pick up highlighted text.** This happens
if the app was rebuilt under different signatures in the past and macOS is confused about
its identity. Fix it once: quit Seihitsu, then paste this single line into Terminal:

```bash
tccutil reset Accessibility com.jarvis.seihitsu
```

Then in System Settings, Privacy & Security, Accessibility, remove any leftover "Seihitsu"
row with the minus button, open the app again, press ⌥C, and allow it. It will stick this
time. (A fresh install almost never needs this.)

**Screen reading does nothing.** Make sure **Screen Recording** is turned on for Seihitsu
in System Settings, then **quit and reopen** the app once.

**No answer appears.** You have not added an AI key yet (step 5), or the box was left
empty. Open Settings and paste one.

**Do not delete the certificate.** In the Keychain there is an item called **"Seihitsu
Self-Signed"**. Leave it alone. Deleting it brings back the endless permission prompts,
because it is what gives the app its stable identity.

---

## Update it later

To get the newest version:

```bash
cd ~/seihitsu-shirei && git pull && app/Scripts/bundle.sh
```

Then quit and reopen Seihitsu. Your permissions and key are kept.

## Uninstall

- Quit it from the brain icon.
- Open your **Applications** folder and drag **Seihitsu** to the Trash.
- Optional, remove its signature: `security delete-identity -c "Seihitsu Self-Signed"`
- Optional, delete the `~/seihitsu-shirei` folder.

---

## For developers

Build only (no signing changes): `app/Scripts/bundle.sh`. Create the stable self-signed
identity on its own: `app/Scripts/setup-signing.sh`. Ad-hoc signing changes the code hash
on every build, so macOS forgets every TCC grant; the self-signed identity gives a stable,
cert-based designated requirement so grants persist.

```
app/
  Package.swift            SwiftPM executable target (Seihitsu)
  Scripts/                 setup-signing.sh, bundle.sh, fix-permissions.sh
  Resources/               Info.plist (bundle id com.jarvis.seihitsu), AppIcon-source.png
  Sources/Seihitsu/
    App/                   Bootstrap(@main), AppDelegate, MenuBar, Hotkeys, SelectionCapture,
                           ScreenReader (OCR), RegionPicker, ScreenRegionStore, SpeechListener, Log
    HUD/                   HUDPanel (.none), HUDController, HUDViewModel, HUDView (glass)
    Model/                 ModelBackend + adapters, ModelRouter, ProviderRegistry, HUDPrompts
                           (incl. AnswerMode: Full/Brief/Blitz), Keychain, SSEStream
    Settings/              SettingsController + SettingsView
docs/                      ARCHITECTURE.md, PROJECT-BRIEF.md, collab/
proof/capture-exclusion/   the standalone capture-exclusion proof
STATUS.md                  running session log and current state
```

Screen reading is on-device Apple Vision OCR (`ScreenReader.swift`), fed into the same
`ModelBackend` path as everything else. Capture-exclusion (`sharingType = .none`) is
verified against screenshots and ScreenCaptureKit; see `docs/ARCHITECTURE.md`.

---

## Name

**Seihitsu Shirei**, 静謐司令, "quiet command."
