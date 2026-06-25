import SwiftUI

struct ReadinessSection: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 10) {
                    Image(systemName: symbolName)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(symbolColor)
                        .frame(width: 28, height: 28)
                        .background(symbolColor.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ready To Test")
                            .font(.system(size: 11, weight: .bold))
                            .textCase(.uppercase)
                            .foregroundStyle(ColorTokens.fog.opacity(0.72))

                        Text(appState.statusTitle)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }

                Text(appState.statusDetail)
                    .font(.system(size: 12))
                    .foregroundStyle(ColorTokens.fog.opacity(0.84))
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(instructions, id: \.self) { instruction in
                        HStack(alignment: .top, spacing: 10) {
                            Circle()
                                .fill(symbolColor.opacity(0.8))
                                .frame(width: 6, height: 6)
                                .padding(.top, 5)

                            Text(instruction)
                                .font(.system(size: 11))
                                .foregroundStyle(ColorTokens.fog.opacity(0.78))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
    }

    private var symbolName: String {
        switch appState.status {
        case .permissionRequired:
            "hand.raised.fill"
        case .attention:
            "bell.badge.fill"
        case .paused:
            "pause.circle.fill"
        case .error:
            "exclamationmark.triangle.fill"
        case .idle, .watching:
            "sparkle.magnifyingglass"
        }
    }

    private var symbolColor: Color {
        switch appState.status {
        case .permissionRequired:
            Color.orange
        case .attention:
            ColorTokens.coral
        case .paused:
            ColorTokens.fog
        case .error:
            Color.red.opacity(0.85)
        case .idle, .watching:
            ColorTokens.blue
        }
    }

    private var instructions: [String] {
        switch appState.status {
        case .permissionRequired:
            [
                "Click Open Accessibility and enable Chime 4 Breakfast in System Settings.",
                "Keep Codex or Claude open on a conversation screen once permission is granted.",
                "Wait for a finished assistant response and watch the Recent panel for the first detection."
            ]
        case .paused:
            [
                "Resume watching from the footer button.",
                "Keep Codex or Claude open on a conversation screen.",
                "Wait for a finished assistant response and confirm the sound and Recent log."
            ]
        case .idle, .watching, .attention, .error:
            [
                "Keep Codex or Claude open on a conversation screen.",
                "Send any prompt and let the assistant finish streaming a reply.",
                "Confirm you hear the selected sound and see a new item in the Recent panel."
            ]
        }
    }
}
