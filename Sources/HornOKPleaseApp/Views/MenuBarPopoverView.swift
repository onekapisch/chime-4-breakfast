import SwiftUI

struct MenuBarPopoverView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    ColorTokens.base,
                    ColorTokens.baseElevated
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [ColorTokens.coral.opacity(0.32), .clear],
                center: .topLeading,
                startRadius: 10,
                endRadius: 220
            )

            RadialGradient(
                colors: [ColorTokens.magenta.opacity(0.38), .clear],
                center: .topTrailing,
                startRadius: 10,
                endRadius: 220
            )

            RadialGradient(
                colors: [ColorTokens.blue.opacity(0.34), .clear],
                center: .bottomLeading,
                startRadius: 30,
                endRadius: 240
            )

            NoiseTexture()

            ScrollView {
                VStack(spacing: 12) {
                    header
                    ReadinessSection()
                    AppToggleSection()
                    SoundSection()
                    GlowSection()
                    RulesSection()
                    RecentActivitySection()
                    GeneralSection()
                    utilityRow
                }
                .padding(12)
            }
        }
        .frame(width: 360)
        .preferredColorScheme(.dark)
        .onAppear {
            appState.acknowledgeAttention()
        }
    }

    private var header: some View {
        GlassPanel {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Horn OK Please")
                        .font(.system(size: 24, weight: .semibold, design: .serif))
                        .foregroundStyle(.white)
                    Text(appState.statusTitle)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(ColorTokens.fog.opacity(0.8))
                }

                Spacer()

                Label {
                    Text(statusChipTitle)
                } icon: {
                    Image(systemName: appState.menuBarSymbolName)
                }
                .font(.system(size: 11, weight: .semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(statusChipBackground, in: Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                )
            }
        }
    }

    private var utilityRow: some View {
        HStack(spacing: 10) {
            Button(appState.status == .paused ? "Resume Watching" : "Pause Watching") {
                if appState.status == .paused {
                    appState.resumeWatching()
                } else {
                    appState.pauseWatching()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(ColorTokens.magenta.opacity(0.8))

            Spacer()

            if appState.status == .permissionRequired {
                Button("Open Accessibility") {
                    appState.openAccessibilitySettings()
                }
                .buttonStyle(.borderless)
                .foregroundStyle(ColorTokens.fog)
            }
        }
        .padding(.top, 2)
    }

    private var statusChipTitle: String {
        switch appState.status {
        case .idle:
            "Idle"
        case .watching:
            appState.runningApps.isEmpty ? "Waiting" : "Live"
        case .paused:
            "Paused"
        case .attention:
            "Alert"
        case .permissionRequired:
            "Permission"
        case .error:
            "Error"
        }
    }

    private var statusChipBackground: AnyShapeStyle {
        switch appState.status {
        case .attention:
            AnyShapeStyle(ColorTokens.coral.opacity(0.20))
        case .watching:
            AnyShapeStyle(ColorTokens.blue.opacity(0.18))
        case .permissionRequired, .error:
            AnyShapeStyle(Color.orange.opacity(0.18))
        case .paused:
            AnyShapeStyle(Color.white.opacity(0.08))
        case .idle:
            AnyShapeStyle(Color.white.opacity(0.08))
        }
    }
}
