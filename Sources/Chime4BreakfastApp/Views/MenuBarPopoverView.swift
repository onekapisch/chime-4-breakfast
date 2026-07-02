import AppKit
import SwiftUI

struct MenuBarPopoverView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [ColorTokens.baseElevated, ColorTokens.base],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                    .padding(.bottom, 10)

                Rectangle()
                    .fill(Color.white.opacity(0.06))
                    .frame(height: 1)

                ScrollView {
                    VStack(spacing: 14) {
                        StatusBanner()
                        AppToggleSection()
                        SoundSection()
                        GlowSection()
                        RulesSection()
                        RecentActivitySection()
                    }
                    .padding(12)
                    .animation(.smooth(duration: 0.26), value: appState.status)
                    .animation(.smooth(duration: 0.26), value: appState.runningApps)
                }
                .scrollIndicators(.hidden)

                Rectangle()
                    .fill(Color.white.opacity(0.06))
                    .frame(height: 1)

                footer
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
            }
        }
        .frame(width: 360, height: 600)
        .preferredColorScheme(.dark)
        .onAppear {
            appState.acknowledgeAttention()
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 9) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .interpolation(.high)
                .frame(width: 26, height: 26)
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))

            Text("Chime 4 Breakfast")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)

            Spacer(minLength: 8)

            statusChip
        }
    }

    private var statusChip: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(statusTint)
                .frame(width: 6, height: 6)
            Text(statusChipTitle)
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4.5)
        .background(Color.white.opacity(0.07), in: Capsule())
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
    }

    // MARK: Footer

    private var footer: some View {
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
                .font(.system(size: 11, weight: .medium))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            Button {
                appState.captureDiagnostics()
            } label: {
                Image(systemName: "stethoscope")
                    .font(.system(size: 10.5, weight: .medium))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .help("Capture detection diagnostics to the Desktop")

            Spacer()

            Toggle(isOn: Binding(
                get: { appState.launchAtLoginEnabled },
                set: { appState.setLaunchAtLogin($0) }
            )) {
                Text("Open at login")
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(ColorTokens.fog.opacity(0.75))
            }
            .toggleStyle(.checkbox)
            .controlSize(.mini)
        }
    }

    // MARK: Status

    private var statusChipTitle: String {
        switch appState.status {
        case .idle:
            "Idle"
        case .watching:
            appState.runningApps.isEmpty ? "Waiting" : "Watching"
        case .paused:
            "Paused"
        case .attention:
            "Attention"
        case .permissionRequired:
            "No access"
        case .error:
            "Error"
        }
    }

    private var statusTint: Color {
        switch appState.status {
        case .attention:
            ColorTokens.coral
        case .watching:
            appState.runningApps.isEmpty ? ColorTokens.fog.opacity(0.6) : ColorTokens.success
        case .permissionRequired, .error:
            ColorTokens.coral
        case .paused, .idle:
            ColorTokens.fog.opacity(0.6)
        }
    }
}
