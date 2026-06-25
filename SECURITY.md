# Security

## Permissions

Chime 4 Breakfast requires macOS Accessibility permission to read visible UI text from supported desktop apps. The app should request only the system permission needed to perform that task.

## Data Handling

- Captured message excerpts stay on-device
- Version 1 keeps only a short recent activity list for local display
- The app does not upload UI text, analytics, or conversation data

## Supported Targets

- Codex desktop: `com.openai.codex`
- Claude Desktop: `com.anthropic.claudefordesktop`

## Secrets

Version 1 does not require API keys or server credentials. `.env.local.example` exists only to satisfy repository hygiene rules and should stay empty unless a later feature needs configuration.

## Retention

Recent activity is local-only and compact. It is retained only to preserve the short session log shown in the popover.
