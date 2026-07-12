# TODO

## P1

- Live-validate the Stop-edge detector, fast-completion fallback, and away-state glow against current Codex and Claude Desktop builds
- Capture Codex diagnostics from long conversations and modal-window states to tune assistant-turn selection further

## P2

- Notification click-to-focus for the source app
- Run the signed/notarized v1.1.0 release after restoring the local notarytool Keychain profile

## P3

- Explore Codex CLI and Claude Code support
- Add import of user-licensed custom audio
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
- Per-event or per-app sound routing, including local system-spoken Codex and Claude cues
- Sound playback now uses retained full-volume AVAudioPlayer instances with playback-result logging
- Deterministic app-color glow preview and presentation-layer glow debug logging
- Stronger in-window edge-band glow renderer for reliable live visibility
- Perceptual glow intensity with a 20-100% range, live preview updates, and persisted low settings
- Fast-completion fallback for short replies that finish before polling observes the Stop edge
- Wake/idle guard that prevents stale transcript refreshes from triggering screen glow
- Official app icon in the popover header with refined liquid-glass panel highlights
- Optional macOS notification banners
- Quiet-hours sound-only mode with centralized delivery policy
- Session-only recent activity retention
- Launch at login and Clear recent activity
- Whole-word classifier matching
- MIT license + CI workflow
