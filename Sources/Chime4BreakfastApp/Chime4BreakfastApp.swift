import SwiftUI

@main
struct Chime4BreakfastApp: App {
    @StateObject private var appState: AppState

    init() {
        let state = AppState()
        _appState = StateObject(wrappedValue: state)
        state.startMonitoringIfNeeded()
    }

    var body: some Scene {
        MenuBarExtra("Chime 4 Breakfast", systemImage: appState.menuBarSymbolName) {
            MenuBarPopoverView()
                .environmentObject(appState)
        }
        .menuBarExtraStyle(.window)
    }
}
