# Horn OK Please

Horn OK Please is a native macOS menu bar utility for Codex desktop and Claude Desktop. It listens for finished assistant responses through the Accessibility layer and plays one sound for normal completions and another for messages that likely need your attention.

## Requirements

- macOS 14 or newer
- Xcode 26.4 or newer
- XcodeGen

## Setup

1. Generate the project:

```bash
xcodegen generate
```

2. Open the generated project or build from the terminal:

```bash
open HornOKPlease.xcodeproj
```

3. Grant Accessibility access to Horn OK Please when prompted.

## Development Commands

Run tests:

```bash
xcodebuild test -scheme HornOKPleaseApp -destination 'platform=macOS'
```

Build the app:

```bash
xcodebuild -scheme HornOKPleaseApp -destination 'platform=macOS' build
```

Build and launch the menu bar app:

```bash
./scripts/run-debug.sh
```

## Current Scope

Version 1 targets:

- Codex desktop: `com.openai.codex`
- Claude Desktop: `com.anthropic.claudefordesktop`

Version 1 does not include:

- Codex CLI
- Claude Code
- Claude Web
- Custom sound imports

## Accessibility

Horn OK Please requires Accessibility permission to inspect UI text in supported desktop apps. The app does not transmit captured text anywhere. Recent activity remains local to the machine.

## Built App Location

When built from the terminal, the debug app bundle is generated inside Xcode DerivedData. The launch helper prints the exact path after opening the app.
