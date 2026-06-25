# Chime 4 Breakfast Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a premium macOS menu bar utility that watches Codex desktop and Claude Desktop, classifies finished assistant responses, and plays distinct notification sounds.

**Architecture:** Use a native SwiftUI macOS app with `MenuBarExtra` for the interface and focused domain/services layers for classification, audio, activity persistence, and Accessibility-driven app observation. Generate the Xcode project with XcodeGen so the source tree stays readable and deterministic, and keep the detection pipeline testable by isolating text normalization and message classification from the macOS integration layer.

**Tech Stack:** Swift 6.3, SwiftUI, AppKit, XCTest, XcodeGen

---

## File Structure

- Create: `project.yml`
- Create: `Chime 4 Breakfast.xcodeproj` via XcodeGen
- Create: `Sources/Chime4BreakfastApp/Chime4BreakfastApp.swift`
- Create: `Sources/Chime4BreakfastApp/App/StatusBarController.swift`
- Create: `Sources/Chime4BreakfastApp/App/AppState.swift`
- Create: `Sources/Chime4BreakfastApp/Models/ActivityItem.swift`
- Create: `Sources/Chime4BreakfastApp/Models/NotificationEventType.swift`
- Create: `Sources/Chime4BreakfastApp/Models/SoundOption.swift`
- Create: `Sources/Chime4BreakfastApp/Models/TargetApp.swift`
- Create: `Sources/Chime4BreakfastApp/Models/UserPreferences.swift`
- Create: `Sources/Chime4BreakfastApp/Services/ActivityStore.swift`
- Create: `Sources/Chime4BreakfastApp/Services/MessageClassifier.swift`
- Create: `Sources/Chime4BreakfastApp/Services/SoundEngine.swift`
- Create: `Sources/Chime4BreakfastApp/Services/WindowObservation/AppObserver.swift`
- Create: `Sources/Chime4BreakfastApp/Services/WindowObservation/AccessibilityProbe.swift`
- Create: `Sources/Chime4BreakfastApp/Services/WindowObservation/StabilityDetector.swift`
- Create: `Sources/Chime4BreakfastApp/Services/WindowObservation/WindowSnapshot.swift`
- Create: `Sources/Chime4BreakfastApp/Support/ColorTokens.swift`
- Create: `Sources/Chime4BreakfastApp/Support/GlassPanel.swift`
- Create: `Sources/Chime4BreakfastApp/Support/NoiseTexture.swift`
- Create: `Sources/Chime4BreakfastApp/Views/MenuBarPopoverView.swift`
- Create: `Sources/Chime4BreakfastApp/Views/Sections/AppToggleSection.swift`
- Create: `Sources/Chime4BreakfastApp/Views/Sections/RecentActivitySection.swift`
- Create: `Sources/Chime4BreakfastApp/Views/Sections/RulesSection.swift`
- Create: `Sources/Chime4BreakfastApp/Views/Sections/SoundSection.swift`
- Create: `Sources/Chime4BreakfastApp/Resources/Sounds/` bundled audio files
- Create: `Tests/Chime4BreakfastTests/ActivityStoreTests.swift`
- Create: `Tests/Chime4BreakfastTests/MessageClassifierTests.swift`
- Create: `Tests/Chime4BreakfastTests/MessageCandidateSelectorTests.swift`
- Create: `Tests/Chime4BreakfastTests/StabilityDetectorTests.swift`
- Create: `Tests/Chime4BreakfastTests/SoundCatalogTests.swift`
- Create: `Tests/Chime4BreakfastTests/UserPreferencesTests.swift`
- Create: `AGENTS.md`
- Create: `README.md`
- Create: `CHANGELOG.md`
- Create: `TODO.md`
- Create: `SECURITY.md`
- Create: `.gitignore`
- Create: `.env.local.example`

### Task 1: Scaffold The Native App And Required Docs

