# Chime 4 Breakfast Design

Date: 2026-04-03
Status: Draft approved for review

## Summary

Chime 4 Breakfast is a premium macOS menu bar utility that watches Codex desktop and Claude Desktop, detects when a new assistant response has finished, classifies that response, and plays a sound. It uses one sound for normal completion and a stronger sound for messages that likely need user attention.

Version 1 focuses on desktop app coverage only. CLI, API, and web support are future phases.

## Product Goals

- Let the user walk away from Codex or Claude without missing a finished response.
- Make question-like or blocker-like responses feel distinct from normal completions.
- Keep the app lightweight, native, and fast enough to live permanently in the menu bar.
- Deliver a premium visual style that feels closer to a boutique macOS utility than a generic settings pane.

## Non-Goals

- Support Codex CLI, Claude Code, or Claude Web in version 1.
- Build an in-app plugin for Codex or Claude.
- Store full conversation history.
- Add custom rule builders in version 1.

## Primary User Flows

### First Run

1. User launches Chime 4 Breakfast.
2. App requests Accessibility permission.
3. User chooses whether to watch Codex, Claude Desktop, or both.
4. User picks a completion sound and an attention sound.
5. App enters `watching` state and begins passive monitoring.

### Normal Completion

1. Codex or Claude streams a response.
2. Chime 4 Breakfast waits for the latest assistant message to stabilize.
3. The message is classified as `completion`.
4. The app plays the selected completion sound.
5. The event is added to the recent activity list.

### Attention Needed

1. Codex or Claude streams a response.
2. Chime 4 Breakfast waits for the latest assistant message to stabilize.
3. The message is classified as `attention`.
4. The app plays the selected attention sound.
5. The menu bar icon shifts to an alert state until the user opens the popover or 90 seconds pass, whichever comes first.

## Functional Requirements

### App Coverage

- Support Codex desktop app on macOS.
- Support Claude Desktop on macOS.
- Allow the user to enable or disable each app independently.

### Detection Rules

- Detect the latest assistant-visible message from the accessibility tree.
- Debounce streaming output and fire only when the latest message is stable.
- Deduplicate alerts by fingerprinting the final message body per app.
- Emit one event per new assistant response.

### Classification Rules

Each new assistant response is classified as either `completion` or `attention`.

`attention` takes precedence over `completion` when one or more of these conditions match:

- The message contains a question mark.
- The message contains action phrases such as `choose`, `which one`, `which do you want`, `approve`, `confirm`, `need your input`, `waiting on you`, `blocked`, `pick one`, or `let me know`.
- The message is short, imperative, and clearly asks for a decision.

All other new assistant responses are classified as `completion`.

### Sound System

- Provide more than 10 built-in sounds.
- Let the user assign one sound to `completion`.
- Let the user assign one sound to `attention`.
- Provide a preview button for every sound selector.
- Keep the sound set curated and short enough to scan quickly.

Initial bundled sound library:

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

### Popover Features

The menu bar popover includes:

- Brand row with app name and live status chip
- Per-app toggles for Codex and Claude
- Completion sound selector and preview
- Attention sound selector and preview
- Rule toggles for completion alerts and attention alerts
- Quiet hours toggle with start and end time
- Recent activity log with the latest 8 detections
- Pause watching action

### Recent Activity

Each log item shows:

- Source app
- Event type
- Time
- Short excerpt of the detected message

The log is local-only and short-lived. Version 1 keeps the latest 8 items and persists them only for session continuity on relaunch.

## UX and Visual Design

### Product Form

Chime 4 Breakfast is a menu bar utility first. The primary interface is a compact popover panel. It should feel polished enough to use daily without ever becoming visually loud.

### Visual Direction

The UI draws from the supplied wallpaper:

- Near-black base
- Hot coral-red highlight
- Electric magenta bloom
- Violet-blue edge light
- Cool silver haze

The interface should read as dark lacquered glass with controlled neon light leaks, not cyberpunk noise and not a flat dark dashboard.

### Surface Treatment

- Smoked glass background with strong blur
- Soft internal highlight along the top edge
- Fine grain or noise overlay to avoid flat gradients
- Thin luminous borders
- Deep shadow under the popover for separation

Suggested surface tokens:

- Background: `rgba(10, 10, 14, 0.72)`
- Stroke: `rgba(255, 255, 255, 0.08)`
- Highlight: `rgba(255, 255, 255, 0.10)`
- Shadow: `rgba(0, 0, 0, 0.42)`

Suggested accent tokens:

- Coral: `#FF4D5E`
- Magenta: `#D946EF`
- Violet: `#8B5CF6`
- Blue: `#4F7BFF`
- Fog: `#C8D2FF`

### Typography

- Display face for the app wordmark only
- Clean sans-serif for labels, controls, and body text
- Monospace for timestamps, diagnostics, and event metadata

Typography should be restrained. The premium feel comes from spacing, contrast, and material finish, not oversized type.

Recommended macOS font stack:

- Wordmark: New York
- UI text: SF Pro
- Metadata: SF Mono

### Motion

- Hover lift of 1 to 2 points on interactive rows
- Accent bloom on focused controls
- Soft pulse for `watching` status
- More urgent flare for `attention` state
- No looping decorative animations

