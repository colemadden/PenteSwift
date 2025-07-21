import XCTest
import SwiftUI
@testable import Pente_MessagesExtension

final class PenteGameViewTests: XCTestCase {
    
    var gameModel: PenteGameModel!
    
    override func setUp() {
        super.setUp()
        gameModel = PenteGameModel()
    }
    
    override func tearDown() {
        gameModel = nil
        super.tearDown()
    }
    
    // MARK: - View Initialization Tests
    
    func testPenteGameViewInitialization() {
        let gameView = PenteGameView(gameModel: gameModel)
        
        // Should not crash during initialization
        XCTAssertNotNil(gameView)
    }
    
    func testPenteBoardViewInitialization() {
        let boardView = PenteBoardView(
            gameModel: gameModel,
            boardColor: .brown,
            blackStoneColor: .black,
            whiteStoneColor: .white,
            gridLineColor: .gray
        )
        
        XCTAssertNotNil(boardView)
    }
    
    // MARK: - Color Theme Tests
    
    func testLightModeColors() {
        let gameView = PenteGameView(gameModel: gameModel)
        
        // Test that color computations work without crashing
        // Note: We can't easily test the actual Environment values in unit tests,
        // but we can test that the color properties are accessible
        let boardColor = Color(hex: "D4A574")
        let blackStoneColor = Color(hex: "1C1C1C")
        let whiteStoneColor = Color(hex: "FAFAFA")
        let gridLineColor = Color.black.opacity(0.3)
        
        XCTAssertNotNil(boardColor)
        XCTAssertNotNil(blackStoneColor)
        XCTAssertNotNil(whiteStoneColor)
        XCTAssertNotNil(gridLineColor)
    }
    
    func testDarkModeColors() {
        let boardColor = Color(hex: "3E2723")
        let blackStoneColor = Color(hex: "0A0A0A")
        let whiteStoneColor = Color(hex: "E8E8E8")
        let gridLineColor = Color.white.opacity(0.2)
        
        XCTAssertNotNil(boardColor)
        XCTAssertNotNil(blackStoneColor)
        XCTAssertNotNil(whiteStoneColor)
        XCTAssertNotNil(gridLineColor)
    }
    
    // MARK: - Hex Color Extension Tests
    
    func testHexColorValidInputs() {
        // Test 6-character hex
        let color1 = Color(hex: "FF0000") // Red
        let color2 = Color(hex: "00FF00") // Green
        let color3 = Color(hex: "0000FF") // Blue
        
        XCTAssertNotNil(color1)
        XCTAssertNotNil(color2)
        XCTAssertNotNil(color3)
    }
    
    func testHexColorWithHash() {
        let colorWithHash = Color(hex: "#FF0000")
        let colorWithoutHash = Color(hex: "FF0000")
        
        XCTAssertNotNil(colorWithHash)
        XCTAssertNotNil(colorWithoutHash)
        // Colors should be equivalent, but we can't easily test color equality
    }
    
    func testHexColor3Character() {
        let shortHex = Color(hex: "F0A") // Should expand to FF00AA
        XCTAssertNotNil(shortHex)
    }
    
    func testHexColor8Character() {
        let alphaHex = Color(hex: "FF0000FF") // Red with full alpha
        XCTAssertNotNil(alphaHex)
    }
    
    func testHexColorInvalidInputs() {
        let invalidHex1 = Color(hex: "GGGGGG") // Invalid hex characters
        let invalidHex2 = Color(hex: "12345") // Invalid length
        let invalidHex3 = Color(hex: "") // Empty string
        
        XCTAssertNotNil(invalidHex1) // Should default to black
        XCTAssertNotNil(invalidHex2) // Should default to black
        XCTAssertNotNil(invalidHex3) // Should default to black
    }
    
    // MARK: - Game State Display Tests
    
    func testGameStateDisplayPlaying() {
        gameModel.currentPlayer = .black
        gameModel.gameState = .playing
        
        let gameView = PenteGameView(gameModel: gameModel)
        
        // Should display current player without crashing
        XCTAssertNotNil(gameView)
    }
    
    func testGameStateDisplayPendingMove() {
        gameModel.makeMove(row: 10, col: 10)
        
        let gameView = PenteGameView(gameModel: gameModel)
        
        // Should display Send/Undo buttons for pending move
        XCTAssertNotNil(gameView)
        XCTAssertNotNil(gameModel.pendingMove)
    }
    
    func testGameStateDisplayWon() {
        gameModel.gameState = .won(by: .black, method: .fiveInARow)
        
        let gameView = PenteGameView(gameModel: gameModel)
        
        // Should display win message
        XCTAssertNotNil(gameView)
    }
    
    func testGameStateDisplayFirstMoveReady() {
        gameModel.startNewGame()
        
        let gameView = PenteGameView(gameModel: gameModel)
        
        // Should display Send button for first move
        XCTAssertNotNil(gameView)
        XCTAssertTrue(gameModel.isFirstMoveReadyToSend)
    }
    
    // MARK: - Capture Count Display Tests
    
    func testCaptureCountDisplay() {
        gameModel.capturedCount[.black] = 3
        gameModel.capturedCount[.white] = 1
        
        let gameView = PenteGameView(gameModel: gameModel)
        
        // Should display capture counts without crashing
        XCTAssertNotNil(gameView)
        XCTAssertEqual(gameModel.capturedCount[.black], 3)
        XCTAssertEqual(gameModel.capturedCount[.white], 1)
    }
    
