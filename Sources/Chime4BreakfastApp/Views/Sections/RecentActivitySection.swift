import SwiftUI

struct RecentActivitySection: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        SectionBlock("Recent", trailing: AnyView(clearButton)) {
            if appState.recentActivity.isEmpty {
                Text("Finished responses will appear here.")
                    .font(.system(size: 11))
                    .foregroundStyle(ColorTokens.fog.opacity(0.5))
                    .padding(.vertical, 10)
            } else {
                ForEach(Array(appState.recentActivity.prefix(5).enumerated()), id: \.element.id) { index, item in
                    if index > 0 { RowDivider() }
                    activityRow(item)
                }
            }
        }
    }

    @ViewBuilder
    private var clearButton: some View {
        if !appState.recentActivity.isEmpty {
            Button("Clear") {
                appState.clearRecentActivity()
            }
            .buttonStyle(.plain)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(ColorTokens.fog.opacity(0.6))
        }
    }

    private func activityRow(_ item: ActivityItem) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Circle()
                    .fill(item.eventType == .attention ? ColorTokens.coral : ColorTokens.success)
                    .frame(width: 6, height: 6)

                Text(item.sourceApp.displayName)
                    .font(.system(size: 11.5, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.95))

                Text(item.eventType.title)
                    .font(.system(size: 10))
                    .foregroundStyle(ColorTokens.fog.opacity(0.6))

                Spacer(minLength: 8)

                Text(item.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(ColorTokens.fog.opacity(0.5))
            }

            Text(item.excerpt)
                .font(.system(size: 10.5))
                .foregroundStyle(ColorTokens.fog.opacity(0.75))
                .lineLimit(2)

            if let delivery = item.delivery {
                Text(delivery)
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundStyle(ColorTokens.fog.opacity(0.45))
            }
        }
        .padding(.vertical, 7)
    }
}
