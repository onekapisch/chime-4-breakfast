import SwiftUI

struct GlowSection: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        SectionBlock("Screen Glow", trailing: AnyView(previewButton)) {
            CompactRow(
                title: "Glow when you're away",
                subtitle: "Edge light in the app's color, about a second"
            ) {
                MiniToggle(isOn: Binding(
                    get: { appState.preferences.screenGlowEnabled },
                    set: { appState.setScreenGlowEnabled($0) }
                ))
            }

            if appState.preferences.screenGlowEnabled {
                RowDivider()

                CompactRow(title: "Intensity") {
                    Slider(
                        value: Binding(
                            get: { appState.preferences.glowIntensity },
                            set: { appState.setGlowIntensity($0) }
                        ),
                        in: 0.7...1.0
                    )
                    .controlSize(.small)
                    .frame(width: 132)
                }
            }
        }
    }

    private var previewButton: some View {
        Button {
            appState.previewGlow()
        } label: {
            Label("Preview", systemImage: "sparkles")
                .font(.system(size: 10, weight: .medium))
        }
        .buttonStyle(.borderless)
        .foregroundStyle(ColorTokens.fog.opacity(0.8))
        .disabled(!appState.preferences.screenGlowEnabled)
    }
}
