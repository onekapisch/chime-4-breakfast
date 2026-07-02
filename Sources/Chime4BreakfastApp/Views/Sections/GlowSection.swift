import SwiftUI

struct GlowSection: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        sectionHeader("Screen Glow")
                        Text("App-colored edge light when a watched response finishes away from you")
                            .font(.system(size: 11))
                            .foregroundStyle(ColorTokens.fog.opacity(0.58))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { appState.preferences.screenGlowEnabled },
                        set: { appState.setScreenGlowEnabled($0) }
                    ))
                    .labelsHidden()
                }

                if appState.preferences.screenGlowEnabled {
                    HStack(spacing: 8) {
                        GlowModeChip(title: "Completion", subtitle: "App-color flash")
                        GlowModeChip(title: "Attention", subtitle: "App-color pulse")
                    }

                    HStack(spacing: 10) {
                        Text("Intensity")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(ColorTokens.fog.opacity(0.82))

                        Slider(
                            value: Binding(
                                get: { appState.preferences.glowIntensity },
                                set: { appState.setGlowIntensity($0) }
                            ),
                            in: 0.2...1.0
                        )
                        .tint(ColorTokens.accent)
                    }

                    Button {
                        appState.previewGlow()
                    } label: {
                        Label("Preview", systemImage: "sparkles")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(.bordered)
                    .tint(ColorTokens.electricBlue.opacity(0.72))
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

private struct GlowModeChip: View {
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(ColorTokens.fog.opacity(0.82))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(ColorTokens.fog.opacity(0.58))
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
