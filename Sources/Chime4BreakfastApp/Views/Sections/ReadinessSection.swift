import SwiftUI

/// A contextual banner that only appears when something needs the user:
/// missing Accessibility permission, paused monitoring, or a watcher error.
/// In the healthy state it renders nothing - the header chip already says
/// "Watching".
struct StatusBanner: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        if let issue = appState.issue {
            banner(
                icon: issue.iconName,
                tint: ColorTokens.coral,
                message: issue.message,
                actionTitle: "Dismiss"
            ) {
                appState.dismissIssue()
            }
        } else {
            switch appState.status {
        case .permissionRequired:
            banner(
                icon: "hand.raised.fill",
                tint: ColorTokens.coral,
                message: "Grant Accessibility access so alerts can work.",
                actionTitle: "Open Settings"
            ) {
                appState.openAccessibilitySettings()
            }
        case .paused:
            banner(
                icon: "pause.fill",
                tint: ColorTokens.fog,
                message: "Monitoring is paused.",
                actionTitle: "Resume"
            ) {
                appState.resumeWatching()
            }
        case .error:
            banner(
                icon: "exclamationmark.triangle.fill",
                tint: ColorTokens.coral,
                message: "The watcher hit an error. Try pausing and resuming.",
                actionTitle: nil,
                action: nil
            )
        case .idle, .watching, .attention:
            EmptyView()
            }
        }
    }

    private func banner(
        icon: String,
        tint: Color,
        message: String,
        actionTitle: String?,
        action: (() -> Void)? = nil
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(tint)

            Text(message)
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(.white.opacity(0.92))
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 8)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(tint.opacity(0.25), lineWidth: 1)
        )
    }
}
