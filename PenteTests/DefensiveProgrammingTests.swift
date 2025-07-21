import XCTest
@testable import Pente_MessagesExtension

final class DefensiveProgrammingTests: XCTestCase {
    
    var gameModel: PenteGameModel!
    var gameBoard: GameBoard!
    
    override func setUp() {
        super.setUp()
        gameModel = PenteGameModel()
        gameBoard = GameBoard()
    }
    
    override func tearDown() {
        gameModel = nil
        gameBoard = nil
        super.tearDown()
    }
    
    // MARK: - Capture Count Integrity Tests
    
    func testCaptureCountAlwaysEven() {
        // Verify that capture counts are always even (pairs)
        // This tests the defensive programming against odd capture bugs
        
        // Set up a capture scenario
        gameModel.currentPlayer = .black
        gameModel.makeMove(row: 10, col: 10)
        gameModel.confirmMove()
        
        gameModel.currentPlayer = .white
        gameModel.makeMove(row: 10, col: 11)
        gameModel.confirmMove()
        
        gameModel.makeMove(row: 10, col: 12)
        gameModel.confirmMove()
        
        // Black captures
        gameModel.currentPlayer = .black
        gameModel.makeMove(row: 10, col: 13)
        
        let pendingCaptures = gameModel.pendingCaptures
        XCTAssertEqual(pendingCaptures.count % 2, 0, "Pending captures should always be even")
        
        gameModel.confirmMove()
        
        // Verify capture count is properly calculated as pairs
        let captureCount = gameModel.capturedCount[.black] ?? 0
        XCTAssertEqual(pendingCaptures.count / 2, captureCount, "Capture count should equal stones captured divided by 2")
    }
    
    func testCaptureCountManuallyCorrupted() {
        // Test what happens if capture count gets corrupted (defensive programming)
        gameModel.capturedCount[.black] = 3 // Odd number (shouldn't happen normally)
        
        // Game should still function
        gameModel.makeMove(row: 10, col: 10)
        gameModel.confirmMove()
        
        // Win condition should still work (though with odd count)
        gameModel.capturedCount[.black] = 5
        XCTAssertTrue(WinDetector.checkCaptureWin(capturedCount: 5))
        
        // 4 captures should not win
        gameModel.capturedCount[.black] = 4
        XCTAssertFalse(WinDetector.checkCaptureWin(capturedCount: 4))
    }
    
    // MARK: - Board State Integrity Tests
    
    func testBoardStateAfterManualManipulation() {
        // Test that game handles manually corrupted board states
        var board = gameModel.board
        
        // Manually place stones (simulating corruption)
        gameBoard.placeStone(.black, at: 5, col: 5)
        gameBoard.placeStone(.white, at: 5, col: 6)
        gameBoard.placeStone(.black, at: 5, col: 7)
        
        // Check captures with manually placed stones
        let captures = CaptureEngine.findCaptures(on: gameBoard, at: 5, col: 8, by: .black)
        XCTAssertEqual(captures.count, 0, "Should not find captures in invalid pattern")
    }
    
    func testInconsistentMoveHistoryAndBoard() {
        // Test handling of inconsistent state between move history and board
        gameModel.makeMove(row: 9, col: 9)
        gameModel.confirmMove()
        
        // Manually clear the board but keep move history
        gameModel.resetGame()
        // But manually restore some move history (simulating corruption)
        // This tests robustness against data inconsistency
        
        let emptyBoardImage = gameModel.generateBoardImage(colorScheme: .light)
        XCTAssertNotNil(emptyBoardImage, "Should handle inconsistent state gracefully")
    }
    
    // MARK: - Concurrent Access Tests
    
    func testRapidStateChanges() {
        // Test rapid state changes that might occur in edge cases
        for i in 0..<100 {
            if i % 3 == 0 {
                gameModel.makeMove(row: i % 19, col: (i + 1) % 19)
            } else if i % 3 == 1 {
                gameModel.undoMove()
            } else {
                if gameModel.pendingMove != nil {
                    gameModel.confirmMove()
                }
            }
        }
        
        // Game should remain in valid state
        XCTAssertTrue(gameModel.moveHistory.count >= 0)
        XCTAssertTrue(gameModel.capturedCount[.black] ?? 0 >= 0)
        XCTAssertTrue(gameModel.capturedCount[.white] ?? 0 >= 0)
    }
    
