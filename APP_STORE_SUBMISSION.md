# App Store Submission Guide - Version 1.0 (Build 2)

## What Was Done

✅ **Version bumped**: 1.0 (Build 1) → 1.0 (Build 2)
✅ **Bug fixes committed and pushed** to GitHub
✅ **Build artifacts cleaned**

## Critical Bug Fixes in This Build

### Player Assignment System
- **Fixed**: Players could make moves for both colors in multiplayer games
- **Added**: UUID-based player tracking to identify who controls which color
- **Added**: Turn-based move enforcement (canMakeMove/waitingForOpponent)

### Game State Improvements
- **Fixed**: Game state now properly tracks which player started the game
- **Added**: Player roles persist across message sends and app restarts
- **Added**: "Waiting for opponent" UI indicator

### Visual Improvements
- **Added**: Dynamic board images that adapt to light/dark mode for each viewer
- **Improved**: Turn indicator now shows "Your turn" instead of generic color names

## How to Build & Submit (Use Xcode GUI)

### Step 1: Open in Xcode
```bash
open Pente.xcodeproj
```

### Step 2: Archive the Build
1. Select **Product > Archive** from menu bar
2. Wait for archive to complete (2-3 minutes)
3. Xcode Organizer will open automatically

### Step 3: Distribute to App Store
1. In Organizer, select the new archive (Build 2)
2. Click **Distribute App**
3. Choose **App Store Connect**
4. Select **Upload**
5. Choose automatic signing
6. Click **Upload**

### Step 4: Submit in App Store Connect
1. Go to https://appstoreconnect.apple.com
2. Select **Pente** app
3. Create a new version or update existing
4. Add "What's New" text (see below)
5. Submit for review

## What's New Text (Copy to App Store Connect)

```
Bug Fixes and Improvements

• Fixed critical multiplayer issue where any player could make moves for both colors
• Added proper turn-based gameplay enforcement
• Improved game state tracking across devices
• Added "Waiting for opponent" indicator for better clarity
• Board previews now automatically adapt to light/dark mode preferences

This update ensures fair two-player gameplay in iMessage conversations.
```

## Alternative "What's New" (More User-Friendly)

```
Multiplayer Fixes

Now you can properly play Pente with friends! This update fixes an issue where players could accidentally move for both colors.

What's Fixed:
• Two-player turn enforcement works correctly
• Clear "waiting for opponent" messages
• Board previews look great in both light and dark mode
• Game state saves properly between moves

Enjoy fair games with your friends!
```

## Version Info
- **Marketing Version**: 1.0
- **Build Number**: 2
- **Bundle ID**: colemadden.Pente / colemadden.Pente.MessagesExtension
- **Team ID**: SB4A7WG2KH
- **Min iOS**: 18.5 (consider lowering for broader compatibility)

## Files Changed in This Update
- PenteGameModel.swift
- MessagesViewController.swift
- GameStateEncoder.swift
- PenteGameView.swift
- Plus 100+ new unit tests

## Notes
- Clean build artifacts have been removed
- Version number already updated in project file
- All changes committed to git (commit ec3b909)
- iMessage extension icon format issue still pending (safe to defer)
