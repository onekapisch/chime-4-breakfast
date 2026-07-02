import SwiftUI

struct SoundSection: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        SectionBlock("Sounds") {
            soundRow(for: .completion, subtitle: "When a response finishes")
            RowDivider()
            soundRow(for: .attention, subtitle: "Questions and blockers")
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
}