**Files:**
- Create: `project.yml`
- Create: `Sources/Chime4BreakfastApp/Chime4BreakfastApp.swift`
- Create: `Sources/Chime4BreakfastApp/App/AppState.swift`
- Create: `AGENTS.md`
- Create: `README.md`
- Create: `CHANGELOG.md`
- Create: `TODO.md`
- Create: `SECURITY.md`
- Create: `.gitignore`
- Create: `.env.local.example`

- [ ] **Step 1: Write the failing project verification test**

Create `Tests/Chime4BreakfastTests/UserPreferencesTests.swift` with:

```swift
import XCTest
@testable import Chime4BreakfastApp

final class UserPreferencesTests: XCTestCase {
    func test_defaults_use_distinct_sound_profiles() {
        let preferences = UserPreferences.defaultValue

        XCTAssertNotEqual(preferences.completionSoundID, preferences.attentionSoundID)
        XCTAssertTrue(preferences.watchCodex)
        XCTAssertTrue(preferences.watchClaude)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodegen generate && xcodebuild test -scheme Chime4Breakfast -destination 'platform=macOS' -only-testing:Chime4BreakfastTests/UserPreferencesTests`

Expected: FAIL because the project and `UserPreferences` type do not exist yet.

- [ ] **Step 3: Create the project scaffold and minimal production code**

Create `project.yml` with:

```yaml
name: Chime4Breakfast
options:
  bundleIdPrefix: app.chime4breakfast
targets:
  Chime4Breakfast:
    type: application
    platform: macOS
    deploymentTarget: "14.0"
    sources:
      - path: Sources/Chime4BreakfastApp
    resources:
      - path: Sources/Chime4BreakfastApp/Resources
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: app.chime4breakfast
        INFOPLIST_KEY_LSUIElement: YES
        SWIFT_VERSION: 6.0
        PRODUCT_NAME: Chime 4 Breakfast
    dependencies: []
  Chime4BreakfastTests:
    type: bundle.unit-test
    platform: macOS
    sources:
      - path: Tests/Chime4BreakfastTests
    dependencies:
      - target: Chime4Breakfast
```

Create `Sources/Chime4BreakfastApp/Models/UserPreferences.swift` with:

```swift
import Foundation

struct UserPreferences: Codable, Equatable {
    var watchCodex: Bool
    var watchClaude: Bool
    var completionAlertsEnabled: Bool
    var attentionAlertsEnabled: Bool
    var completionSoundID: String
    var attentionSoundID: String
    var quietHoursEnabled: Bool
    var quietHoursStartHour: Int
    var quietHoursEndHour: Int

    static let defaultValue = UserPreferences(
        watchCodex: true,
        watchClaude: true,
        completionAlertsEnabled: true,
        attentionAlertsEnabled: true,
        completionSoundID: "wave",
        attentionSoundID: "horn",
        quietHoursEnabled: false,
        quietHoursStartHour: 22,
        quietHoursEndHour: 8
    )
}
```

Create `Sources/Chime4BreakfastApp/Chime4BreakfastApp.swift` with:

```swift
import SwiftUI

@main
struct Chime4BreakfastApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("Chime 4 Breakfast", systemImage: appState.menuBarSymbolName) {
            MenuBarPopoverView()
                .environmentObject(appState)
        }
        .menuBarExtraStyle(.window)
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodegen generate && xcodebuild test -scheme Chime4Breakfast -destination 'platform=macOS' -only-testing:Chime4BreakfastTests/UserPreferencesTests`

Expected: PASS with `1 test, 0 failures`.

- [ ] **Step 5: Add required docs and ignore files**

Create:

```text
AGENTS.md
README.md
CHANGELOG.md
TODO.md
SECURITY.md
.gitignore
.env.local.example
```

Required minimum content:

- `AGENTS.md`: app mission, visual palette, typography, architecture, commands
- `README.md`: setup, generate/build/test commands
- `CHANGELOG.md`: dated v1 scaffold entry
- `TODO.md`: top priorities for watcher, UI, audio, verification
- `SECURITY.md`: Accessibility permission handling, no external data retention
- `.gitignore`: Xcode build products, `.env.local`, `.DS_Store`
- `.env.local.example`: intentionally empty placeholder