### Layout

Popover structure from top to bottom:

1. Brand and status
2. Apps
3. Sounds
4. Rules
5. Recent activity
6. Utility actions

The panel should be narrow and dense, but not cramped. Controls should feel grouped, not stacked arbitrarily.
Target popover width: 360 points.

## Technical Architecture

### Platform

- Native macOS app
- SwiftUI for the menu bar popover and settings surfaces
- AppKit where menu bar or accessibility integration needs lower-level control

### Main Components

#### StatusBarController

- Owns the menu bar item
- Updates the icon and status state
- Opens and closes the popover

#### AppObserver

- Tracks whether Codex and Claude Desktop are running
- Tracks relevant windows
- Starts or stops probes for enabled apps

#### AccessibilityProbe

- Reads the accessibility tree for the frontmost or visible app window
- Extracts candidate assistant message text
- Normalizes text before classification
- Uses accessibility change notifications when available and falls back to a 750 ms polling loop when they are not

#### StabilityDetector

- Samples the latest message over time
- Marks a response as complete only after the text stops changing for a fixed settle window
- Default settle window: 2.0 seconds

#### MessageClassifier

- Applies deterministic rules for `completion` vs `attention`
- Produces a confidence score for internal diagnostics, but not a user-facing score in version 1

#### SoundEngine

- Loads bundled sounds
- Plays preview sounds and live alert sounds
- Prevents duplicate overlapping playback from rapid duplicate events

#### ActivityStore

- Stores recent detections locally
- Exposes the latest entries to the popover

#### PreferencesStore

- Persists app toggles, sound choices, quiet hours, and alert toggles
- Uses local storage only

## Detection Pipeline

1. Detect that Codex or Claude Desktop is running and enabled.
2. Subscribe to accessibility changes for the relevant conversation window and fall back to 750 ms polling when notifications are unavailable.
3. Extract the latest assistant-visible message candidate.
4. Normalize whitespace and remove transient duplicates.
5. Wait until the candidate remains unchanged for 2.0 seconds.
6. Generate a fingerprint from app identifier plus normalized final message.
7. Skip if the fingerprint matches the last emitted event for that app.
8. Classify the message.
9. Check quiet hours and enabled rule toggles.
10. Play the assigned sound and write the activity item.

## States

Global app states:

- `idle`: app launched but not watching
- `watching`: at least one target app is active and monitoring is enabled
- `paused`: monitoring disabled by user
- `attention`: a recent attention event is active
- `permission-required`: Accessibility permission missing
- `error`: watcher failed and needs recovery

The menu bar icon and status chip should reflect these states clearly.

## Permissions and Error Handling

### Accessibility

- The app requires macOS Accessibility permission.
- If permission is missing, the popover must explain why, show the current status, and offer a button to open System Settings.

### App Detection Failures

- If Codex or Claude cannot be read reliably, show that app as unavailable rather than failing the full watcher.
- Record a local diagnostic message for the recent activity section or a hidden diagnostics sheet.

### Sound Failures

- If a sound asset fails to load, fall back to a safe built-in sound and surface a small error state in the UI.

## Data Model

### Preferences

- `watchCodex: Bool`
- `watchClaude: Bool`
- `completionAlertsEnabled: Bool`
- `attentionAlertsEnabled: Bool`
- `completionSoundID: String`
- `attentionSoundID: String`
- `quietHoursEnabled: Bool`
- `quietHoursStart: Time`
- `quietHoursEnd: Time`

### Activity Item

- `id`
- `sourceApp`
- `eventType`
- `timestamp`
- `excerpt`
- `fingerprint`

## Implementation Boundaries for Version 1

- Desktop apps only
- Built-in sounds only
- Deterministic text rules only
- Local storage only
- Menu bar UI only

Not included in version 1:

- Browser support
- CLI wrappers
- Cloud sync
- Custom imported sounds
- User-authored phrase rules

## Testing and Validation

### Functional Checks

- Verify Codex completion messages trigger the completion sound once.
- Verify Codex question-like messages trigger the attention sound once.
- Verify Claude completion messages trigger the completion sound once.
- Verify Claude question-like messages trigger the attention sound once.
- Verify repeated polling does not replay the same event.
- Verify quiet hours suppress sound while still logging activity if enabled.

### UX Checks

- Verify the popover feels stable and legible on light and dark desktop wallpapers.
- Verify the activity list remains readable in a compact height.
- Verify hover, press, and status transitions feel smooth and restrained.

### Failure Checks

- Verify missing Accessibility permission shows the recovery UI.
- Verify disabled target apps do not generate noise or errors.
- Verify sound fallback works when a selected asset is unavailable.

## Future Phases

Phase 2 can extend the same product into:

- Codex CLI
- Claude Code
- Claude Web
- API wrappers
- Custom sound import
- Rule tuning and diagnostics

The core model remains the same: detect response completion, classify response intent, and notify with distinct sounds.

## Shipping Recommendation

Build version 1 as a native SwiftUI menu bar app with AppKit integration where needed. Optimize for fast startup, low idle resource use, and an exact visual finish. The product should feel like a premium utility, not a developer demo.
