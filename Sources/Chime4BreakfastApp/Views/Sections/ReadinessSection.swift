import SwiftUI

struct ReadinessSection: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 10) {
                    Image(systemName: symbolName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(symbolColor)
                        .frame(width: 30, height: 30)
                        .background(symbolColor.opacity(0.14), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Watcher")
                            .font(.system(size: 11, weight: .bold))
                            .textCase(.uppercase)
                            .foregroundStyle(ColorTokens.fog.opacity(0.72))

                        Text(appState.statusTitle)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }

                Text(appState.statusDetail)
                    .font(.system(size: 12))
                    .foregroundStyle(ColorTokens.fog.opacity(0.84))
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 8) {
                    statusRow(title: "Accessibility", value: accessibilityValue, color: accessibilityColor)
                    statusRow(title: "Targets", value: targetsValue, color: targetsColor)
                    statusRow(title: "Trigger", value: triggerValue, color: symbolColor)
                }
            }
        }
    }

    private var symbolName: String {
        switch appState.status {
        case .permissionRequired:
            "hand.raised.fill"
        case .attention:
            "bell.badge.fill"
        case .paused:
            "pause.circle.fill"
        case .error:
            "exclamationmark.triangle.fill"
        case .idle, .watching:
            "sparkle.magnifyingglass"
        }
    }

    private var symbolColor: Color {
        switch appState.status {
        case .permissionRequired:
            ColorTokens.accent
        case .attention:
            ColorTokens.accent
        case .paused:
            ColorTokens.fog
        case .error:
            ColorTokens.accent
        case .idle, .watching:
            ColorTokens.accentSoft
        }
    }

    private var accessibilityValue: String {
        appState.status == .permissionRequired ? "Required" : "Granted"
    }

    private var accessibilityColor: Color {
        appState.status == .permissionRequired ? ColorTokens.magenta : ColorTokens.success
    }

    private var targetsValue: String {
        let names = appState.runningApps.map(\.displayName).sorted()
        guard !names.isEmpty else { return "Waiting" }
        return names.joined(separator: " + ")
    }

    private var targetsColor: Color {
        appState.runningApps.isEmpty ? ColorTokens.textMuted : ColorTokens.electricBlue
    }

    private var triggerValue: String {
        switch appState.status {
        case .permissionRequired:
            return "Blocked"
        case .paused:
            return "Paused"
        case .idle, .watching, .attention, .error:
            return appState.runningApps.isEmpty ? "Standby" : "Armed"
        }
    }

    private func statusRow(title: String, value: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)

            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(ColorTokens.fog.opacity(0.72))

            Spacer()

            Text(value)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