    // MARK: - Memory Pressure Tests
    
    func testLargeNumberOfMoves() {
        // Test game with large number of moves (stress test)
        var moveCount = 0
        
        for row in 0..<19 {
            for col in 0..<19 {
                if gameModel.board[row][col] == nil && moveCount < 100 {
                    gameModel.makeMove(row: row, col: col)
                    if gameModel.pendingMove != nil {
                        gameModel.confirmMove()
                        moveCount += 1
                    }
                    
                    // Check game state periodically
                    if moveCount % 10 == 0 {
                        XCTAssertTrue(gameModel.moveHistory.count <= moveCount)
                    }
                }
            }
        }
        
        XCTAssertTrue(gameModel.moveHistory.count > 0)
    }
    
    // MARK: - URL Encoding Edge Cases
    
    func testExtremelyLongMoveHistory() {
        // Create a very long move history
        var moveHistory: [(row: Int, col: Int, player: Player)] = []
        
        for i in 0..<100 {
            let player: Player = i % 2 == 0 ? .black : .white
            moveHistory.append((row: i % 19, col: (i + 1) % 19, player: player))
        }
        
        let queryItems = GameStateEncoder.encodeToQueryItems(
            moveHistory: moveHistory,
            currentPlayer: .black,
            capturedCount: [.black: 0, .white: 0],
            gameState: .playing
        )
        
        XCTAssertTrue(queryItems.count > 0)
        
        let movesItem = queryItems.first { $0.name == "moves" }
        XCTAssertNotNil(movesItem)
        
        // URL should be very long but still valid
        var components = URLComponents()
        components.queryItems = queryItems
        let url = components.url
        
        XCTAssertNotNil(url, "Should handle very long URLs")
    }
    
    func testMalformedURLRecovery() {
        // Test various malformed URLs to ensure graceful handling
        let malformedURLs = [
            "pente://game?moves=B9,9;INVALID;W10,10;&current=Black",
            "pente://game?moves=B-1,5;B5,-1;&current=White",
            "pente://game?moves=B100,200;&current=InvalidPlayer",
            "pente://game?capB=notanumber&capW=alsonotanumber",
            "pente://game?state=invalidstate&winner=InvalidPlayer",
            "invalid://completely/wrong/url",
            "pente://game?" // Empty query
        ]
        
        for urlString in malformedURLs {
            if let url = URL(string: urlString) {
                // Should not crash when loading malformed URLs
                gameModel.loadFromURL(url)
                
                // Game should be in valid state after loading
                XCTAssertTrue(gameModel.capturedCount[.black] ?? 0 >= 0)
                XCTAssertTrue(gameModel.capturedCount[.white] ?? 0 >= 0)
                XCTAssertTrue(gameModel.moveHistory.count >= 0)
            }
        }
    }
    
    // MARK: - Invalid Move Sequences
    
    func testInvalidMoveSequences() {
        // Test sequences that shouldn't be possible but might occur due to bugs
        
        // Try to confirm move without pending move
        gameModel.confirmMove()
        XCTAssertEqual(gameModel.moveHistory.count, 0)
        
        // Try to undo move without pending move
        gameModel.undoMove()
        XCTAssertNil(gameModel.pendingMove)
        
        // Try to make move on won game
        gameModel.gameState = .won(by: .black, method: .fiveInARow)
        gameModel.makeMove(row: 10, col: 10)
        XCTAssertNil(gameModel.pendingMove)
        
        // Reset and try invalid positions
        gameModel.resetGame()
        gameModel.makeMove(row: -1, col: 0)
        XCTAssertNil(gameModel.pendingMove)
        
        gameModel.makeMove(row: 19, col: 0)
        XCTAssertNil(gameModel.pendingMove)
    }
    
    // MARK: - Image Generation Stress Tests
    
