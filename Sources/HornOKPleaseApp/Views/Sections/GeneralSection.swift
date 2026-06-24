import SwiftUI

struct GeneralSection: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("General")

                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Launch at login")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                        Text("Start Horn OK Please automatically after you sign in")
                            .font(.system(size: 11))
                            .foregroundStyle(ColorTokens.fog.opacity(0.58))
                    }

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { appState.launchAtLoginEnabled },
                        set: { appState.setLaunchAtLogin($0) }
                    ))
                    .labelsHidden()
                }

                Button {
                    appState.captureDiagnostics()
                } label: {
                    Label("Capture detection diagnostics", systemImage: "stethoscope")
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.borderless)
                .foregroundStyle(ColorTokens.fog.opacity(0.82))

                if !appState.recentActivity.isEmpty {
                    Button {
                        appState.clearRecentActivity()
                    } label: {
                        Label("Clear recent activity", systemImage: "trash")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(ColorTokens.fog.opacity(0.82))
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
