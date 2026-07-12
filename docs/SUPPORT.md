# Supported Setup

## Supported today

| Surface | Status | Notes |
| --- | --- | --- |
| macOS | Supported | macOS 14 or later, Apple Silicon and Intel |
| Codex Desktop | Supported | Native conversation windows with visible generating and Stop controls |
| Claude Desktop | Supported | Native conversation windows with visible generating and Stop controls |
| Completion and attention alerts | Supported | Completion flashes; likely questions or blockers use the attention cue |
| Multiple displays | Supported | The app-color edge cue appears on every connected display |

## Not supported yet

- Codex CLI
- Claude Code
- Browser-based Codex, Claude, or ChatGPT
- Other desktop AI apps

## What detection depends on

Chime reads the visible Accessibility hierarchy of the supported desktop app. It waits for a generating or Stop control to disappear, confirms that edge, then classifies the latest visible assistant response. Provider UI changes, non-conversation windows, or modal overlays can affect detection.

Before relying on a new layout, use the header setup test to confirm your sound and glow settings. If a real response is missed or misclassified, capture diagnostics from the popover and follow [Troubleshooting](TROUBLESHOOTING.md).
