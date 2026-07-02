import AppKit
import SwiftUI

struct MenuBarPopoverView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack {
            backgroundArtwork
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
                .animation(.smooth(duration: 0.26), value: appState.status)
                .animation(.smooth(duration: 0.26), value: appState.runningApps)
            }
            .scrollIndicators(.hidden)
        }
        .frame(width: 360, height: 620)
        .preferredColorScheme(.dark)
        .onAppear {
            appState.acknowledgeAttention()
        }
    }

    private var backgroundArtwork: some View {
        ZStack {
            LinearGradient(
                colors: [
                    ColorTokens.baseElevated,
                    ColorTokens.base,
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [ColorTokens.electricBlue.opacity(0.24), .clear],
                center: UnitPoint(x: 0.12, y: 0.08),
                startRadius: 12,
                endRadius: 280
            )

            RadialGradient(
                colors: [ColorTokens.coral.opacity(0.16), .clear],
                center: UnitPoint(x: 0.92, y: 0.18),
                startRadius: 24,
                endRadius: 300
            )

            LinearGradient(
                colors: [.clear, Color.black.opacity(0.24)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .ignoresSafeArea()
    }

    private var header: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    appIcon

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Chime 4 Breakfast")
                            .font(.system(size: 23, weight: .semibold, design: .serif))
                            .foregroundStyle(.white)
                        Text(appState.statusTitle)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(statusTint)
                        Text(appState.statusDetail)
                            .font(.system(size: 11))
                            .foregroundStyle(ColorTokens.fog.opacity(0.72))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)
                }

                HStack(spacing: 8) {
                    statusChip

                    if !appState.runningApps.isEmpty {
                        Text(activeAppsSummary)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(ColorTokens.fog.opacity(0.78))
                            .lineLimit(1)
                    }

                    Spacer(minLength: 0)
                }
            }
        }
    }

    private var appIcon: some View {
        Image(nsImage: NSApp.applicationIconImage)
            .resizable()
            .interpolation(.high)
            .frame(width: 48, height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(alignment: .bottomTrailing) {
                ZStack {
                    Circle()
                        .fill(ColorTokens.base.opacity(0.96))
                        .frame(width: 21, height: 21)
                    Image(systemName: appState.menuBarSymbolName)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(statusTint)
                }
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
                )
                .offset(x: 4, y: 4)
            }
            .shadow(color: statusTint.opacity(0.24), radius: 16, x: 0, y: 10)
    }

    private var statusChip: some View {
        Label {
            Text(statusChipTitle)
        } icon: {
            Circle()
                .fill(statusTint)
                .frame(width: 7, height: 7)
        }
        .font(.system(size: 11, weight: .semibold))
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(statusChipBackground, in: Capsule())
        .overlay(
            Capsule()
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
        )
    }

    private var utilityRow: some View {
        HStack(spacing: 10) {
            Button {
                if appState.status == .paused {
                    appState.resumeWatching()
                } else {
                    appState.pauseWatching()
                }
            } label: {
                Label(
                    appState.status == .paused ? "Resume" : "Pause",
                    systemImage: appState.status == .paused ? "play.fill" : "pause.fill"
                )
                .font(.system(size: 12, weight: .semibold))
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.white.opacity(0.14))

            Spacer()

            if appState.status == .permissionRequired {
                Button {
                    appState.openAccessibilitySettings()
                } label: {
                    Label("Accessibility", systemImage: "switch.2")
                        .font(.system(size: 12, weight: .semibold))
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
            appState.runningApps.isEmpty ? "Waiting" : "Watching"
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
            AnyShapeStyle(ColorTokens.coral.opacity(0.22))
        case .watching:
            AnyShapeStyle(ColorTokens.electricBlue.opacity(0.18))
        case .permissionRequired, .error:
            AnyShapeStyle(ColorTokens.magenta.opacity(0.18))
        case .paused:
            AnyShapeStyle(Color.white.opacity(0.07))
        case .idle:
            AnyShapeStyle(Color.white.opacity(0.07))
        }
    }

    private var statusTint: Color {
        switch appState.status {
        case .attention:
            ColorTokens.coral
        case .watching:
            appState.runningApps.isEmpty ? ColorTokens.fog : ColorTokens.electricBlue
        case .permissionRequired, .error:
            ColorTokens.magenta
        case .paused:
            ColorTokens.textMuted
        case .idle:
            ColorTokens.fog
        }
    }

    private var activeAppsSummary: String {
        let names = appState.runningApps.map(\.displayName).sorted()
        switch names.count {
        case 0:
            return ""
        case 1:
            return "\(names[0]) is open"
        default:
            return "\(names.joined(separator: " + ")) are open"
        }
    }
}
