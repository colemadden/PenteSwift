# App Store Submission Guide - Version 1.2 (Build 5)

## Release History

| Version | Build | Date | Status | Key Changes |
|---------|-------|------|--------|-------------|
| 1.0 | 1-2 | Aug 2025 | Released | Initial release + multiplayer bug fixes |
| 1.1 | 3 | Mar 2026 | Released | App icons, encryption compliance |
| 1.2 | 5 | Apr 2026 | In Review | PenteCore modular refactor, UI improvements |

## What's in v1.2

### PenteCore Swift Package Refactor
- Extracted core game logic into standalone `PenteCore/` Swift Package
- `GameBoard`, `CaptureEngine`, `WinDetector`, `GameStateEncoder`, `GameTypes` now live in PenteCore
- Extension UI layer imports from PenteCore — cleaner separation of concerns
- 36 fast pure-logic tests runnable via `swift test` (no simulator needed)

### UI & Quality
- Updated board image generator with theme support improvements
- Streamlined MessagesViewController and PenteGameView
- Updated test suite to match modular architecture

## How to Build & Submit

### Option A: Programmatic (via CLI)
```bash
# Archive
xcodebuild -project Pente.xcodeproj -scheme "Pente MessagesExtension" \
  -archivePath build/Pente.xcarchive archive -allowProvisioningUpdates

# Export IPA
xcodebuild -exportArchive -archivePath build/Pente.xcarchive \
  -exportOptionsPlist ExportOptions.plist -exportPath build/export

# Upload (credentials in .claude/CLAUDE.md)
xcrun altool --upload-app --type ios --file build/export/Pente.ipa \
  --apiKey <KEY_ID> --apiIssuer <ISSUER_ID>
```

### Option B: Xcode GUI
1. Open `Pente.xcodeproj`
2. Product > Archive
3. Organizer > Distribute App > App Store Connect > Upload

### Submit for Review (via API)
1. Create appStoreVersion (POST /v1/appStoreVersions)
2. Attach build (PATCH /v1/appStoreVersions/{id}/relationships/build)
3. Set What's New text (PATCH /v1/appStoreVersionLocalizations/{id})
4. Create reviewSubmission + reviewSubmissionItem, then PATCH submitted=true

## What's New Text (v1.2)

```
Version 1.2 brings improved game architecture for better reliability and performance. Core game logic has been modularized for a smoother gameplay experience.
```

## Version Info
- **Marketing Version**: 1.2
- **Build Number**: 5
- **Bundle ID**: colemadden.Pente / colemadden.Pente.MessagesExtension
- **Team ID**: SB4A7WG2KH
- **Min iOS**: 18.5
