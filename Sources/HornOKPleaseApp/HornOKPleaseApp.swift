import SwiftUI

@main
struct HornOKPleaseApp: App {
    @StateObject private var appState: AppState

    init() {
        let state = AppState()
        _appState = StateObject(wrappedValue: state)
        state.startMonitoringIfNeeded()
    }

    var body: some Scene {
        MenuBarExtra("Horn OK Please", systemImage: appState.menuBarSymbolName) {
            MenuBarPopoverView()
                .environmentObject(appState)
        }
        .menuBarExtraStyle(.window)
    }
}
