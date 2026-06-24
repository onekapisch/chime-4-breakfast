# TODO

## P1

- Validate Accessibility text extraction against live Codex and Claude windows
- Tune message scoring so the latest assistant response is chosen reliably
- Verify target bundle identifiers (`com.openai.codex`, `com.anthropic.claudefordesktop`) on real installs
- Add a small diagnostics capture mode for misclassified windows
- Debounce/coalesce Accessibility traversal so streaming responses do not over-trigger work on the main thread

## P2

- Per-app sound and glow overrides (different cues for Codex vs Claude)
- Optional macOS notification banners with click-to-focus the source app
- Quiet-hours option to also suppress the screen glow
- App icon and menu-bar template glyph
- Code signing + notarization, and a signed DMG release pipeline

## P3

- Explore Codex CLI and Claude Code support
- Add custom sound import
- Add adjustable attention phrase rules (user-authored / regex)
- Daily detection stats

## Done

- Full-screen edge glow with per-event colors and preview (Codex + Claude)
- Launch at login and Clear recent activity
- Whole-word classifier matching
- MIT license + CI workflow
