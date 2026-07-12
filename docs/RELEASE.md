# Releasing Chime 4 Breakfast

Chime 4 Breakfast reads other apps' UI through the Accessibility API, so it **cannot
be sandboxed** and is therefore **not distributable on the Mac App Store**. Ship
it as a notarized DMG (for example, attached to a GitHub Release).

## 1. One-time setup

You need an Apple Developer account ($99/year) for a Developer ID certificate.

1. In Xcode, sign in with your Apple ID and create a **Developer ID Application**
   certificate (Settings → Accounts → Manage Certificates).
2. Store notarization credentials in the keychain:

   ```bash
   xcrun notarytool store-credentials chime-4-breakfast \
     --apple-id "you@example.com" \
     --team-id "TEAMID"
   ```

   `notarytool` will prompt securely and store the credential in Keychain.
   `chime-4-breakfast` becomes your `NOTARY_PROFILE` name.

## 2. Build, sign, notarize, package

Before building, update `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in
`project.yml`. The GitHub tag, release title, and app version must agree.

```bash
DEVELOPER_ID="Developer ID Application: Your Name (TEAMID)" \
NOTARY_PROFILE="chime-4-breakfast" \
./scripts/build-release.sh
```

This produces a signed, notarized, stapled `Chime 4 Breakfast.dmg` and a
SHA-256 checksum file in `.release/`. The script mounts the final DMG and asks
Gatekeeper to assess the contained app, so it exits non-zero unless the
notarized installer is accepted.

Without `DEVELOPER_ID` / `NOTARY_PROFILE`, the script still builds and packages an
unsigned DMG for local testing.

## 3. Publish

1. Run the full test suite from the exact commit being released.
2. Create an annotated `vX.Y.Z` tag matching `MARKETING_VERSION`.
3. Attach both the DMG and its `.sha256` file to the matching GitHub Release.
4. Include the completed user-facing changes and first-run Accessibility note in
   the release body.

## Hardened runtime note

The release build signs with `--options runtime`. Accessibility is granted by the
user in System Settings at first run; no extra entitlement is required for it.