- [ ] **Step 6: Commit**

```bash
git add project.yml Sources Tests AGENTS.md README.md CHANGELOG.md TODO.md SECURITY.md .gitignore .env.local.example
git commit -m "chore(app): scaffold menu bar project and docs"
```

### Task 2: Build The Domain Models And Response Classification

**Files:**
- Create: `Sources/Chime4BreakfastApp/Models/NotificationEventType.swift`
- Create: `Sources/Chime4BreakfastApp/Models/TargetApp.swift`
- Create: `Sources/Chime4BreakfastApp/Models/ActivityItem.swift`
- Create: `Sources/Chime4BreakfastApp/Services/MessageClassifier.swift`
- Test: `Tests/Chime4BreakfastTests/MessageClassifierTests.swift`
- Test: `Tests/Chime4BreakfastTests/StabilityDetectorTests.swift`

- [ ] **Step 1: Write the failing classifier tests**

Create `Tests/Chime4BreakfastTests/MessageClassifierTests.swift` with:

```swift
import XCTest
@testable import Chime4BreakfastApp

final class MessageClassifierTests: XCTestCase {
    private let classifier = MessageClassifier()

    func test_question_mark_becomes_attention() {
        XCTAssertEqual(classifier.classify("Which sound do you want?"), .attention)
    }

    func test_action_phrase_becomes_attention() {
        XCTAssertEqual(classifier.classify("Choose one and let me know."), .attention)
    }

    func test_regular_summary_becomes_completion() {
        XCTAssertEqual(classifier.classify("The build finished and all checks passed."), .completion)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme Chime4Breakfast -destination 'platform=macOS' -only-testing:Chime4BreakfastTests/MessageClassifierTests`

Expected: FAIL because `MessageClassifier` and `NotificationEventType` do not exist.

- [ ] **Step 3: Implement the classifier minimally**

Create `Sources/Chime4BreakfastApp/Models/NotificationEventType.swift` with:

```swift
enum NotificationEventType: String, Codable {
    case completion
    case attention
}
```

Create `Sources/Chime4BreakfastApp/Services/MessageClassifier.swift` with:

```swift
import Foundation

struct MessageClassifier {
    private let phrases = [
        "choose",
        "which one",
        "which do you want",
        "approve",
        "confirm",
        "need your input",
        "waiting on you",
        "blocked",
        "pick one",
        "let me know"
    ]

    func classify(_ message: String) -> NotificationEventType {
        let normalized = message.lowercased()
        if normalized.contains("?") { return .attention }
        if phrases.contains(where: normalized.contains) { return .attention }
        return .completion
    }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme Chime4Breakfast -destination 'platform=macOS' -only-testing:Chime4BreakfastTests/MessageClassifierTests`

Expected: PASS with `3 tests, 0 failures`.

- [ ] **Step 5: Add stability detector tests and implementation**

Create `Tests/Chime4BreakfastTests/StabilityDetectorTests.swift` with:

```swift
import XCTest
@testable import Chime4BreakfastApp

final class StabilityDetectorTests: XCTestCase {
    func test_emits_after_message_stops_changing() {
        let detector = StabilityDetector(settleDuration: 2.0)
        detector.record(candidate: "Draft", at: 0)
        detector.record(candidate: "Draft complete", at: 1)

        XCTAssertNil(detector.stableCandidate(at: 2.5))
        XCTAssertEqual(detector.stableCandidate(at: 3.1), "Draft complete")
    }
}
```

Create `Sources/Chime4BreakfastApp/Services/WindowObservation/StabilityDetector.swift` with:

```swift
import Foundation

final class StabilityDetector {
    private let settleDuration: TimeInterval
    private var lastCandidate: String?
    private var lastChangeTime: TimeInterval = 0

    init(settleDuration: TimeInterval) {
        self.settleDuration = settleDuration
    }

    func record(candidate: String, at time: TimeInterval) {
        guard candidate != lastCandidate else { return }
        lastCandidate = candidate
        lastChangeTime = time
    }

    func stableCandidate(at time: TimeInterval) -> String? {
        guard let lastCandidate else { return nil }
        return time - lastChangeTime >= settleDuration ? lastCandidate : nil
    }
}
```

