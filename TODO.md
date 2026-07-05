# TODO

## P1

- Live-validate the Stop-edge detector, fast-completion fallback, and away-state glow against current Codex and Claude Desktop builds
- Capture Codex diagnostics from long conversations and modal-window states to tune assistant-turn selection further

## P2

- Per-app sound overrides (different cues for Codex vs Claude)
- Notification click-to-focus for the source app
- Optional quiet-hours mode that suppresses sound only while still allowing visual glow
- Signed/notarized DMG release dry run with real Developer ID credentials

## P3

- Explore Codex CLI and Claude Code support
- Add custom sound import
- Add adjustable attention phrase rules (user-authored / regex)
- Daily detection stats

## Done

- Stop-edge finish detector with confirm sampling, duplicate suppression, and away-state memory
- Full-screen app-color edge glow with completion flash, brief attention pulse, and preview
- Assistant-turn message selection for labeled Codex/Claude transcript text
- Reduced AX work by avoiding full text extraction while responses are still streaming
- Diagnostics capture for raw AX text, selected message, classification, and generating state
- Polished menu bar popover with app icons, watcher health, event accents, and compact recent activity
- Stable local debug signing through `scripts/run-debug.sh` so Accessibility permission survives rebuilds
- Built-in sound previews now load the selected app-bundled WAV instead of falling back to the system beep
- Sound playback now uses retained full-volume AVAudioPlayer instances with playback-result logging
- Deterministic app-color glow preview and presentation-layer glow debug logging
- Stronger in-window edge-band glow renderer for reliable live visibility
- Fast-completion fallback for short replies that finish before polling observes the Stop edge
- Wake/idle guard that prevents stale transcript refreshes from triggering screen glow
- Official app icon in the popover header with refined liquid-glass panel highlights
- Optional macOS notification banners
- Launch at login and Clear recent activity
- Whole-word classifier matching
- MIT license + CI workflow
