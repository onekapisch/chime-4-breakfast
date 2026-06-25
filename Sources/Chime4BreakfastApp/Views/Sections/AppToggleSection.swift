import SwiftUI

struct AppToggleSection: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("Apps")

                ForEach(TargetApp.allCases) { targetApp in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(appState.runningApps.contains(targetApp) ? ColorTokens.blue : Color.white.opacity(0.18))
                            .frame(width: 10, height: 10)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(targetApp.displayName)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                            Text(targetApp.bundleIdentifier)
                                .font(.system(size: 11, weight: .regular, design: .monospaced))
                                .foregroundStyle(ColorTokens.fog.opacity(0.58))
                                .lineLimit(1)
                        }

                        Spacer()

                        Toggle("", isOn: Binding(
                            get: { appState.preferences.isWatching(targetApp) },
                            set: { appState.toggleWatching(targetApp, enabled: $0) }
                        ))
                        .toggleStyle(.switch)
                    }
                }
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .bold))
            .textCase(.uppercase)
            .foregroundStyle(ColorTokens.fog.opacity(0.72))
    }
}