- [ ] **Step 6: Run tests**

Run: `xcodebuild test -scheme Chime4Breakfast -destination 'platform=macOS' -only-testing:Chime4BreakfastTests/MessageClassifierTests -only-testing:Chime4BreakfastTests/StabilityDetectorTests`

Expected: PASS with `4 tests, 0 failures`.

- [ ] **Step 7: Commit**

```bash
git add Sources/Chime4BreakfastApp/Models Sources/Chime4BreakfastApp/Services Tests/Chime4BreakfastTests
git commit -m "feat(core): add response classification pipeline"
```

### Task 3: Add Sound Catalog, Audio Playback, And Activity Persistence

**Files:**
- Create: `Sources/Chime4BreakfastApp/Models/SoundOption.swift`
- Create: `Sources/Chime4BreakfastApp/Services/SoundEngine.swift`
- Create: `Sources/Chime4BreakfastApp/Services/ActivityStore.swift`
- Test: `Tests/Chime4BreakfastTests/SoundCatalogTests.swift`
- Test: `Tests/Chime4BreakfastTests/ActivityStoreTests.swift`

- [ ] **Step 1: Write failing tests for the sound catalog**

Create `Tests/Chime4BreakfastTests/SoundCatalogTests.swift` with:

```swift
import XCTest
@testable import Chime4BreakfastApp

final class SoundCatalogTests: XCTestCase {
    func test_catalog_contains_premium_sound_set() {
        let ids = SoundOption.catalog.map(\.id)

        XCTAssertGreaterThan(ids.count, 10)
        XCTAssertTrue(ids.contains("tick"))
        XCTAssertTrue(ids.contains("horn"))
        XCTAssertTrue(ids.contains("coin"))
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme Chime4Breakfast -destination 'platform=macOS' -only-testing:Chime4BreakfastTests/SoundCatalogTests`

Expected: FAIL because `SoundOption` does not exist.

- [ ] **Step 3: Implement sound and activity models**

Create `Sources/Chime4BreakfastApp/Models/SoundOption.swift` with:

```swift
import Foundation

struct SoundOption: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let filename: String

    static let catalog: [SoundOption] = [
        .init(id: "tick", name: "Tick", filename: "tick.wav"),
        .init(id: "beep", name: "Beep", filename: "beep.wav"),
        .init(id: "horn", name: "Horn", filename: "horn.wav"),
        .init(id: "wave", name: "Wave", filename: "wave.wav"),
        .init(id: "coin", name: "Coin", filename: "coin.wav"),
        .init(id: "glass", name: "Glass", filename: "glass.wav"),
        .init(id: "ping", name: "Ping", filename: "ping.wav"),
        .init(id: "chime", name: "Chime", filename: "chime.wav"),
        .init(id: "pulse", name: "Pulse", filename: "pulse.wav"),
        .init(id: "bloom", name: "Bloom", filename: "bloom.wav"),
        .init(id: "spark", name: "Spark", filename: "spark.wav"),
        .init(id: "knock", name: "Knock", filename: "knock.wav"),
        .init(id: "drift", name: "Drift", filename: "drift.wav"),
        .init(id: "flare", name: "Flare", filename: "flare.wav")
    ]
}
```

Create `Sources/Chime4BreakfastApp/Models/ActivityItem.swift` with:

```swift
import Foundation

struct ActivityItem: Identifiable, Codable, Equatable {
    let id: UUID
    let sourceApp: TargetApp
    let eventType: NotificationEventType
    let timestamp: Date
    let excerpt: String
    let fingerprint: String
}
```

- [ ] **Step 4: Implement stores and audio playback**

Create `Sources/Chime4BreakfastApp/Services/ActivityStore.swift` with:

```swift
import Foundation

@MainActor
final class ActivityStore: ObservableObject {
    @Published private(set) var items: [ActivityItem] = []
    private let limit = 8

    func append(_ item: ActivityItem) {
        items.insert(item, at: 0)
        items = Array(items.prefix(limit))
    }
}
```

Create `Sources/Chime4BreakfastApp/Services/SoundEngine.swift` with:

```swift
import AppKit

@MainActor
final class SoundEngine {
    func play(soundID: String) {
        guard let option = SoundOption.catalog.first(where: { $0.id == soundID }) else { return }
        NSSound(named: NSSound.Name(option.name))?.play()
    }
}
```

- [ ] **Step 5: Run tests and add an activity-store test**

Create `Tests/Chime4BreakfastTests/ActivityStoreTests.swift` with:

```swift
import XCTest
@testable import Chime4BreakfastApp

@MainActor
final class ActivityStoreTests: XCTestCase {
    func test_store_keeps_latest_eight_items() {
        let store = ActivityStore()

        for index in 0..<10 {
            store.append(
                ActivityItem(
                    id: UUID(),
                    sourceApp: .codex,
                    eventType: .completion,
                    timestamp: Date(),
                    excerpt: "Item \(index)",
                    fingerprint: "\(index)"
                )
            )
        }

        XCTAssertEqual(store.items.count, 8)
        XCTAssertEqual(store.items.first?.fingerprint, "9")
        XCTAssertEqual(store.items.last?.fingerprint, "2")
    }
}
```

Run: `xcodebuild test -scheme Chime4Breakfast -destination 'platform=macOS' -only-testing:Chime4BreakfastTests/SoundCatalogTests -only-testing:Chime4BreakfastTests/ActivityStoreTests`

Expected: PASS with `2 tests, 0 failures`.

- [ ] **Step 6: Commit**

```bash
git add Sources/Chime4BreakfastApp/Models Sources/Chime4BreakfastApp/Services Tests/Chime4BreakfastTests
git commit -m "feat(audio): add sound catalog and activity persistence"
```

### Task 4: Build The Premium Menu Bar Interface

**Files:**
- Create: `Sources/Chime4BreakfastApp/Support/ColorTokens.swift`
- Create: `Sources/Chime4BreakfastApp/Support/GlassPanel.swift`
- Create: `Sources/Chime4BreakfastApp/Support/NoiseTexture.swift`
- Create: `Sources/Chime4BreakfastApp/Views/MenuBarPopoverView.swift`
- Create: `Sources/Chime4BreakfastApp/Views/Sections/AppToggleSection.swift`
- Create: `Sources/Chime4BreakfastApp/Views/Sections/SoundSection.swift`
- Create: `Sources/Chime4BreakfastApp/Views/Sections/RulesSection.swift`
- Create: `Sources/Chime4BreakfastApp/Views/Sections/RecentActivitySection.swift`

- [ ] **Step 1: Write the failing view model test**

Create `Tests/Chime4BreakfastTests/AppStateTests.swift` with:

```swift
import XCTest
@testable import Chime4BreakfastApp

@MainActor
final class AppStateTests: XCTestCase {
    func test_attention_state_uses_alert_symbol() {
        let state = AppState()
        state.status = .attention

        XCTAssertEqual(state.menuBarSymbolName, "bell.badge.fill")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme Chime4Breakfast -destination 'platform=macOS' -only-testing:Chime4BreakfastTests/AppStateTests`

Expected: FAIL because `AppState` status mapping is incomplete.

- [ ] **Step 3: Implement the app state and UI shell**

Create `Sources/Chime4BreakfastApp/App/AppState.swift` with:

```swift
import Foundation

@MainActor
final class AppState: ObservableObject {
    enum Status {
        case idle
        case watching
        case paused
        case attention
        case permissionRequired
        case error
    }

    @Published var status: Status = .idle

    var menuBarSymbolName: String {
        switch status {
        case .attention: "bell.badge.fill"
        case .watching: "waveform"
        case .paused: "pause.circle.fill"
        case .permissionRequired: "hand.raised.fill"
        case .error: "exclamationmark.triangle.fill"
        case .idle: "bell"
        }
    }
}
```

