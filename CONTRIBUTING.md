# Contributing to Chime 4 Breakfast

Thanks for your interest in improving Chime 4 Breakfast.

## Prerequisites

- macOS 14 or newer
- Xcode 16 or newer
- [XcodeGen](https://github.com/yonyz/XcodeGen) (`brew install xcodegen`)

## Getting started

```bash
xcodegen generate
open Chime4Breakfast.xcodeproj
```

The `.xcodeproj` is generated and intentionally not committed — always run
`xcodegen generate` after pulling changes that touch `project.yml` or add files.

## Before opening a pull request

Run the test suite and a build:

```bash
xcodebuild test -scheme Chime4BreakfastApp -destination 'platform=macOS'
xcodebuild -scheme Chime4BreakfastApp -destination 'platform=macOS' build
```

CI runs the same checks on every pull request.

## Conventions

- Keep response classification deterministic and unit-tested.
- Keep Accessibility integration isolated from pure logic so the core stays testable.
- Add tests first for classification, persistence, and timing behavior.
- Do not store conversation history beyond the compact recent-activity list.
- Match the existing code style (naming, spacing, comment density).

## Reporting detection problems

If Chime 4 Breakfast misses or misclassifies a response, open the popover,
choose **Capture detection diagnostics**, and review the generated Desktop file
before attaching it. It contains the raw Accessibility strings the watcher saw,
which can include visible prompt or reply text. No data leaves your machine
unless you choose to share that file.

## Regenerating the app icon

```bash
./scripts/generate-app-icon.sh
```
