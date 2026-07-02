import AppKit
import SwiftUI

struct AppToggleSection: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader("Apps")

                ForEach(TargetApp.allCases) { targetApp in
                    let isRunning = appState.runningApps.contains(targetApp)

                    HStack(spacing: 12) {
                        TargetAppIcon(targetApp: targetApp, isRunning: isRunning)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(targetApp.displayName)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                            Text(isRunning ? "Open" : "Not open")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundStyle(isRunning ? ColorTokens.success.opacity(0.86) : ColorTokens.fog.opacity(0.58))
                                .lineLimit(1)
                        }

                        Spacer()

                        Toggle("", isOn: Binding(
                            get: { appState.preferences.isWatching(targetApp) },
                            set: { appState.toggleWatching(targetApp, enabled: $0) }
                        ))
                        .toggleStyle(.switch)
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
                        .padding(4)
                } else {
                    Image(systemName: "app.dashed")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(ColorTokens.fog)
                }
            }
            .frame(width: 32, height: 32)
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
            )

            Circle()
                .fill(isRunning ? ColorTokens.success : Color.white.opacity(0.22))
                .frame(width: 9, height: 9)
                .overlay(Circle().stroke(Color.black.opacity(0.65), lineWidth: 1.5))
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
