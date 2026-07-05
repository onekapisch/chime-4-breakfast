# Changelog

## 2026-07-05

- Prepared the project for public GitHub launch by cleaning repository hygiene, CI, documentation, diagnostics privacy copy, notification handling, dead support code, and developer tooling portability

## 2026-07-02 (UI redesign)

- Redesigned the popover in a native macOS grouped-settings style: compact header with a single status chip, flat section cards with outside labels, hairline dividers, and small controls
- Removed the redundant watcher-status card (status now lives in the header chip; permission/pause/error states appear as a contextual banner only when action is needed)
- Moved Pause, diagnostics, and Open-at-login into a slim footer; custom attention phrases now sit behind a disclosure
- Added a snapshot harness that renders the real popover to an image so visual changes are reviewed, not guessed

## 2026-07-02 (night)

- Found via live logs that glows WERE firing but at half brightness for half a second — invisible from another window: stale stored intensity values below 0.7 now migrate to full brightness, the fade-in is near-instant so the ~1 s dwell is fully visible, and edge bands got brighter
- Scans are now wall-clock bounded (2.5 s full / 1.5 s cheap) with per-element AX timeouts, so a beachballing target app can no longer stall detection
- Each app scans independently — a busy Codex can never delay Claude's finish detection (and vice versa)

## 2026-07-02 (evening)

- Fixed missed alerts on rapid consecutive short replies: a confirmed Stop edge now always fires (identical-message dedup no longer swallows real completions like "hi" → "how are you"), with a 3-second debounce absorbing indicator flicker
- Change detection now fingerprints the transcript tail instead of one selected message, so fast completions are recognized even when the selector picks the same candidate twice
- Glow now lasts about one second (completion flash 1.0 s, attention pulse 1.5 s with a quicker pulse), per feedback

## 2026-07-02 (later)

- Unified alert gating: quiet hours and the per-event toggle now mute sound, glow, and banners together, and "away" alone decides sound-only versus sound + glow — no more mismatched combinations that looked random
- Every Recent entry now records what the app did and why (e.g. "Sound + glow", "Sound — you were in the app", "Muted — quiet hours") so any unexpected outcome is self-explaining
- The glow intensity slider is now honest: the hidden 0.9 floor is gone and the slider range matches what is actually rendered
- Notification banners only appear when you are away from the source app

## 2026-07-02

- Fixed the biggest source of missed alerts: the poll timer now runs in the common run-loop mode (it used to stall while menus or the popover were open) and the app opts out of App Nap while monitoring, so background throttling can no longer delay or drop the finish edge
- The finish edge now self-schedules its confirmation pass instead of waiting for the next timer tick, so a completed response is confirmed within ~250 ms even when the conversation goes quiet
- Bounded every Accessibility call with a 1-second messaging timeout and added a stall watchdog, so a busy or hung Codex/Claude can no longer freeze detection silently
- Detector state now only resets on true system sleep/wake — ordinary display wake no longer drops in-flight responses
- Attention glow now pulses briefly and always auto-dismisses; no glow ever lingers on screen

## 2026-06-26

- Replaced the old settle-based completion path with a Stop-edge detector that confirms the finish edge, preserves away-from-app state, and suppresses duplicate replies
- Routed completion and attention glows separately: completions flash briefly, attention pulses until acknowledged or timed out
- Changed screen glow color to the source app icon color and removed stale per-event glow color preferences
- Reduced AX traversal cost by scanning cheaply for generating state first and only collecting full text on finish/confirm samples
- Added scan-session guards so stale detached AX reads cannot emit events after monitoring restarts
- Improved latest-message selection to prefer labeled assistant turns over longer user prompts
- Added diagnostics output for current generating state and gated debug logging behind `CHIME_DEBUG_LOG=1`
- Fixed sound preview/playback loading so selected built-in WAV files resolve from the app bundle instead of falling back to the system beep
- Replaced sound playback with a retained `AVAudioPlayer`, full-volume preparation, and explicit playback success logging
- Made screen-glow preview deterministic by preferring Codex when both watched apps are running, and clarified that glow color is app-derived while event type controls flash versus pulse
- Increased completion glow visibility and added debug logs for glow presentation, window creation, and dismissal
- Rebuilt the glow renderer with in-window edge bands so the flash is not clipped or too subtle when shown over another app
- Added a fast-completion fallback that baselines stable messages and emits an away completion when a response finishes before polling sees the Stop edge
- Disarmed stale away-state fast fallback after idle samples and reset detection on sleep/wake so opening the laptop cannot trigger old transcript glows
- Polished the menu bar popover with clearer watcher health, app icons, app-color glow copy, event accents, and a cleaner recent-activity list
- Updated the popover header to use the official app icon with a live status badge and refined the shared glass panel highlights
- Added tests for finish-edge behavior, glow gating, assistant selection, AX generating labels, and stale in-flight reset
- Updated the debug launcher to install and open the single canonical app at `~/Applications/Chime 4 Breakfast.app`
- Debug builds now re-sign that canonical app with the local Apple Development identity when available, preventing Accessibility permission churn between rebuilds

## 2026-06-24

- Added full-screen edge glow: the display border lights up in a calm color on completion and a stronger color for attention-needed responses, for both Codex and Claude
- Glow covers every connected display, auto-fades for completions, and pulses for attention until acknowledged
- Added a Screen Glow settings section with an enable toggle, per-event color pickers, an intensity slider, and live preview
- Added optional macOS notification banners alongside the audible and visual cues
- Added a custom attention-phrase rule editor so responses can be flagged on your own keywords
- Added Launch at login (via `SMAppService`), Clear recent activity, and a Capture detection diagnostics action for reporting misdetections
- Coalesced Accessibility change notifications so streaming responses no longer trigger repeated tree walks
- Hardened response classification with whole-word phrase matching to avoid false positives like "approved" or "unblocked"
- Status now reads "Waiting" when watching is on but no target app is open
- Made saved preferences forward-compatible so new settings no longer reset existing choices
- Added a generated app icon, MIT license, GitHub Actions CI, CONTRIBUTING guide, issue/PR templates
- Added a release pipeline (`scripts/build-release.sh` + `docs/RELEASE.md`) that builds a DMG with optional signing and notarization

## 2026-04-03

- Initialized the Chime 4 Breakfast macOS menu bar project
- Added the design spec and implementation plan
- Added the native SwiftUI scaffold, watcher pipeline, and required project docs
- Added first-run Accessibility prompting, readiness guidance, and live startup status coverage
- Hardened the observer pipeline so monitoring starts at launch, repeated identical replies can alert again, and AX message selection is more targeted
- Added a one-command debug launcher for building and opening the menu bar app
