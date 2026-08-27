import SwiftUI

@main
struct Chime4BreakfastApp: App {
    @StateObject private var appState: AppState
    // macOS can restore a menu-bar item's visibility as hidden. Keeping this
    // state app-owned prevents that stale scene state from terminating Chime.
    @State private var isMenuBarExtraInserted = true

    init() {
        let state = AppState()
        _appState = StateObject(wrappedValue: state)
        state.startMonitoringIfNeeded()
    }

    var body: some Scene {
        MenuBarExtra(
            "Chime 4 Breakfast",
            systemImage: appState.menuBarSymbolName,
            isInserted: $isMenuBarExtraInserted
        ) {
            MenuBarPopoverView()
                .environmentObject(appState)
        }
        .menuBarExtraStyle(.window)
    }
}
