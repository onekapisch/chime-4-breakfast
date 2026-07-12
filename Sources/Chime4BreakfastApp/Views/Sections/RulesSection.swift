import SwiftUI

struct RulesSection: View {
    @EnvironmentObject private var appState: AppState
    @State private var newPhrase = ""
    @State private var showsPhrases = false

    private let hours = Array(0..<24)

    var body: some View {
        SectionBlock("Rules") {
            CompactRow(title: "Completion alerts") {
                MiniToggle(isOn: Binding(
                    get: { appState.preferences.completionAlertsEnabled },
                    set: { appState.setAlertsEnabled($0, for: .completion) }
                ))
            }

            RowDivider()

            CompactRow(title: "Attention alerts") {
                MiniToggle(isOn: Binding(
                    get: { appState.preferences.attentionAlertsEnabled },
                    set: { appState.setAlertsEnabled($0, for: .attention) }
                ))
            }

            RowDivider()

            CompactRow(title: "Notification banners", subtitle: "When you're away") {
                MiniToggle(isOn: Binding(
                    get: { appState.preferences.notificationsEnabled },
                    set: { appState.setNotificationsEnabled($0) }
                ))
            }

            RowDivider()

            CompactRow(title: "Quiet hours", subtitle: quietHoursSubtitle) {
                MiniToggle(isOn: Binding(
                    get: { appState.preferences.quietHoursEnabled },
                    set: { appState.setQuietHoursEnabled($0) }
                ))
            }

            if appState.preferences.quietHoursEnabled {
                HStack(spacing: 8) {
                    hourPicker(selection: Binding(
                        get: { appState.preferences.quietHoursStartHour },
                        set: { appState.setQuietHoursStart(hour: $0) }
                    ))
                    Text("to")
                        .font(.system(size: 10.5))
                        .foregroundStyle(ColorTokens.fog.opacity(0.55))
                    hourPicker(selection: Binding(
                        get: { appState.preferences.quietHoursEndHour },
                        set: { appState.setQuietHoursEnd(hour: $0) }
                    ))
                    Spacer()
                }
                .padding(.bottom, 8)

                Picker("Quiet-hours mode", selection: Binding(
                    get: { appState.preferences.quietHoursMode },
                    set: { appState.setQuietHoursMode($0) }
                )) {
                    ForEach(QuietHoursMode.allCases, id: \.self) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .labelsHidden()
                .controlSize(.small)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 8)
            }

            RowDivider()

            disclosureRow

            if showsPhrases {
                phraseEditor
                    .padding(.bottom, 8)
            }
        }
    }

    private var quietHoursSubtitle: String {
        appState.preferences.quietHoursMode == .soundOnly
            ? "Mutes sound; keeps visual alerts when away"
            : "Silences sound, glow, and banners"
    }

    private var disclosureRow: some View {
        Button {
            withAnimation(.smooth(duration: 0.2)) { showsPhrases.toggle() }
        } label: {
            HStack(spacing: 6) {
                Text("Custom attention phrases")
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundStyle(.white.opacity(0.96))

                if !appState.preferences.customAttentionPhrases.isEmpty {
                    Text("\(appState.preferences.customAttentionPhrases.count)")
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .foregroundStyle(ColorTokens.fog.opacity(0.7))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.07), in: Capsule())
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(ColorTokens.fog.opacity(0.5))
                    .rotationEffect(.degrees(showsPhrases ? 90 : 0))
            }
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var phraseEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                TextField("Add a phrase…", text: $newPhrase)
                    .textFieldStyle(.roundedBorder)
                    .controlSize(.small)
                    .onSubmit(addPhrase)

                Button("Add", action: addPhrase)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(newPhrase.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            ForEach(appState.preferences.customAttentionPhrases, id: \.self) { phrase in
                HStack(spacing: 8) {
                    Text(phrase)
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.9))
                    Spacer()
                    Button {
                        appState.removeAttentionPhrase(phrase)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(ColorTokens.fog.opacity(0.55))
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(Color.white.opacity(0.04), in: Capsule())
            }
        }
    }

    private func addPhrase() {
        appState.addAttentionPhrase(newPhrase)
        newPhrase = ""
    }

    private func hourPicker(selection: Binding<Int>) -> some View {
        Picker("", selection: selection) {
            ForEach(hours, id: \.self) { hour in
                Text(String(format: "%02d:00", hour)).tag(hour)
            }
        }
        .labelsHidden()
        .controlSize(.small)
        .frame(width: 84)
    }
}
