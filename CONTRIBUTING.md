# Contributing to Horn OK Please

Thanks for your interest in improving Horn OK Please.

## Prerequisites

- macOS 14 or newer
- Xcode 16 or newer
- [XcodeGen](https://github.com/yonyz/XcodeGen) (`brew install xcodegen`)

## Getting started

```bash
xcodegen generate
open HornOKPlease.xcodeproj
```

The `.xcodeproj` is generated and intentionally not committed — always run
`xcodegen generate` after pulling changes that touch `project.yml` or add files.

## Before opening a pull request

Run the test suite and a build:

```bash
xcodebuild test -scheme HornOKPleaseApp -destination 'platform=macOS'
xcodebuild -scheme HornOKPleaseApp -destination 'platform=macOS' build
```

CI runs the same checks on every pull request.

## Conventions

- Keep response classification deterministic and unit-tested.
- Keep Accessibility integration isolated from pure logic so the core stays testable.
- Add tests first for classification, persistence, and timing behavior.
- Do not store conversation history beyond the compact recent-activity list.
- Match the existing code style (naming, spacing, comment density).

## Reporting detection problems

If Horn OK Please misses or misclassifies a response, open the popover,
choose **Capture detection diagnostics**, and attach the generated file (it is
written to your Desktop). It contains the raw Accessibility strings the watcher
saw — no data leaves your machine unless you choose to share that file.

## Regenerating the app icon

```bash
./scripts/generate-app-icon.sh
```
