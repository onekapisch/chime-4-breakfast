# Troubleshooting

## Start with a setup test

Open the menu-bar popover, select the checkmark badge in the header, then choose **Test Codex** or **Test Claude**. The test plays the selected completion sound, shows the selected app-color glow, and sends a banner when banners are enabled. It also creates a Recent entry.

## Chime opened a recovery panel instead of appearing in the menu bar

Chime is an agent app and never deliberately becomes a Dock app. Until you have opened Chime's icon from the menu bar once, it keeps a recovery panel available so the app cannot become unreachable. The panel closes as soon as the icon is opened. It also returns if AppKit reports an off-screen status-item host. Closing the panel keeps it closed until you relaunch Chime.

## The popover says No access

1. Launch the installed app from `~/Applications/Chime 4 Breakfast.app`.
2. Select **Open Settings** in the popover.
3. In **System Settings → Privacy & Security → Accessibility**, enable Chime 4 Breakfast.
4. Quit and relaunch Chime if macOS does not refresh the status immediately.

Developer builds must use a stable signing identity. Run `./scripts/setup-signing.sh` once before repeatedly launching a source build.

## The setup test works but automatic alerts do not

Automatic glow is intentionally shown only when you have moved away from the source app. Keep Codex or Claude on a normal conversation window, send a prompt, switch to another app, and wait for the response to finish.

Check that the target app is enabled in the Apps section and that Completion or Attention alerts are enabled in Rules. Quiet hours can intentionally mute all signals or only sound.

## The wrong sound plays

Use the play button beside the selected sound to audition it. In **Per event** mode, Completion and Attention have different choices. In **Per app** mode, Codex and Claude each use one sound for both event types.

## Capture a useful bug report

Choose the diagnostics button in the popover footer and confirm the warning. The report is written to the Desktop and can contain visible text from supported app windows, including prompt or reply snippets. Review it before sharing it in a GitHub issue.
