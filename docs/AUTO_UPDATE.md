# Auto-Update Readiness

Chime 4 Breakfast distributes outside the Mac App Store, so native auto-update will use Sparkle 2 once the update feed and signing keys are ready.

## Required before enabling updates

1. Generate a Sparkle EdDSA key pair and keep the private key in the release machine's Keychain only.
2. Add the public key and appcast feed URL to the app's release configuration.
3. Host a signed appcast on a stable project-controlled URL.
4. Add release automation that signs the update archive, generates the appcast entry, notarizes the DMG, and verifies Gatekeeper acceptance before publishing.
5. Test first install, update-over-existing-install, rollback behavior, and a failed-download path on a clean macOS account.

Until those controls exist, releases remain signed, notarized DMGs from GitHub Releases. This is deliberate: a manual update is safer than an unsigned or unverifiable update path.
