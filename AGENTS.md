# Chime 4 Breakfast Agent Guide

## Product

Chime 4 Breakfast is a native macOS menu bar utility. It watches Codex desktop and Claude Desktop through the macOS Accessibility APIs, classifies finished assistant responses, and plays distinct sounds for normal completion versus attention-needed moments.

## Stack

- Swift 6
- SwiftUI for the menu bar UI
- AppKit and ApplicationServices for macOS integration
- XCTest for deterministic unit tests
- XcodeGen for project generation

## Architecture

- `Sources/Chime4BreakfastApp/App`: app lifecycle and shared state
- `Sources/Chime4BreakfastApp/Models`: small data types and enums
- `Sources/Chime4BreakfastApp/Services`: classification, audio, persistence
- `Sources/Chime4BreakfastApp/Services/WindowObservation`: Accessibility polling and window analysis
- `Sources/Chime4BreakfastApp/Support`: palette, glass surfaces, texture helpers
- `Sources/Chime4BreakfastApp/Views`: popover and section views
- `Tests/Chime4BreakfastTests`: unit tests for deterministic behavior

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
xcodebuild test -scheme Chime4BreakfastApp -destination 'platform=macOS'
```

Build the app:

```bash
xcodebuild -scheme Chime4BreakfastApp -destination 'platform=macOS' build
```

## Conventions

- Keep response classification deterministic in version 1
- Keep Accessibility code isolated from pure logic
- Add tests first for classification, persistence, and timing behavior
- Do not store conversation history beyond the compact recent activity list