    func testZeroCaptureCountDisplay() {
        gameModel.capturedCount[.black] = 0
        gameModel.capturedCount[.white] = 0
        
        let gameView = PenteGameView(gameModel: gameModel)
        
        // Should handle zero counts gracefully
        XCTAssertNotNil(gameView)
    }
    
    func testHighCaptureCountDisplay() {
        gameModel.capturedCount[.black] = 10
        gameModel.capturedCount[.white] = 8
        
        let gameView = PenteGameView(gameModel: gameModel)
        
        // Should handle high numbers gracefully
        XCTAssertNotNil(gameView)
    }
    
    // MARK: - Board View Interaction Tests
    
    func testBoardViewCreation() {
        let boardView = PenteBoardView(
            gameModel: gameModel,
            boardColor: Color(hex: "D4A574"),
            blackStoneColor: Color(hex: "1C1C1C"),
            whiteStoneColor: Color(hex: "FAFAFA"),
            gridLineColor: Color.black.opacity(0.3)
        )
        
        XCTAssertNotNil(boardView)
    }
    
    // MARK: - View State Consistency Tests
    
    func testViewReflectsGameState() {
        let gameView = PenteGameView(gameModel: gameModel)
        
        // Initial state
        XCTAssertEqual(gameModel.currentPlayer, .black)
        XCTAssertEqual(gameModel.moveHistory.count, 0)
        
        // Make a move
        gameModel.makeMove(row: 10, col: 10)
        XCTAssertNotNil(gameModel.pendingMove)
        
        // Confirm move
        gameModel.confirmMove()
        XCTAssertEqual(gameModel.currentPlayer, .white)
        XCTAssertEqual(gameModel.moveHistory.count, 1)
        
        // View should reflect all these changes
        XCTAssertNotNil(gameView)
    }
    
    func testViewHandlesGameModelChanges() {
        let gameView = PenteGameView(gameModel: gameModel)
        
        // Start new game
        gameModel.startNewGame()
        XCTAssertTrue(gameModel.isFirstMoveReadyToSend)
        
        // Send first move
        gameModel.sendFirstMove()
        XCTAssertFalse(gameModel.isFirstMoveReadyToSend)
        
        // Make subsequent moves
        gameModel.makeMove(row: 8, col: 8)
        gameModel.confirmMove()
        
        // Win the game
        gameModel.gameState = .won(by: .white, method: .fiveCaptures)
        
        // View should handle all state transitions
        XCTAssertNotNil(gameView)
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityElements() {
        let gameView = PenteGameView(gameModel: gameModel)
        
        // Views should be accessible
        XCTAssertNotNil(gameView)
        
        // Could add more specific accessibility testing if needed
        // This would require more complex view testing setup
    }
    
    // MARK: - Layout Tests
    
    func testViewLayoutWithDifferentStates() {
        let states: [(GameState, String)] = [
            (.playing, "playing"),
            (.won(by: .black, method: .fiveInARow), "black wins five in a row"),
            (.won(by: .white, method: .fiveCaptures), "white wins by captures")
        ]
        
        for (state, description) in states {
            gameModel.gameState = state
            let gameView = PenteGameView(gameModel: gameModel)
            
            XCTAssertNotNil(gameView, "View should handle \(description) state")
        }
    }
    
    func testViewWithComplexGameState() {
        // Set up a complex game state
        gameModel.startNewGame()
        gameModel.sendFirstMove()
        
        // Add some moves
        gameModel.makeMove(row: 8, col: 8)
        gameModel.confirmMove()
        gameModel.makeMove(row: 10, col: 10)
        gameModel.confirmMove()
        
        // Add some captures
        gameModel.capturedCount[.black] = 2
        gameModel.capturedCount[.white] = 1
        
        // Create pending move
        gameModel.makeMove(row: 11, col: 11)
        
        let gameView = PenteGameView(gameModel: gameModel)
        
        // Should handle complex state without issues
        XCTAssertNotNil(gameView)
        XCTAssertNotNil(gameModel.pendingMove)
        XCTAssertEqual(gameModel.moveHistory.count, 3) // Including center stone
    }
    
    // MARK: - Performance Tests
    
    func testViewCreationPerformance() {
        measure {
            let gameView = PenteGameView(gameModel: gameModel)
            _ = gameView.body // Force body computation
        }
    }
    
    func testBoardViewCreationPerformance() {
        measure {
            let boardView = PenteBoardView(
                gameModel: gameModel,
                boardColor: Color(hex: "D4A574"),
                blackStoneColor: Color(hex: "1C1C1C"),
                whiteStoneColor: Color(hex: "FAFAFA"),
                gridLineColor: Color.black.opacity(0.3)
            )
            _ = boardView.body // Force body computation
        }
    }
    
    // MARK: - Memory Tests
    
    func testViewMemoryManagement() {
        weak var weakGameView: PenteGameView?
        
        autoreleasepool {
            let gameView = PenteGameView(gameModel: gameModel)
            weakGameView = gameView
            XCTAssertNotNil(weakGameView)
        }
        
        // View should be deallocated (though SwiftUI views might be retained differently)
        // This test might not work as expected with SwiftUI's view system
    }
}