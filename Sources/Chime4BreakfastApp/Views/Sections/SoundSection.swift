import SwiftUI

struct SoundSection: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        SectionBlock("Sounds") {
            CompactRow(title: "Sound profile", subtitle: "Choose how alerts are assigned") {
                Picker(
                    "Sound profile",
                    selection: Binding(
                        get: { appState.preferences.soundRoutingMode },
                        set: { appState.setSoundRoutingMode($0) }
                    )
                ) {
                    ForEach(SoundRoutingMode.allCases, id: \.self) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .labelsHidden()
                .controlSize(.small)
                .frame(width: 100)
            }

            RowDivider()

            if appState.preferences.soundRoutingMode == .event {
                soundRow(for: .completion, subtitle: "When a response finishes")
                RowDivider()
                soundRow(for: .attention, subtitle: "Questions and blockers")
            } else {
                providerSoundRow(for: .codex)
                RowDivider()
                providerSoundRow(for: .claude)
            }
        }
    }

    private func soundRow(for eventType: NotificationEventType, subtitle: String) -> some View {
        CompactRow(title: eventType.title, subtitle: subtitle) {
            HStack(spacing: 6) {
                Picker(
                    "",
                    selection: Binding(
                        get: { appState.preferences.soundID(for: eventType) },
                        set: { appState.setSound($0, for: eventType) }
                    )
                ) {
                    ForEach(SoundOption.catalog) { option in
                        Text(option.title).tag(option.id)
                    }
                }
                .labelsHidden()
                .controlSize(.small)
                .frame(width: 92)

                Button {
                    appState.previewSound(for: eventType)
                } label: {
                    Image(systemName: "play.fill")
                        .font(.system(size: 9, weight: .bold))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }

    private func providerSoundRow(for app: TargetApp) -> some View {
        CompactRow(title: app.displayName, subtitle: "Used for every \(app.displayName) alert") {
            HStack(spacing: 6) {
                Picker(
                    "",
                    selection: Binding(
                        get: { appState.preferences.soundID(for: app, eventType: .completion) },
                        set: { appState.setSound($0, for: app) }
                    )
                ) {
                    ForEach(SoundOption.catalog) { option in
                        Text(option.title).tag(option.id)
                    }
                }
                .labelsHidden()
                .controlSize(.small)
                .frame(width: 112)

                Button {
                    appState.previewSound(for: app)
                } label: {
                    Image(systemName: "play.fill")
                        .font(.system(size: 9, weight: .bold))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }
}
