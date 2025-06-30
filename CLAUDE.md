# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an iOS iMessage extension app that implements the board game Pente. The app consists of:

- **Main app (Pente/)**: Simple placeholder app that directs users to use the iMessage extension
- **Messages extension (Pente MessagesExtension/)**: The actual game implementation that runs within iMessage

## Architecture

The codebase follows a Model-View pattern with SwiftUI:

- `PenteGameModel`: Core game logic using `@ObservableObject` pattern
- `PenteGameView` + `PenteBoardView`: SwiftUI views for the game interface  
- `MessagesViewController`: UIKit controller that hosts the SwiftUI view in the Messages extension

### Key Features

- **Game State Encoding**: Game state is encoded into URL query parameters for sharing between devices via messages
- **Two-Step Move System**: Players place stones tentatively, then confirm/undo before sending to opponent
- **Capture System**: Implements Pente's capture rules (sandwich opponent stones between your own)
- **Win Conditions**: Five in a row OR capturing 5 pairs (10 stones) of opponent
- **Theme Support**: Automatic light/dark mode support with theme-aware colors

## Build Commands

This is a standard Xcode project - build using:
- Xcode GUI: Product → Build (⌘+B)
- Command line: `xcodebuild -project Pente.xcodeproj -scheme Pente build`

## Development Notes

### Messages Extension Specifics

- Game state persists through message URL encoding/decoding
- The extension runs in a sandboxed environment within iMessage
- Use `MessagesViewController.swift:15` for move delegation between game model and Messages framework
- Board image generation in `PenteGameModel.swift:301` creates message previews

### Game Logic

- Board is 19x19 grid stored in `PenteGameModel.swift:27`
- Move validation and capture logic in `checkCaptures()` at `PenteGameModel.swift:213`
- Win detection in `checkFiveInARow()` at `PenteGameModel.swift:245`

### Testing on Device

When testing on physical devices, ensure:
1. Proper code signing certificates are configured
2. The Messages extension target has valid provisioning profiles
3. The extension bundle ID matches your developer team settings

The extension identifier is `com.apple.message-payload-provider` as defined in `Info.plist:10`.