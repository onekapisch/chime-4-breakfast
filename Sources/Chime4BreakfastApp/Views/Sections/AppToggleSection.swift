import AppKit
import SwiftUI

struct AppToggleSection: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        SectionBlock("Apps") {
            ForEach(Array(TargetApp.allCases.enumerated()), id: \.element.id) { index, targetApp in
                if index > 0 { RowDivider() }

                let isRunning = appState.runningApps.contains(targetApp)

                HStack(spacing: 10) {
                    TargetAppIcon(targetApp: targetApp, isRunning: isRunning)

                    Text(targetApp.displayName)
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(.white.opacity(0.96))

                    Text(isRunning ? "Open" : "Not open")
                        .font(.system(size: 10.5))
                        .foregroundStyle(isRunning ? ColorTokens.success.opacity(0.85) : ColorTokens.fog.opacity(0.45))

                    Spacer(minLength: 8)

                    MiniToggle(isOn: Binding(
                        get: { appState.preferences.isWatching(targetApp) },
                        set: { appState.toggleWatching(targetApp, enabled: $0) }
                    ))
                }
                .padding(.vertical, 7)
            }
        }
    }
}

private struct TargetAppIcon: View {
    let targetApp: TargetApp
    let isRunning: Bool

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let icon {
                    Image(nsImage: icon)
                        .resizable()
                        .scaledToFit()
                } else {
                    Image(systemName: "app.dashed")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(ColorTokens.fog)
                }
            }
            .frame(width: 22, height: 22)

            Circle()
                .fill(isRunning ? ColorTokens.success : Color.white.opacity(0.2))
                .frame(width: 7, height: 7)
                .overlay(Circle().stroke(ColorTokens.base, lineWidth: 1.5))
                .offset(x: 2, y: 2)
        }
    }

    private var icon: NSImage? {
        if let runningIcon = NSRunningApplication
            .runningApplications(withBundleIdentifier: targetApp.bundleIdentifier)
            .first?
            .icon {
            return runningIcon
        }

        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: targetApp.bundleIdentifier) else {
            return nil
        }

        return NSWorkspace.shared.icon(forFile: appURL.path)
    }
}
