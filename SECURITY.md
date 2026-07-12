# Security

## Permissions

Chime 4 Breakfast requires macOS Accessibility permission to read visible UI text from supported desktop apps. The app should request only the system permission needed to perform that task.

## Data Handling

- Captured message excerpts stay on-device
- The recent activity list is session-only: it is cleared on launch and never written to persistent storage
- The Capture Diagnostics action is explicit and user-triggered. It writes a Desktop text file containing the AX text visible to the watcher, selected candidate, classification, and generating state for debugging misdetections.
- Debug logging is disabled by default. Setting `CHIME_DEBUG_LOG=1` writes event metadata to `/tmp/chime4breakfast.log`; it should not include message excerpts.
- The app does not upload UI text, analytics, or conversation data
- The optional spoken "Codex" and "Claude" cues use local macOS speech synthesis. They do not send text off-device, embed third-party recordings, or emulate a public figure's voice.
- A setup test produces only a local sample completion alert. It does not read a target-app window or transmit data.

## Supported Targets

- Codex desktop: `com.openai.codex`
- Claude Desktop: `com.anthropic.claudefordesktop`

## Secrets

Version 1 does not require API keys or server credentials. `.env.local.example` exists only to satisfy repository hygiene rules and should stay empty unless a later feature needs configuration.

## Retention

Recent activity is local-only, capped at eight entries, and retained only for the current app session.

Diagnostics reports are retained wherever the user saves them and should be deleted manually when no longer needed.
