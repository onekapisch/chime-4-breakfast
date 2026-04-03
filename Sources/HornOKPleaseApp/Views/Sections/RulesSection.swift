import SwiftUI

struct RulesSection: View {
    @EnvironmentObject private var appState: AppState

    private let hours = Array(0..<24)

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("Rules")

                ToggleRow(
                    title: "Completion alerts",
                    subtitle: "Play the soft sound when a response settles",
                    isOn: Binding(
                        get: { appState.preferences.completionAlertsEnabled },
                        set: { appState.setAlertsEnabled($0, for: .completion) }
                    )
                )

                ToggleRow(
                    title: "Attention alerts",
                    subtitle: "Play the stronger sound for questions and blockers",
                    isOn: Binding(
                        get: { appState.preferences.attentionAlertsEnabled },
                        set: { appState.setAlertsEnabled($0, for: .attention) }
                    )
                )

                ToggleRow(
                    title: "Quiet hours",
                    subtitle: "Mute sounds while still keeping the activity log",
                    isOn: Binding(
                        get: { appState.preferences.quietHoursEnabled },
                        set: { appState.setQuietHoursEnabled($0) }
                    )
                )

                if appState.preferences.quietHoursEnabled {
                    HStack(spacing: 12) {
                        quietHourPicker(
                            title: "Start",
                            selection: Binding(
                                get: { appState.preferences.quietHoursStartHour },
                                set: { appState.setQuietHoursStart(hour: $0) }
                            )
                        )

                        quietHourPicker(
                            title: "End",
                            selection: Binding(
                                get: { appState.preferences.quietHoursEndHour },
                                set: { appState.setQuietHoursEnd(hour: $0) }
                            )
                        )
                    }
                }
            }
        }
    }

    private func quietHourPicker(title: String, selection: Binding<Int>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(ColorTokens.fog.opacity(0.72))

            Picker(title, selection: selection) {
                ForEach(hours, id: \.self) { hour in
                    Text(String(format: "%02d:00", hour)).tag(hour)
                }
            }
            .labelsHidden()
            .frame(maxWidth: .infinity)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .bold))
            .textCase(.uppercase)
            .foregroundStyle(ColorTokens.fog.opacity(0.72))
    }
}

private struct ToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(ColorTokens.fog.opacity(0.58))
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
    }
}
