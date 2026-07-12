import SwiftUI

struct GlowSection: View {
    @EnvironmentObject private var appState: AppState
    @State private var previewApp: TargetApp = .codex

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
                    HStack(spacing: 8) {
                        Text("\(Int(appState.preferences.glowIntensity * 100))%")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundStyle(ColorTokens.fog.opacity(0.72))
                            .frame(width: 30, alignment: .trailing)

                        Slider(
                            value: Binding(
                                get: { appState.preferences.glowIntensity },
                                set: { appState.setGlowIntensity($0) }
                            ),
                            in: 0.2...1.0
                        )
                        .controlSize(.small)
                        .frame(width: 96)
                    }
                }

                RowDivider()

                CompactRow(title: "Preview color") {
                    Picker("Preview source", selection: $previewApp) {
                        ForEach(TargetApp.allCases) { app in
                            Text(app.displayName).tag(app)
                        }
                    }
                    .labelsHidden()
                    .controlSize(.small)
                    .frame(width: 92)
                }
            }
        }
    }

    private var previewButton: some View {
        Button {
            appState.previewGlow(for: previewApp)
        } label: {
            Label("Preview", systemImage: "sparkles")
                .font(.system(size: 10, weight: .medium))
        }
        .buttonStyle(.borderless)
        .foregroundStyle(ColorTokens.fog.opacity(0.8))
        .disabled(!appState.preferences.screenGlowEnabled)
    }
}
