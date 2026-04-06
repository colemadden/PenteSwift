# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an iOS iMessage extension app that implements the board game Pente. The app consists of:

- **Main app (Pente/)**: Simple placeholder app that directs users to use the iMessage extension
- **Messages extension (Pente MessagesExtension/)**: The actual game implementation that runs within iMessage

## Architecture

The codebase follows a modular Model-View pattern with SwiftUI. Core game logic lives in a local Swift Package (`PenteCore/`), with the UI layer in the Messages extension.

### PenteCore (Local Swift Package)
Pure game logic with no UIKit/SwiftUI dependencies:
- **`GameTypes.swift`**: Core game types (Player, GameState, WinMethod, GameMoveDelegate)
- **`GameBoard.swift`**: 19x19 board representation and basic operations
- **`CaptureEngine.swift`**: Isolated capture detection logic following Pente rules
- **`WinDetector.swift`**: Win condition checking (5-in-a-row and capture wins)
- **`GameStateEncoder.swift`**: URL encoding/decoding for game state persistence in iMessage

### Messages Extension UI Layer (Pente MessagesExtension/)
- **`PenteGameModel.swift`**: Orchestrates PenteCore modules, handles game state
- **`PenteGameView.swift`** + **`PenteBoardView.swift`**: SwiftUI views for game interface
- **`MessagesViewController.swift`**: UIKit controller that hosts SwiftUI view in Messages extension
- **`BoardImageGenerator.swift`**: Image generation for message previews with theme support

### Testing
- **`PenteCore/Tests/`**: Fast pure-logic tests runnable via `swift test` (no simulator)
- **`PenteTests/`**: Full test suite (238+ tests) including UI, integration, and Messages framework tests

### Key Features

- **Game State Encoding**: Game state is encoded into URL query parameters for sharing between devices via messages
- **Two-Step Move System**: Players place stones tentatively, then confirm/undo before sending to opponent
- **Capture System**: Implements Pente's capture rules (sandwich opponent stones between your own)
- **Win Conditions**: Five in a row OR capturing 5 pairs (10 stones) of opponent
- **Theme Support**: Automatic light/dark mode support with theme-aware colors

## Build Commands

### For Simulator Testing
```bash
# Build for iOS Simulator
xcodebuild -project Pente.xcodeproj -scheme "Pente MessagesExtension" build -destination "platform=iOS Simulator,name=iPhone 16"

# Install on simulator
xcrun simctl install "iPhone 16" "/path/to/Build/Products/Debug-iphonesimulator/Pente.app"
```

### For Physical Device Testing (Requires Paid Apple Developer Account)
```bash
# Find your device UDID
xcrun xctrace list devices

# Build for physical device
xcodebuild -project Pente.xcodeproj -scheme "Pente MessagesExtension" build -destination "id=YOUR_DEVICE_UDID" -allowProvisioningUpdates

# Install on device
xcrun devicectl device install app --device "YOUR_DEVICE_UDID" "/path/to/Build/Products/Debug-iphoneos/Pente.app"
```

### Running Tests

```bash
# Fast: PenteCore pure-logic tests (no simulator, ~0.01 seconds)
cd PenteCore && swift test

# Full: All 238+ tests via xcodebuild (requires simulator)
xcodebuild test -project Pente.xcodeproj -scheme PenteTests \
  -destination "platform=iOS Simulator,id=EF30FA9D-8D3D-4EC7-9571-C0D01151374E" \
  -only-testing:PenteTests

# Structured results (preferred over grep):
xcodebuild test -project Pente.xcodeproj -scheme PenteTests \
  -destination "platform=iOS Simulator,id=EF30FA9D-8D3D-4EC7-9571-C0D01151374E" \
  -resultBundlePath /tmp/PenteTestResults.xcresult
xcrun xcresulttool get test-results summary --path /tmp/PenteTestResults.xcresult

# Boot simulator if needed:
xcrun simctl boot EF30FA9D-8D3D-4EC7-9571-C0D01151374E
```

## Development Notes

### Apple Developer Account Requirements

**CRITICAL**: Physical device testing requires a **paid Apple Developer Program membership ($99/year)**:
- Free developer accounts cannot test iMessage extensions on physical devices
- Simulator testing works with free accounts
- Check developer.apple.com account status - "pending" status blocks full functionality
- Once activated, icons and full provisioning will work automatically

### iMessage Extension Icon Configuration

The extension uses **iMessage App Icon.appiconset** (NOT sticker format):
- Required sizes: 29x29, 27x20, 32x24 (2x/3x), plus 1024x1024 marketing
- Both main app and extension need complete icon sets for proper display
- Icons appear blank until developer account is fully activated
- Asset catalog must be configured as `.appiconset`, not `.stickersiconset`

