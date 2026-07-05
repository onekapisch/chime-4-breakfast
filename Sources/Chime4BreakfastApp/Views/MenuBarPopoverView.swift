import AppKit
import SwiftUI

struct MenuBarPopoverView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showingDiagnosticsWarning = false

    var body: some View {
        ZStack {
            // Depth comes from an opaque layered gradient with a soft top
            // light. (NSVisualEffectView behind-window blur breaks the
            // MenuBarExtra window's shape, so no live vibrancy here.)
            LinearGradient(
                colors: [
                    ColorTokens.baseElevated,
                    ColorTokens.base,
                    Color(red: 0.02, green: 0.02, blue: 0.03)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color.white.opacity(0.09), .clear],
                center: UnitPoint(x: 0.5, y: -0.1),
                startRadius: 10,
                endRadius: 320
            )
            .ignoresSafeArea()

            NoiseTexture()
                .opacity(0.28)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 12)

                Rectangle()
                    .fill(Color.white.opacity(0.07))
                    .frame(height: 1)

                ScrollView {
                    VStack(spacing: 16) {
                        StatusBanner()
                        AppToggleSection()
                        SoundSection()
                        GlowSection()
                        RulesSection()
                        RecentActivitySection()
                    }
                    .padding(14)
                    .animation(.smooth(duration: 0.26), value: appState.status)
                    .animation(.smooth(duration: 0.26), value: appState.runningApps)
                }
                .scrollIndicators(.hidden)

                Rectangle()
                    .fill(Color.white.opacity(0.07))
                    .frame(height: 1)

                footer
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
            }
        }
        .frame(width: 368, height: 640)
        .preferredColorScheme(.dark)
        .onAppear {
            appState.acknowledgeAttention()
        }
        .alert("Capture Diagnostics?", isPresented: $showingDiagnosticsWarning) {
            Button("Cancel", role: .cancel) {}
            Button("Capture") {
                appState.captureDiagnostics()
            }
        } message: {
            Text("This writes a Desktop report with visible Accessibility text from Codex and Claude, including snippets of prompts or replies on screen.")
        }
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 11) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .interpolation(.high)
                .frame(width: 36, height: 36)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                .shadow(color: statusTint.opacity(0.35), radius: 10, x: 0, y: 4)

            VStack(alignment: .leading, spacing: 3) {
                Text("Chime 4 Breakfast")
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundStyle(.white)

                WaveformMotif(active: isLive)
            }

            Spacer(minLength: 8)

            statusChip
        }
    }

    private var isLive: Bool {
        appState.status == .watching && !appState.runningApps.isEmpty
    }

    private var statusChip: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(statusTint)
                .frame(width: 6.5, height: 6.5)
                .shadow(color: statusTint.opacity(0.8), radius: 3)
            Text(statusChipTitle)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.88))
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(Color.white.opacity(0.08), in: Capsule())
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
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
                showingDiagnosticsWarning = true
            } label: {
                Image(systemName: "waveform.badge.magnifyingglass")
                    .font(.system(size: 11, weight: .medium))
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
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(ColorTokens.fog.opacity(0.78))
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

/// The five-bar waveform from the app icon, miniaturized as a static brand
/// mark. Bright while actively watching, dimmed otherwise. (No looping
/// animation: repeat-forever animations inside a MenuBarExtra window cause
/// continuous layout churn that makes the popover jitter.)
private struct WaveformMotif: View {
    let active: Bool

    private let heights: [CGFloat] = [7, 11, 15, 10, 7.5]

    var body: some View {
        HStack(alignment: .center, spacing: 2.5) {
            ForEach(heights.indices, id: \.self) { index in
                RoundedRectangle(cornerRadius: 1.6, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(white: 0.96), Color(white: 0.62)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 3.2, height: heights[index])
            }
        }
        .frame(height: 16, alignment: .center)
        .opacity(active ? 0.95 : 0.5)
    }
}
