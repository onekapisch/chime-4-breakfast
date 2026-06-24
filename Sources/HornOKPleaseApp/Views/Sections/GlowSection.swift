import SwiftUI

struct GlowSection: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        sectionHeader("Screen Glow")
                        Text("Glow the display edges when a response lands")
                            .font(.system(size: 11))
                            .foregroundStyle(ColorTokens.fog.opacity(0.58))
                    }

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { appState.preferences.screenGlowEnabled },
                        set: { appState.setScreenGlowEnabled($0) }
                    ))
                    .labelsHidden()
                }

                if appState.preferences.screenGlowEnabled {
                    glowRow(for: .completion)
                    glowRow(for: .attention)

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
                        .tint(ColorTokens.magenta.opacity(0.8))
                    }
                }
            }
        }
    }

    private func glowRow(for eventType: NotificationEventType) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(eventType.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                Text(eventType == .completion ? "Edge color when a response settles" : "Edge color for questions and blockers")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(ColorTokens.fog.opacity(0.58))
            }

            Spacer()

            ColorPicker(
                "",
                selection: Binding(
                    get: { Color(hex: appState.preferences.glowColorHex(for: eventType)) ?? eventType.accentColor },
                    set: { appState.setGlowColor($0, for: eventType) }
                ),
                supportsOpacity: false
            )
            .labelsHidden()
            .frame(width: 44)

            Button {
                appState.previewGlow(for: eventType)
            } label: {
                Image(systemName: "sparkles")
                    .font(.system(size: 11, weight: .bold))
            }
            .buttonStyle(.bordered)
            .tint(eventType.accentColor.opacity(0.72))
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .bold))
            .textCase(.uppercase)
            .foregroundStyle(ColorTokens.fog.opacity(0.72))
    }
}