### Messages Extension Specifics

- Game state persists through message URL encoding/decoding via `GameStateEncoder`
- Extension runs in sandboxed environment within iMessage
- **MSSession**: All messages in a game share one `MSSession` to prevent replaying from old message states
- **Player Assignment**: UUID-based `blackPlayerID` tracking prevents playing opponent's turn
- Use `MessagesViewController.swift` for move delegation between game model and Messages framework
- Board image generation in `BoardImageGenerator.swift` creates message previews with theme support
- Extension identifier: `com.apple.message-payload-provider` in `Info.plist`

### Modular Game Logic (Refactored Architecture)

- **Board**: 19x19 grid in `GameBoard.swift` with subscript access
- **Captures**: Isolated logic in `CaptureEngine.swift` with 8-direction detection
- **Win Detection**: Separated into `WinDetector.swift` for 5-in-a-row and capture wins
- **Game State**: URL encoding/decoding in `GameStateEncoder.swift`
- **Main Model**: `PenteGameModel.swift` now orchestrates modules vs implementing all logic

### Testing Strategy

- **PenteCore Tests**: 36+ fast tests via `swift test` — no simulator, runs in <1 second
- **Full Suite**: 238+ tests in `/PenteTests/` covering all game rules, UI, and integration
- **Pre-commit Hook**: Automatically runs PenteCore tests before each commit
- **Simulator Testing**: Required for UI/Messages framework tests
- **Physical Device**: Required for final iMessage extension validation

### **MANDATORY TESTING REQUIREMENTS**

**ALL NEW FEATURES AND BUG FIXES MUST INCLUDE UNIT TESTS:**

1. **New Game Logic**: Write tests covering all code paths, edge cases, and error conditions
2. **UI Components**: Test user interactions, state changes, and view updates
3. **Data Encoding/Decoding**: Test URL parameter serialization, edge cases, and malformed data
4. **Player Assignment Logic**: Test participant identification, role assignments, and permission checks
5. **Image Generation**: Test dynamic theme support, performance, and memory management
6. **Message Handling**: Test iMessage integration, conversation flow, and error recovery

**Test Requirements:**
- ✅ **100% Code Coverage**: All new code must have corresponding tests
- ✅ **Edge Case Testing**: Handle invalid inputs, boundary conditions, and error states
- ✅ **Performance Testing**: Use `measure {}` blocks for computationally intensive operations
- ✅ **Memory Management**: Test for retain cycles and proper cleanup
- ✅ **Integration Testing**: Verify components work together correctly

**Test Naming Convention:**
- `testFeatureName()` - Basic functionality
- `testFeatureNameWithEdgeCase()` - Boundary conditions
- `testFeatureNamePerformance()` - Performance requirements
- `testFeatureNameErrorHandling()` - Error conditions

**Before committing any feature:**
1. Write comprehensive unit tests
2. Run all tests via Xcode Test Navigator (⌘+6)
3. Verify 100% test pass rate
4. Check code coverage reports

### GitHub Integration

Repository: https://github.com/colemadden/PenteSwift.git
- All refactoring and icon fixes committed
- Test suite included in repository
- Use `git push` to sync changes to GitHub

### App Store Connect API Access

Programmatic access to App Store Connect is available via the REST API:
- **API Key ID**: `423RCYC29Y`
- **Issuer ID**: `a6c794e7-34a7-412d-8694-a630ed90701c`
- **Key File**: `AuthKey_423RCYC29Y.p8` (in project root, DO NOT commit)
- **App ID**: `6748970073`
- **Bundle ID**: `colemadden.Pente`
- **SKU**: `PenteForIMessage`
- **Team ID**: `SB4A7WG2KH`

**How to use**: Generate a JWT (ES256, 20min expiry, audience `appstoreconnect-v1`) and call `https://api.appstoreconnect.apple.com/v1/...` endpoints. Python example with `jwt` library works. `xcrun altool` also accepts `--apiKey` and `--apiIssuer` flags.

**Useful endpoints**:
- List apps: `GET /v1/apps`
- List builds: `GET /v1/builds?filter[app]={appId}&sort=-uploadedDate`
- Beta groups: `GET /v1/apps/{appId}/betaGroups`
- Beta testers: `GET /v1/betaTesters?filter[apps]={appId}`
- Upload builds: `xcrun altool --upload-app --type ios --file <ipa> --apiKey <key> --apiIssuer <issuer>`