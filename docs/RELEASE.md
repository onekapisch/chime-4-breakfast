# Releasing Horn OK Please

Horn OK Please reads other apps' UI through the Accessibility API, so it **cannot
be sandboxed** and is therefore **not distributable on the Mac App Store**. Ship
it as a notarized DMG (for example, attached to a GitHub Release).

## 1. One-time setup

You need an Apple Developer account ($99/year) for a Developer ID certificate.

1. In Xcode, sign in with your Apple ID and create a **Developer ID Application**
   certificate (Settings → Accounts → Manage Certificates).
2. Store notarization credentials in the keychain:

   ```bash
   xcrun notarytool store-credentials horn-ok-please \
     --apple-id "you@example.com" \
     --team-id "TEAMID" \
     --password "app-specific-password"
   ```

   (`horn-ok-please` becomes your `NOTARY_PROFILE` name.)

## 2. Build, sign, notarize, package

```bash
DEVELOPER_ID="Developer ID Application: Your Name (TEAMID)" \
NOTARY_PROFILE="horn-ok-please" \
./scripts/build-release.sh
```

This produces a signed, notarized, stapled `Horn OK Please.dmg` in `.release/`.

Without `DEVELOPER_ID` / `NOTARY_PROFILE`, the script still builds and packages an
unsigned DMG for local testing.

## 3. Publish

Attach the DMG to a GitHub Release and update the version in `CHANGELOG.md`.

## Hardened runtime note

The release build signs with `--options runtime`. Accessibility is granted by the
user in System Settings at first run; no extra entitlement is required for it.
