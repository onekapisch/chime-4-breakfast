# Horn OK Please Agent Guide

## Product

Horn OK Please is a native macOS menu bar utility. It watches Codex desktop and Claude Desktop through the macOS Accessibility APIs, classifies finished assistant responses, and plays distinct sounds for normal completion versus attention-needed moments.

## Stack

- Swift 6
- SwiftUI for the menu bar UI
- AppKit and ApplicationServices for macOS integration
- XCTest for deterministic unit tests
- XcodeGen for project generation

## Architecture

- `Sources/HornOKPleaseApp/App`: app lifecycle and shared state
- `Sources/HornOKPleaseApp/Models`: small data types and enums
- `Sources/HornOKPleaseApp/Services`: classification, audio, persistence
- `Sources/HornOKPleaseApp/Services/WindowObservation`: Accessibility polling and window analysis
- `Sources/HornOKPleaseApp/Support`: palette, glass surfaces, texture helpers
- `Sources/HornOKPleaseApp/Views`: popover and section views
- `Tests/HornOKPleaseTests`: unit tests for deterministic behavior

## Visual Direction

- Dark lacquered glass, not flat dark mode
- Wallpaper-inspired accents: coral red, magenta, violet, electric blue
- Tight spacing, sharp typography, low-noise motion
- Popover target width: 360 pt

## Sound Catalog

The built-in sound set includes:

- Tick
- Beep
- Horn
- Wave
- Coin
- Glass
- Ping
- Chime
- Pulse
- Bloom
- Spark
- Knock
- Drift
- Flare

## Commands

Generate the Xcode project:

```bash
xcodegen generate
```

Run tests:

```bash
xcodebuild test -scheme HornOKPleaseApp -destination 'platform=macOS'
```

Build the app:

```bash
xcodebuild -scheme HornOKPleaseApp -destination 'platform=macOS' build
```

## Conventions

- Keep response classification deterministic in version 1
- Keep Accessibility code isolated from pure logic
- Add tests first for classification, persistence, and timing behavior
- Do not store conversation history beyond the compact recent activity list