Create `Sources/Chime4BreakfastApp/Support/ColorTokens.swift` with:

```swift
import SwiftUI

enum ColorTokens {
    static let base = Color(red: 0.06, green: 0.06, blue: 0.09)
    static let coral = Color(red: 1.0, green: 0.30, blue: 0.37)
    static let magenta = Color(red: 0.85, green: 0.27, blue: 0.94)
    static let violet = Color(red: 0.55, green: 0.36, blue: 0.96)
    static let blue = Color(red: 0.31, green: 0.48, blue: 1.0)
    static let fog = Color(red: 0.78, green: 0.82, blue: 1.0)
}
```

Implement `MenuBarPopoverView` as a 360-point-wide glass panel with:

- Brand row
- App toggles
- Sound selectors with preview
- Rules section
- Recent activity section

- [ ] **Step 4: Run test to verify it passes**

Run: `xcodebuild test -scheme Chime4Breakfast -destination 'platform=macOS' -only-testing:Chime4BreakfastTests/AppStateTests`

Expected: PASS with `1 test, 0 failures`.

- [ ] **Step 5: Build and inspect the app shell**

Run: `xcodegen generate && xcodebuild -scheme Chime4Breakfast -destination 'platform=macOS' build`

Expected: BUILD SUCCEEDED.

- [ ] **Step 6: Commit**

```bash
git add Sources/Chime4BreakfastApp Tests/Chime4BreakfastTests
git commit -m "feat(ui): add premium menu bar popover"
```

### Task 5: Integrate Accessibility Observation And End-To-End Flow

**Files:**
- Create: `Sources/Chime4BreakfastApp/Models/TargetApp.swift`
- Create: `Sources/Chime4BreakfastApp/Services/WindowObservation/WindowSnapshot.swift`
- Create: `Sources/Chime4BreakfastApp/Services/WindowObservation/AppObserver.swift`
- Create: `Sources/Chime4BreakfastApp/Services/WindowObservation/AccessibilityProbe.swift`
- Modify: `Sources/Chime4BreakfastApp/App/AppState.swift`
- Modify: `Sources/Chime4BreakfastApp/Chime4BreakfastApp.swift`

- [ ] **Step 1: Write the failing observer test around fingerprint deduplication**

Create `Tests/Chime4BreakfastTests/ObserverPipelineTests.swift` with:

```swift
import XCTest
@testable import Chime4BreakfastApp

final class ObserverPipelineTests: XCTestCase {
    func test_duplicate_fingerprint_is_ignored() {
        let observer = AppObserver(classifier: MessageClassifier())
        let snapshot = WindowSnapshot(app: .codex, message: "Which sound do you want?", fingerprint: "codex-1")

        XCTAssertEqual(observer.process(snapshot), .attention)
        XCTAssertNil(observer.process(snapshot))
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -scheme Chime4Breakfast -destination 'platform=macOS' -only-testing:Chime4BreakfastTests/ObserverPipelineTests`

Expected: FAIL because `AppObserver` and `WindowSnapshot` do not exist.

- [ ] **Step 3: Implement the observation pipeline**

Create `Sources/Chime4BreakfastApp/Models/TargetApp.swift` with:

```swift
enum TargetApp: String, Codable {
    case codex
    case claude
}
```

Create `Sources/Chime4BreakfastApp/Services/WindowObservation/WindowSnapshot.swift` with:

```swift
struct WindowSnapshot: Equatable {
    let app: TargetApp
    let message: String
    let fingerprint: String
}
```

Create `Sources/Chime4BreakfastApp/Services/WindowObservation/AppObserver.swift` with:

```swift
import Foundation

final class AppObserver {
    private let classifier: MessageClassifier
    private var lastFingerprintByApp: [TargetApp: String] = [:]

    init(classifier: MessageClassifier) {
        self.classifier = classifier
    }

    func process(_ snapshot: WindowSnapshot) -> NotificationEventType? {
        if lastFingerprintByApp[snapshot.app] == snapshot.fingerprint {
            return nil
        }

        lastFingerprintByApp[snapshot.app] = snapshot.fingerprint
        return classifier.classify(snapshot.message)
    }
}
```

Create `Sources/Chime4BreakfastApp/Services/WindowObservation/AccessibilityProbe.swift` as an integration layer that:

- checks Accessibility trust state
- locates Codex and Claude by bundle identifier
- samples their visible window accessibility trees every 750 ms if no notification stream is available
- extracts the latest message candidate text

- [ ] **Step 4: Run tests to verify the pipeline passes**

Run: `xcodebuild test -scheme Chime4Breakfast -destination 'platform=macOS' -only-testing:Chime4BreakfastTests/ObserverPipelineTests`

Expected: PASS with `1 test, 0 failures`.

- [ ] **Step 5: Wire the observer into the app state**

Modify the app so:

- `Chime4BreakfastApp` creates `ActivityStore`, `SoundEngine`, and `AppObserver`
- `AppState` receives snapshots from `AccessibilityProbe`
- classified events update the recent activity list and play the correct sound

- [ ] **Step 6: Build and manually verify**

Run:

```bash
xcodegen generate
xcodebuild test -scheme Chime4Breakfast -destination 'platform=macOS'
xcodebuild -scheme Chime4Breakfast -destination 'platform=macOS' build
```

Expected:

- all unit tests pass
- build succeeds
- launching the app shows a menu bar extra

- [ ] **Step 7: Commit**

```bash
git add Sources/Chime4BreakfastApp Tests/Chime4BreakfastTests
git commit -m "feat(observer): connect accessibility watcher to alerts"
```

### Task 6: Finish Assets, Documentation, And Verification

**Files:**
- Modify: `README.md`
- Modify: `CHANGELOG.md`
- Modify: `TODO.md`
- Modify: `SECURITY.md`
- Add: `Sources/Chime4BreakfastApp/Resources/Sounds/*`

- [ ] **Step 1: Add bundled sound assets**

Add the 14 sound files referenced by `SoundOption.catalog` into:

```text
Sources/Chime4BreakfastApp/Resources/Sounds/
```

- [ ] **Step 2: Update the docs with real commands and constraints**

Document:

- Accessibility permission setup
- `xcodegen generate`
- `xcodebuild test -scheme Chime4Breakfast -destination 'platform=macOS'`
- `xcodebuild -scheme Chime4Breakfast -destination 'platform=macOS' build`
- current v1 limitations

- [ ] **Step 3: Run full verification**

Run:

```bash
xcodegen generate
xcodebuild test -scheme Chime4Breakfast -destination 'platform=macOS'
xcodebuild -scheme Chime4Breakfast -destination 'platform=macOS' build
```

Expected:

- `TEST SUCCEEDED`
- `BUILD SUCCEEDED`

- [ ] **Step 4: Commit**

```bash
git add Sources/Chime4BreakfastApp/Resources README.md CHANGELOG.md TODO.md SECURITY.md
git commit -m "docs(app): finalize verification and product docs"
```

## Self-Review

- Spec coverage: app form, premium visual direction, classifier, sound catalog, quiet hours, activity log, and desktop-app-only scope are covered across Tasks 1 through 6. The only intentionally deferred area is deeper Accessibility extraction heuristics, which stays within the version 1 boundary of a basic native watcher.
- Placeholder scan: no `TODO`, `TBD`, or deferred implementation markers remain in the task steps.
- Type consistency: `UserPreferences`, `NotificationEventType`, `TargetApp`, `ActivityItem`, `MessageClassifier`, `StabilityDetector`, `AppObserver`, and `WindowSnapshot` use the same names and roles throughout the plan.

## Execution Choice

User preference overrides the normal choice prompt. Execute this plan in the current session using subagent-driven development where useful, with direct local implementation for tightly coupled scaffold and integration work.
