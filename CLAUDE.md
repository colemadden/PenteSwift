# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an iOS iMessage extension app that implements the board game Pente. The app consists of:

- **Main app (Pente/)**: Simple placeholder app that directs users to use the iMessage extension
- **Messages extension (Pente MessagesExtension/)**: The actual game implementation that runs within iMessage

## Architecture

The codebase follows a modular Model-View pattern with SwiftUI. **Refactored December 2024** into atomic, testable modules:

### Core Modules (Pente MessagesExtension/)
- **`GameTypes.swift`**: Core game types (Player, GameState, WinMethod, GameMoveDelegate)
- **`GameBoard.swift`**: 19x19 board representation and basic operations
- **`CaptureEngine.swift`**: Isolated capture detection logic following Pente rules
- **`WinDetector.swift`**: Win condition checking (5-in-a-row and capture wins)
- **`GameStateEncoder.swift`**: URL encoding/decoding for game state persistence in iMessage
- **`BoardImageGenerator.swift`**: Image generation for message previews with theme support

### UI Layer
- **`PenteGameModel.swift`**: Orchestrates modules, reduced from 440+ to ~160 lines
- **`PenteGameView.swift`** + **`PenteBoardView.swift`**: SwiftUI views for game interface  
- **`MessagesViewController.swift`**: UIKit controller that hosts SwiftUI view in Messages extension

### Testing Suite
- **`PenteTests/`**: Comprehensive test suite with 275+ tests covering all game rules, edge cases, UI components, and defensive programming

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
# Use Xcode IDE (recommended for iMessage extensions)
# Test Navigator (⌘+6) → Run tests

# Command line (may have limitations with iMessage extension testing)
xcodebuild test -project Pente.xcodeproj -scheme PenteTests -destination "platform=iOS Simulator,name=iPhone 16"
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
- Use `MessagesViewController.swift:15` for move delegation between game model and Messages framework
- Board image generation in `BoardImageGenerator.swift` creates message previews with theme support
- Extension identifier: `com.apple.message-payload-provider` in `Info.plist`

### Modular Game Logic (Refactored Architecture)

- **Board**: 19x19 grid in `GameBoard.swift` with subscript access
- **Captures**: Isolated logic in `CaptureEngine.swift` with 8-direction detection
- **Win Detection**: Separated into `WinDetector.swift` for 5-in-a-row and capture wins
- **Game State**: URL encoding/decoding in `GameStateEncoder.swift`
- **Main Model**: `PenteGameModel.swift` now orchestrates modules vs implementing all logic

### Testing Strategy

- **Comprehensive Suite**: 275+ tests in `/PenteTests/` covering all game rules
- **Simulator Testing**: Fully functional for development and validation
- **Physical Device**: Required for final iMessage extension validation
- **Test Execution**: Use Xcode Test Navigator (⌘+6) for iMessage extension tests

### GitHub Integration

Repository: https://github.com/colemadden/PenteSwift.git
- All refactoring and icon fixes committed
- Test suite included in repository
- Use `git push` to sync changes to GitHub