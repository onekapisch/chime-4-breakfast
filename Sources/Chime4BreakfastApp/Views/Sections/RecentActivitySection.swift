import SwiftUI

struct RecentActivitySection: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    sectionHeader("Recent")
                    Spacer()
                    if !appState.recentActivity.isEmpty {
                        Text("\(appState.recentActivity.count)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(ColorTokens.fog.opacity(0.72))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.06), in: Capsule())
                    }
                }

                if appState.recentActivity.isEmpty {
                    HStack(spacing: 10) {
                        Image(systemName: "clock.badge.questionmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(ColorTokens.fog.opacity(0.7))
                            .frame(width: 28, height: 28)
                            .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 9, style: .continuous))

                        Text("No finished responses yet")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(ColorTokens.fog.opacity(0.72))
                    }
                } else {
                    VStack(spacing: 8) {
                        ForEach(appState.recentActivity) { item in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: item.eventType.symbolName)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundStyle(item.eventType.accentColor)
                                    .frame(width: 24, height: 24)
                                    .background(item.eventType.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

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
                                        .lineLimit(3)

                                    if let delivery = item.delivery {
                                        Label(delivery, systemImage: deliverySymbol(for: delivery))
                                            .font(.system(size: 10, weight: .medium))
                                            .foregroundStyle(ColorTokens.fog.opacity(0.58))
                                            .padding(.top, 1)
                                    }
                                }
                            }
                            .padding(10)
                            .background(Color.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
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

    private func deliverySymbol(for delivery: String) -> String {
        if delivery.hasPrefix("Muted") { return "moon.zzz.fill" }
        if delivery.contains("glow is off") || delivery.contains("in the app") { return "speaker.wave.2.fill" }
        return "sparkles"
    }
}
