# Setting Up Tests for Pente iMessage Extension

## Current Situation
The test files have been moved to `/PenteTests/` but need proper Xcode project integration.

## Quick Solution (Immediate Testing)
I've created `GameTester.swift` in your Messages Extension folder. You can:

1. **Add to your project**: Drag `GameTester.swift` into your Xcode project
2. **Run tests**: Call `GameTester.runAllTests()` from your app (e.g., in `viewDidLoad`)
3. **Check console**: View test results in Xcode's debug console

Example usage in MessagesViewController:
```swift
override func viewDidLoad() {
    super.viewDidLoad()
    setupGameView()
    
    #if DEBUG
    GameTester.runAllTests() // Run tests in debug builds only
    #endif
}
```

## Proper Solution (Full XCTest Integration)

### Step 1: Add Test Target in Xcode
1. Open `Pente.xcodeproj` in Xcode
2. Go to **File → New → Target**
3. Choose **iOS → Test → Unit Testing Bundle**
4. Name it "PenteTests"
5. Set Target to be Tested: **Pente MessagesExtension**
6. Click **Finish**

### Step 2: Configure Test Target
1. Select the **PenteTests** target
2. Go to **Build Settings**
3. Set **Test Host** to: `$(BUILT_PRODUCTS_DIR)/Pente MessagesExtension.appex/Pente MessagesExtension`
4. Set **Bundle Loader** to: `$(TEST_HOST)`

### Step 3: Add Test Files
1. In Xcode, right-click the **PenteTests** group
2. Choose **Add Files to "Pente"**
3. Navigate to `/PenteTests/` folder
4. Select all `.swift` files
5. Make sure they're added to the **PenteTests** target only

### Step 4: Fix Import Statements
The test files currently have:
```swift
@testable import Pente_MessagesExtension
```

You may need to change this to match your actual module name. Check your:
- **Product Module Name** in Build Settings
- **Bundle Identifier** 

It might need to be:
```swift
@testable import Pente_MessagesExtension
// OR
@testable import PenteMessagesExtension  
// OR whatever your actual module name is
```

### Step 5: Run Tests
- **Keyboard shortcut**: ⌘+U
- **Menu**: Product → Test
- **Test Navigator**: ⌘+6, then click the play button

## Test Coverage Summary

The test suite includes:

### Core Game Logic (175+ tests)
- ✅ **GameBoard**: Position validation, stone placement, edge cases
- ✅ **CaptureEngine**: All Pente capture rules, multi-direction captures  
- ✅ **WinDetector**: Five-in-a-row, capture wins, boundary conditions
- ✅ **GameStateEncoder**: URL encoding/decoding, data persistence
- ✅ **PenteGameModel**: Complete game flow integration

### UI & Integration (60+ tests)
- ✅ **MessagesViewController**: iMessage integration, message lifecycle
- ✅ **BoardImageGenerator**: Image generation, themes, performance
- ✅ **PenteGameView**: SwiftUI components, state management
- ✅ **GameTypes**: Core data types, serialization

### Robustness (40+ tests)
- ✅ **DefensiveProgramming**: Error handling, edge cases, corrupted data
- ✅ **Performance**: Memory usage, large game states
- ✅ **Integration**: End-to-end game flows

## Troubleshooting

### "No such module" Error
- Check the module name in Build Settings
- Ensure test target can access the main target
- Verify Bundle Loader and Test Host settings

### "Symbol not found" Error  
- Make sure classes/structs are `public` or `internal` (not `private`)
- Check that files are added to the correct target

### Tests Don't Run
- Verify the test target scheme is selected
- Check that test files are in the test target membership
- Ensure the main app builds successfully first

## Alternative: Simple Assert-Based Testing
If XCTest setup proves difficult, you can use the `GameTester` approach:

```swift
// In your app delegate or view controller
#if DEBUG
GameTester.runAllTests()
GameTester.testCompleteGameFlow()
#endif
```

This provides immediate feedback during development without requiring full test target setup.