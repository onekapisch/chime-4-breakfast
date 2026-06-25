# Changelog

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
