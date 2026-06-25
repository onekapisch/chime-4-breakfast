import SwiftUI

struct SoundSection: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("Sounds")
                soundPickerRow(for: .completion)
                soundPickerRow(for: .attention)
            }
        }
    }

    private func soundPickerRow(for eventType: NotificationEventType) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(eventType.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                Text(eventType == .completion ? "Soft finish cue" : "Decision or blocker cue")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(ColorTokens.fog.opacity(0.58))
            }

            Spacer()

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
            .frame(width: 116)

            Button {
                appState.previewSound(for: eventType)
            } label: {
                Image(systemName: "play.fill")
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