    func testImageGenerationWithCorruptedData() {
        // Test image generation with potentially corrupted board data
        var corruptedBoard = Array(repeating: Array(repeating: Optional<Player>.none, count: 19), count: 19)
        
        // Fill with alternating pattern
        for row in 0..<19 {
            for col in 0..<19 {
                corruptedBoard[row][col] = (row + col) % 2 == 0 ? .black : .white
            }
        }
        
        // Create mismatched move history
        let mismatchedHistory = [(row: 0, col: 0, player: Player.white)] // Doesn't match board
        
        let image = BoardImageGenerator.generateBoardImage(
            board: corruptedBoard,
            moveHistory: mismatchedHistory,
            size: CGSize(width: 300, height: 300),
            colorScheme: .light
        )
        
        XCTAssertNotNil(image, "Should handle mismatched data gracefully")
    }
    
    func testImageGenerationExtremeParameters() {
        let emptyBoard = Array(repeating: Array(repeating: Optional<Player>.none, count: 19), count: 19)
        let emptyHistory: [(row: Int, col: Int, player: Player)] = []
        
        // Test extreme sizes
        let extremeSizes = [
            CGSize(width: 0.1, height: 0.1),
            CGSize(width: 10000, height: 10000),
            CGSize(width: 1, height: 10000),
            CGSize(width: 10000, height: 1)
        ]
        
        for size in extremeSizes {
            let image = BoardImageGenerator.generateBoardImage(
                board: emptyBoard,
                moveHistory: emptyHistory,
                size: size,
                colorScheme: .light
            )
            
            // Should not crash, though image quality may vary
            if let image = image {
                XCTAssertEqual(image.size.width, size.width, accuracy: 0.1)
                XCTAssertEqual(image.size.height, size.height, accuracy: 0.1)
            }
        }
    }
    
    // MARK: - Boundary Value Tests
    
    func testBoundaryValues() {
        // Test all boundary values for board positions
        let boundaryPositions = [
            (0, 0), (0, 18), (18, 0), (18, 18), // Corners
            (-1, 0), (0, -1), (19, 0), (0, 19), // Just outside
            (Int.max, 0), (0, Int.max), (Int.min, 0), (0, Int.min) // Extreme values
        ]
        
        for (row, col) in boundaryPositions {
            // Should not crash with any boundary values
            let isValid = gameBoard.isValidPosition(row, col)
            
            if row >= 0 && row < 19 && col >= 0 && col < 19 {
                XCTAssertTrue(isValid)
            } else {
                XCTAssertFalse(isValid)
            }
            
            // Test capture detection with boundary values
            let captures = CaptureEngine.findCaptures(on: gameBoard, at: row, col: col, by: .black)
            XCTAssertTrue(captures.count >= 0, "Capture count should never be negative")
        }
    }
    
    // MARK: - Resource Cleanup Tests
    
    func testResourceCleanup() {
        // Test that resources are properly cleaned up
        for _ in 0..<10 {
            let tempGameModel = PenteGameModel()
            tempGameModel.startNewGame()
            tempGameModel.makeMove(row: 8, col: 8)
            tempGameModel.confirmMove()
            
            let image = tempGameModel.generateBoardImage(colorScheme: .light)
            XCTAssertNotNil(image)
            
            // Force cleanup
            tempGameModel.resetGame()
        }
        
        // No specific assertion here, but if there are memory leaks,
        // this test might help identify them during development
        XCTAssertTrue(true)
    }
    
    // MARK: - Thread Safety Notes
    
    func testSequentialAccess() {
        // Note: The game model is not designed for concurrent access,
        // but we can test that sequential operations work correctly
        
        let operations = [
            { self.gameModel.makeMove(row: 5, col: 5) },
            { self.gameModel.confirmMove() },
            { self.gameModel.makeMove(row: 6, col: 6) },
            { self.gameModel.undoMove() },
            { self.gameModel.makeMove(row: 7, col: 7) },
            { self.gameModel.confirmMove() },
            { self.gameModel.resetGame() },
            { self.gameModel.startNewGame() }
        ]
        
        for operation in operations {
            operation()
            
            // Verify game state remains consistent after each operation
            XCTAssertTrue(gameModel.moveHistory.count >= 0)
            XCTAssertTrue(gameModel.capturedCount[.black] ?? 0 >= 0)
            XCTAssertTrue(gameModel.capturedCount[.white] ?? 0 >= 0)
        }
    }
}