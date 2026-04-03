import SwiftUI

struct RecentActivitySection: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("Recent")

                if appState.recentActivity.isEmpty {
                    Text("No detections yet. Once Codex or Claude finishes a response, the latest event will appear here.")
                        .font(.system(size: 11))
                        .foregroundStyle(ColorTokens.fog.opacity(0.6))
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    VStack(spacing: 8) {
                        ForEach(appState.recentActivity) { item in
                            HStack(alignment: .top, spacing: 10) {
                                Circle()
                                    .fill(item.eventType.accentColor)
                                    .frame(width: 8, height: 8)
                                    .padding(.top, 4)

                                VStack(alignment: .leading, spacing: 3) {
                                    HStack {
                                        Text(item.sourceApp.displayName)
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(.white)
                                        Text("•")
                                            .foregroundStyle(ColorTokens.fog.opacity(0.42))
                                        Text(item.eventType.title)
                                            .font(.system(size: 11, weight: .medium))
                                            .foregroundStyle(item.eventType.accentColor)
                                        Spacer()
                                        Text(item.timestamp.formatted(date: .omitted, time: .shortened))
                                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                                            .foregroundStyle(ColorTokens.fog.opacity(0.6))
                                    }

                                    Text(item.excerpt)
                                        .font(.system(size: 11))
                                        .foregroundStyle(ColorTokens.fog.opacity(0.84))
                                        .lineLimit(2)
                                }
                            }
                            .padding(10)
                            .background(Color.white.opacity(0.03), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    }
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
