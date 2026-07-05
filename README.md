<div align="center">

<img src=".github/assets/hero.png" width="820" alt="Chime 4 Breakfast, a macOS menu bar utility" />

### No need to keep watching AI think.

Move on to another task, and **Chime 4 Breakfast** (C4B) notifies you the moment **Codex** or **Claude Desktop** needs you or finishes a reply. A sound, plus a screen-edge glow when you have stepped away. One cue for "done," a stronger one for "it needs you."

<p>
  <img src="https://img.shields.io/badge/macOS-14%2B-111111?logo=apple&logoColor=white" alt="macOS 14+" />
  <img src="https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white" alt="Swift 6" />
  <img src="https://img.shields.io/badge/License-MIT-3DA639" alt="MIT License" />
  <img src="https://img.shields.io/badge/tests-47%20passing-3fb950" alt="47 tests passing" />
  <img src="https://img.shields.io/badge/100%25%20local-no%20telemetry-8957E5" alt="100% local, no telemetry" />
  <img src="https://img.shields.io/badge/PRs-welcome-FF4D5E" alt="PRs welcome" />
</p>

<b><a href="#-get-started">Get started</a> · <a href="#-what-it-does">Features</a> · <a href="#-how-it-compares">Compare</a> · <a href="#-faq">FAQ</a> · <a href="CONTRIBUTING.md">Contributing</a></b>

</div>

---

You kick off a long task in Codex or Claude, switch to another window, and then keep checking back. Did it finish? Is it stuck waiting on a yes or no? **Chime 4 Breakfast** ends the babysitting. It watches for the assistant's Stop control to disappear, confirms the finish edge, plays your chosen sound, and lights your display edges if you had stepped away.

It is native, tiny, and lives in your menu bar. Everything happens on your Mac.

<div align="center">
<img src=".github/assets/popover.png" width="360" alt="The Chime 4 Breakfast menu bar popover" />
<br/>
<sub>One compact popover holds it all: apps, sounds, screen glow, rules, and a recent-activity log.</sub>
</div>

## ✨ Why

- **🔔 Never miss a finished response.** Step away without babysitting the chat window.
- **❗ "Done" vs "needs you" at a glance.** A calm cue for completions, a stronger one for questions and blockers.
- **🌗 Glanceable from across the room.** The screen-edge glow reads even when the window is behind something else.
- **🔒 Private by design.** Captured text never leaves the machine. No account, no cloud, no telemetry.

## 🎯 What it does

- **Watches Codex and Claude Desktop** through the macOS Accessibility layer and fires **once per finished response**.
- **Two distinct signals.** A soft cue when a reply simply completes, a bolder cue when it looks like it is asking you something.
- **Full-screen edge glow** in the source app's icon color. Completion fades quickly; attention gives a stronger brief pulse and then clears.
- **14 built-in sounds** with live preview, assignable per signal.
- **Optional notification banners** for a classic Notification Center ping.
- **Quiet hours, custom attention phrases, launch at login,** and a compact local activity log.

<div align="center">
<img src=".github/assets/glow-demo.png" width="760" alt="Screen-edge glow in source-app colors on every display" />
</div>

## 🌗 The signature: screen-edge glow

Sound is great until your speakers are muted or you are in another room. The glow is the part people keep. Chime uses the source app's icon color, so Claude and Codex feel distinct without extra setup. Completion gives a quick flash and fades; attention gives a stronger brief pulse without leaving a persistent overlay on screen.

## 🔊 Sounds

A curated set of 14, each previewable in one click:

`Tick` · `Beep` · `Horn` · `Wave` · `Coin` · `Glass` · `Ping` · `Chime` · `Pulse` · `Bloom` · `Spark` · `Knock` · `Drift` · `Flare`

Assign one to completions and another to attention, or turn sound off entirely and keep just the glow.

## 🧠 How detection works

Chime 4 Breakfast watches the supported apps through the Accessibility API and treats a response as finished when the generating/Stop control disappears. It confirms that edge on the next sample, then reads the latest assistant reply and classifies it:

- contains a question, or phrases like *"let me know", "which one", "approve", "confirm"* → **Attention**
- anything else → **Completion**

The rules are deterministic and unit-tested. No model, no network call. If a response is ever misread, the popover's **Capture Diagnostics** action writes a Desktop report containing the Accessibility text visible to Chime, including snippets of prompts or replies that were on screen. Nothing is uploaded unless you share that file.

## 🆚 How it compares

| | **Chime 4 Breakfast** | macOS notifications | Terminal bell | Just checking |
|---|:---:|:---:|:---:|:---:|
| Works with Codex and Claude **desktop apps** | ✅ | ❌ | ❌ | ➖ |
| Knows **done** vs **needs your input** | ✅ | ❌ | ❌ | 🙂 |
| **Screen-edge glow** (works muted / across the room) | ✅ | ❌ | ❌ | ❌ |
| **Per-event** sound plus app-color glow | ✅ | ❌ | ❌ | ➖ |
| Fires **once** per Stop edge | ✅ | ➖ | ➖ | ➖ |
| **100% local**, no account | ✅ | ✅ | ✅ | ✅ |

## 🚀 Get started

> Requires **macOS 14+**, **Xcode 16+**, and [XcodeGen](https://github.com/yonyz/XcodeGen) (`brew install xcodegen`).

```bash
git clone https://github.com/onekapisch/chime-4-breakfast.git
cd chime-4-breakfast
xcodegen generate
open Chime4Breakfast.xcodeproj   # then Run the Chime4BreakfastApp scheme
```

Or build and launch straight from the terminal:

```bash
./scripts/run-debug.sh
```

The debug launcher installs one canonical app at `~/Applications/Chime 4 Breakfast.app`. If an Apple Development signing identity is available, it signs that app before launch so macOS Accessibility permission survives rebuilds.

On first launch, grant **Accessibility** access when prompted (System Settings → Privacy & Security → Accessibility), keep Codex or Claude open on a conversation, and wait for a response to finish. You will hear the sound; if you switched away while it worked, you will also see the glow.

*(A signed, notarized DMG release is on the way. See [docs/RELEASE.md](docs/RELEASE.md).)*

## 🔒 Privacy & security

- Captured response text is used **only on-device** to classify and show a short recent-activity list.
- **Nothing is uploaded.** No analytics, no telemetry, no network calls.
- The only permission requested is **Accessibility**, required to read the visible reply text.
- Full details in [SECURITY.md](SECURITY.md).

## 🗺️ Roadmap

- Validate and tune detection against more live Codex and Claude layouts
- Per-app sound overrides
- Custom sound import
- Support for Claude Code, Codex CLI, and the web apps
- Signed DMG releases plus auto-update

Have an idea? [Open an issue](https://github.com/onekapisch/chime-4-breakfast/issues). The roadmap is demand-driven.

## 🤝 Contributing

PRs and ideas are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for setup, conventions, and how to attach detection diagnostics to a bug report.

## ❓ FAQ

**Is it really open source?** Yes. MIT licensed, source and all.

**Does it send my prompts or replies anywhere?** No. Everything runs locally; there are no servers and no telemetry.

**Why does it need Accessibility permission?** That is the macOS API that lets it read the visible reply text in another app. It is the whole mechanism.

**Does it work with Claude Code, Codex CLI, or the browser?** Not yet. It targets the Codex and Claude **desktop** apps today. The others are on the roadmap.

**Can I use my own sounds?** There are 14 built in for now; custom import is planned. You can also run sound-free and keep only the glow.

**Why is it not on the Mac App Store?** Reading another app's UI requires Accessibility, which is not allowed under the App Sandbox, so it ships as a notarized DMG or build-from-source instead.

---

<div align="center">

**⭐ If this saves you a few "is it done yet?" check-ins, give it a star. It genuinely helps other builders find it.**

Part of the **4 Breakfast** family, built for people who leave their AI running.

</div>
