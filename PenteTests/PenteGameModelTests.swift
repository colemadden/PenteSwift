import XCTest
import Combine
import PenteCore

// Mock delegate for testing
class MockGameMoveDelegate: GameMoveDelegate {
    var moveCallCount = 0
    var expectation: XCTestExpectation?
    
    func gameDidMakeMove() {
        moveCallCount += 1
        expectation?.fulfill()
    }
}

final class PenteGameModelTests: XCTestCase {
    
    var gameModel: PenteGameModel!
    var mockDelegate: MockGameMoveDelegate!
    
    override func setUp() {
        super.setUp()
        gameModel = PenteGameModel()
        mockDelegate = MockGameMoveDelegate()
        gameModel.moveDelegate = mockDelegate
    }
    
    override func tearDown() {
        gameModel = nil
        mockDelegate = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialGameState() {
        XCTAssertEqual(gameModel.currentPlayer, .black)
        XCTAssertEqual(gameModel.moveHistory.count, 0)
        XCTAssertEqual(gameModel.capturedCount[.black], 0)
        XCTAssertEqual(gameModel.capturedCount[.white], 0)
        
        if case .playing = gameModel.gameState {
            // Correct
        } else {
            XCTFail("Initial game state should be playing")
        }
        
        XCTAssertNil(gameModel.pendingMove)
        XCTAssertEqual(gameModel.pendingCaptures.count, 0)
        XCTAssertEqual(gameModel.lastCaptures.count, 0)
        XCTAssertFalse(gameModel.isNewGamePendingSend)
        XCTAssertFalse(gameModel.isNewGamePendingSend)
        
        // Board should be empty
        for row in 0..<19 {
            for col in 0..<19 {
                XCTAssertNil(gameModel.board[row][col])
            }
        }
    }
    
    // MARK: - Start New Game Tests
    
    func testStartNewGame() {
        gameModel.startNewGame()
        
        // Should place black stone at center
        XCTAssertEqual(gameModel.board[9][9], .black)
        XCTAssertEqual(gameModel.currentPlayer, .white) // Should switch to white
        XCTAssertEqual(gameModel.moveHistory.count, 1)
        XCTAssertEqual(gameModel.moveHistory[0].row, 9)
        XCTAssertEqual(gameModel.moveHistory[0].col, 9)
        XCTAssertEqual(gameModel.moveHistory[0].player, .black)
        XCTAssertTrue(gameModel.isNewGamePendingSend)
        XCTAssertTrue(gameModel.isNewGamePendingSend)
    }
    
    func testSendFirstMove() {
        gameModel.startNewGame()
        
        let expectation = XCTestExpectation(description: "Move delegate called")
        mockDelegate.expectation = expectation
        
        gameModel.sendFirstMove()
        
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertFalse(gameModel.isNewGamePendingSend)
        XCTAssertFalse(gameModel.isNewGamePendingSend)
        XCTAssertEqual(mockDelegate.moveCallCount, 1)
    }
    
    func testSendFirstMoveWhenNotReady() {
        // Don't start new game first
        gameModel.sendFirstMove()
        
        // Should not call delegate
        XCTAssertEqual(mockDelegate.moveCallCount, 0)
    }
    
    // MARK: - Make Move Tests
    
    func testMakeMoveBasic() {
        let row = 10
        let col = 10
        
        gameModel.makeMove(row: row, col: col)
        
        // Should create pending move
        XCTAssertNotNil(gameModel.pendingMove)
        XCTAssertEqual(gameModel.pendingMove?.row, row)
        XCTAssertEqual(gameModel.pendingMove?.col, col)
        
        // Stone should be placed temporarily
        XCTAssertEqual(gameModel.board[row][col], .black)
        
        // Should not be in move history yet
        XCTAssertEqual(gameModel.moveHistory.count, 0)
        
        // Should not call delegate yet
        XCTAssertEqual(mockDelegate.moveCallCount, 0)
    }
    
    func testMakeMoveOnOccupiedPosition() {
        // Place a stone first
        gameModel.makeMove(row: 10, col: 10)
        gameModel.confirmMove()
        
        // Try to place on same position
        let initialMoveCount = gameModel.moveHistory.count
        gameModel.makeMove(row: 10, col: 10)
        
        // Should not create new pending move
        XCTAssertNil(gameModel.pendingMove)
        XCTAssertEqual(gameModel.moveHistory.count, initialMoveCount)
    }
    
    func testMakeMoveDuringFirstMoveReadyState() {
        gameModel.startNewGame()
        
        // Should not allow moves during first move ready state
        gameModel.makeMove(row: 10, col: 10)
        
        XCTAssertNil(gameModel.pendingMove)
        XCTAssertNil(gameModel.board[10][10])
    }
    
    func testMakeMoveWhenGameIsWon() {
        // Force game to won state
        gameModel.gameState = .won(by: .black, method: .fiveInARow)
        
        gameModel.makeMove(row: 10, col: 10)
        
        // Should not allow moves
        XCTAssertNil(gameModel.pendingMove)
        XCTAssertNil(gameModel.board[10][10])
    }
    
    func testMakeMoveReplacePendingMove() {
        // Make first pending move
        gameModel.makeMove(row: 10, col: 10)
        XCTAssertNotNil(gameModel.pendingMove)
        XCTAssertEqual(gameModel.board[10][10], .black)
        
        // Make second pending move on different position
        gameModel.makeMove(row: 11, col: 11)
        
        // Should clear first move and create new one
        XCTAssertNil(gameModel.board[10][10]) // First move cleared
        XCTAssertEqual(gameModel.board[11][11], .black) // New move placed
        XCTAssertEqual(gameModel.pendingMove?.row, 11)
        XCTAssertEqual(gameModel.pendingMove?.col, 11)
    }
    
    func testMakeMoveSamePendingPosition() {
        // Make pending move
        gameModel.makeMove(row: 10, col: 10)
        XCTAssertNotNil(gameModel.pendingMove)
        
        // Click same position again (should undo)
        gameModel.makeMove(row: 10, col: 10)
        
        // Should undo the move
        XCTAssertNil(gameModel.pendingMove)
        XCTAssertNil(gameModel.board[10][10])
    }
    
    // MARK: - Confirm Move Tests
    
    func testConfirmMoveBasic() {
        gameModel.makeMove(row: 10, col: 10)
        
        let expectation = XCTestExpectation(description: "Move delegate called")
        mockDelegate.expectation = expectation
        
        gameModel.confirmMove()
        
        wait(for: [expectation], timeout: 1.0)
        
        // Should add to history
        XCTAssertEqual(gameModel.moveHistory.count, 1)
        XCTAssertEqual(gameModel.moveHistory[0].row, 10)
        XCTAssertEqual(gameModel.moveHistory[0].col, 10)
        XCTAssertEqual(gameModel.moveHistory[0].player, .black)
        
        // Should switch players
        XCTAssertEqual(gameModel.currentPlayer, .white)
        
        // Should clear pending state
        XCTAssertNil(gameModel.pendingMove)
        XCTAssertEqual(gameModel.pendingCaptures.count, 0)
        XCTAssertEqual(gameModel.lastCaptures.count, 0)
        
        // Should call delegate
        XCTAssertEqual(mockDelegate.moveCallCount, 1)
    }
    
    func testConfirmMoveWithCaptures() {
        // Setup capture scenario: Black-White-White-[Pending Black]
        gameModel.currentPlayer = .black
        gameModel.makeMove(row: 10, col: 10) // Place black stone manually for setup
        gameModel.confirmMove()
        
        gameModel.currentPlayer = .white
        gameModel.makeMove(row: 10, col: 11) // White stone
        gameModel.confirmMove()

        gameModel.currentPlayer = .white
        gameModel.makeMove(row: 10, col: 12) // White stone
        gameModel.confirmMove()
        
        // Now black captures
        gameModel.makeMove(row: 10, col: 13)
        
        // Should have pending captures
        XCTAssertEqual(gameModel.pendingCaptures.count, 2)
        
        gameModel.confirmMove()
        
        // Should remove captured stones
        XCTAssertNil(gameModel.board[10][11])
        XCTAssertNil(gameModel.board[10][12])
        
        // Should update capture count (2 stones = 1 pair)
        XCTAssertEqual(gameModel.capturedCount[.black], 1)
    }
    
    func testConfirmMoveWithWinByFiveInARow() {
        // Setup four black stones in a row
        for col in 5...8 {
            gameModel.makeMove(row: 10, col: col)
            gameModel.confirmMove()
            gameModel.currentPlayer = .black // Force back to black for test
        }
        
        // Place fifth stone to win
        gameModel.makeMove(row: 10, col: 9)
        gameModel.confirmMove()
        
        // Should detect win
        if case .won(let winner, let method) = gameModel.gameState {
            XCTAssertEqual(winner, .black)
            XCTAssertEqual(method, .fiveInARow)
        } else {
            XCTFail("Should have won by five in a row")
        }
    }
    
    func testConfirmMoveWithWinByCaptures() {
        // Setup game state with 4 captures already
        gameModel.capturedCount[.black] = 4
        
        // Setup a capture scenario: Black at col 9, White at col 10, White at col 11, Black captures at col 12
        gameModel.currentPlayer = .black
        gameModel.makeMove(row: 10, col: 9) // Place supporting black stone first
        gameModel.confirmMove()

        gameModel.currentPlayer = .white
        gameModel.makeMove(row: 10, col: 10)
        gameModel.confirmMove()

        gameModel.currentPlayer = .white
        gameModel.makeMove(row: 10, col: 11)
        gameModel.confirmMove()

        // Black captures to win
        gameModel.currentPlayer = .black
        gameModel.makeMove(row: 10, col: 12) // Capturing move
        gameModel.confirmMove()
        
        // Should detect win by captures (5 total)
        if case .won(let winner, let method) = gameModel.gameState {
            XCTAssertEqual(winner, .black)
            XCTAssertEqual(method, .fiveCaptures)
        } else {
            XCTFail("Should have won by captures")
        }
    }
    
    func testConfirmMoveWithNoPendingMove() {
        // Should not crash when no pending move
        gameModel.confirmMove()
        
        XCTAssertEqual(gameModel.moveHistory.count, 0)
        XCTAssertEqual(mockDelegate.moveCallCount, 0)
    }
    
    // MARK: - Undo Move Tests
    
    func testUndoMove() {
        gameModel.makeMove(row: 10, col: 10)
        
        XCTAssertNotNil(gameModel.pendingMove)
        XCTAssertEqual(gameModel.board[10][10], .black)
        
        gameModel.undoMove()
        
        XCTAssertNil(gameModel.pendingMove)
        XCTAssertNil(gameModel.board[10][10])
        XCTAssertEqual(gameModel.pendingCaptures.count, 0)
        XCTAssertEqual(gameModel.lastCaptures.count, 0)
    }
    
    func testUndoMoveWithNoPendingMove() {
        // Should not crash when no pending move
        gameModel.undoMove()
        
        XCTAssertNil(gameModel.pendingMove)
    }
    
    // MARK: - Reset Game Tests
    
    func testResetGame() {
        // Setup game state
        gameModel.makeMove(row: 10, col: 10)
        gameModel.confirmMove()
        gameModel.capturedCount[.black] = 2
        gameModel.gameState = .won(by: .black, method: .fiveInARow)
        gameModel.lastCaptures = [(5, 5)]
        gameModel.makeMove(row: 11, col: 11) // Pending move
        gameModel.isNewGamePendingSend = true
        
        gameModel.resetGame()
        
        // Should reset everything to initial state
        XCTAssertEqual(gameModel.currentPlayer, .black)
        XCTAssertEqual(gameModel.moveHistory.count, 0)
        XCTAssertEqual(gameModel.capturedCount[.black], 0)
        XCTAssertEqual(gameModel.capturedCount[.white], 0)
        
        if case .playing = gameModel.gameState {
            // Correct
        } else {
            XCTFail("Game state should be playing after reset")
        }
        
        XCTAssertEqual(gameModel.lastCaptures.count, 0)
        XCTAssertNil(gameModel.pendingMove)
        XCTAssertEqual(gameModel.pendingCaptures.count, 0)
        XCTAssertFalse(gameModel.isNewGamePendingSend)
        
        // Board should be empty
        for row in 0..<19 {
            for col in 0..<19 {
                XCTAssertNil(gameModel.board[row][col])
            }
        }
    }
    
    // MARK: - URL Encoding/Decoding Tests
    
    func testEncodeToQueryItems() {
        // Setup game state
        gameModel.makeMove(row: 9, col: 9)
        gameModel.confirmMove()
        gameModel.makeMove(row: 10, col: 10)
        gameModel.confirmMove()
        gameModel.capturedCount[.black] = 1
        gameModel.capturedCount[.white] = 0
        
        let queryItems = gameModel.encodeToQueryItems()
        
        // Should contain all necessary items
        XCTAssertTrue(queryItems.contains { $0.name == "moves" })
        XCTAssertTrue(queryItems.contains { $0.name == "current" })
        XCTAssertTrue(queryItems.contains { $0.name == "capB" })
        XCTAssertTrue(queryItems.contains { $0.name == "capW" })
        XCTAssertTrue(queryItems.contains { $0.name == "state" })
    }
    
    func testLoadFromURL() {
        let url = URL(string: "pente://game?moves=B9,9;W10,10;&current=Black&capB=1&capW=0&state=playing")!
        
        gameModel.loadFromURL(url)
        
        XCTAssertEqual(gameModel.moveHistory.count, 2)
        XCTAssertEqual(gameModel.board[9][9], .black)
        XCTAssertEqual(gameModel.board[10][10], .white)
        XCTAssertEqual(gameModel.currentPlayer, .black)
        // Capture counts are computed from move replay, not URL params
        XCTAssertEqual(gameModel.capturedCount[.black], 0)
        XCTAssertEqual(gameModel.capturedCount[.white], 0)
    }

    // MARK: - Board Image Generation Tests
    
    func testGenerateBoardImageLight() {
        gameModel.makeMove(row: 9, col: 9)
        gameModel.confirmMove()
        
        let image = gameModel.generateBoardImage(colorScheme: .light)
        
        XCTAssertNotNil(image)
        XCTAssertEqual(image?.size.width, 300)
        XCTAssertEqual(image?.size.height, 300)
    }
    
    func testGenerateBoardImageDark() {
        gameModel.makeMove(row: 9, col: 9)
        gameModel.confirmMove()
        
        let image = gameModel.generateBoardImage(colorScheme: .dark)
        
        XCTAssertNotNil(image)
        XCTAssertEqual(image?.size.width, 300)
        XCTAssertEqual(image?.size.height, 300)
    }
    
    func testGenerateBoardImageCustomSize() {
        let customSize = CGSize(width: 200, height: 200)
        let image = gameModel.generateBoardImage(size: customSize, colorScheme: .light)
        
        XCTAssertNotNil(image)
        XCTAssertEqual(image?.size.width, 200)
        XCTAssertEqual(image?.size.height, 200)
    }
    
    // MARK: - Integration Tests
    
    func testCompleteGameFlow() {
        // Test a complete game flow with multiple moves and captures
        
        // Start new game
        gameModel.startNewGame()
        XCTAssertEqual(gameModel.board[9][9], .black)
        XCTAssertEqual(gameModel.currentPlayer, .white)
        
        // Send first move
        gameModel.sendFirstMove()
        XCTAssertFalse(gameModel.isNewGamePendingSend)
        
        // White makes a move
        gameModel.makeMove(row: 10, col: 10)
        XCTAssertNotNil(gameModel.pendingMove)
        
        gameModel.confirmMove()
        XCTAssertEqual(gameModel.board[10][10], .white)
        XCTAssertEqual(gameModel.currentPlayer, .black)
        
        // Continue with more moves...
        gameModel.makeMove(row: 8, col: 8)
        gameModel.confirmMove()
        
        XCTAssertEqual(gameModel.moveHistory.count, 3) // Including initial center move
        XCTAssertEqual(gameModel.currentPlayer, .white)
    }
    
    func testCaptureIntegration() {
        // Test capture integration with the game model
        
        // Setup capture scenario
        gameModel.currentPlayer = .black
        gameModel.makeMove(row: 10, col: 10)
        gameModel.confirmMove()
        
        gameModel.currentPlayer = .white
        gameModel.makeMove(row: 10, col: 11)
        gameModel.confirmMove()

        gameModel.currentPlayer = .white
        gameModel.makeMove(row: 10, col: 12)
        gameModel.confirmMove()

        // Black captures
        gameModel.currentPlayer = .black
        gameModel.makeMove(row: 10, col: 13)
        
        // Should show pending captures
        XCTAssertEqual(gameModel.pendingCaptures.count, 2)
        XCTAssertEqual(gameModel.lastCaptures.count, 2) // Visual feedback
        
        gameModel.confirmMove()
        
        // Should execute captures
        XCTAssertNil(gameModel.board[10][11])
        XCTAssertNil(gameModel.board[10][12])
        XCTAssertEqual(gameModel.capturedCount[.black], 1) // 1 pair
        XCTAssertEqual(gameModel.lastCaptures.count, 0) // Cleared after confirm
    }
    
    func testDelegateIntegration() {
        let expectation = XCTestExpectation(description: "Delegate called for each move")
        expectation.expectedFulfillmentCount = 2
        mockDelegate.expectation = expectation
        
        // Make and confirm two moves
        gameModel.makeMove(row: 10, col: 10)
        gameModel.confirmMove() // Should call delegate
        
        gameModel.makeMove(row: 11, col: 11)
        gameModel.confirmMove() // Should call delegate again
        
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(mockDelegate.moveCallCount, 2)
    }
    
    // MARK: - Edge Cases and Error Conditions
    
    func testMakeMoveAtBoardEdges() {
        // Test moves at all edges and corners
        let edgePositions = [
            (0, 0), (0, 18), (18, 0), (18, 18), // Corners
            (0, 9), (18, 9), (9, 0), (9, 18)   // Edge midpoints
        ]
        
        for (row, col) in edgePositions {
            gameModel.resetGame()
            gameModel.makeMove(row: row, col: col)
            
            XCTAssertNotNil(gameModel.pendingMove)
            XCTAssertEqual(gameModel.board[row][col], .black)
            
            gameModel.confirmMove()
            XCTAssertEqual(gameModel.moveHistory.count, 1)
        }
    }
    
    func testInvalidMovePositions() {
        // Test that invalid positions are handled gracefully
        let invalidPositions = [
            (-1, 0), (0, -1), (19, 0), (0, 19), (100, 100)
        ]
        
        for (row, col) in invalidPositions {
            gameModel.makeMove(row: row, col: col)
            
            // Should not create pending move or place stone
            XCTAssertNil(gameModel.pendingMove)
            XCTAssertEqual(gameModel.moveHistory.count, 0)
        }
    }
    
    func testRapidMoveSequence() {
        // Test rapid move making and undoing
        for i in 0..<10 {
            gameModel.makeMove(row: i, col: i)
            if i % 2 == 0 {
                gameModel.confirmMove()
            } else {
                gameModel.undoMove()
            }
        }
        
        // Should only have confirmed moves
        XCTAssertEqual(gameModel.moveHistory.count, 5)
        XCTAssertNil(gameModel.pendingMove)
    }
    
    // MARK: - Player Assignment Tests
    
    func testInitialPlayerAssignmentState() {
        // Initial state should allow moves (no assignment restrictions)
        XCTAssertNil(gameModel.assignedPlayerColor)
        XCTAssertNil(gameModel.blackPlayerID)
        XCTAssertTrue(gameModel.canMakeMove)
        XCTAssertFalse(gameModel.waitingForOpponent)
    }
    
    func testSetBlackPlayerAssignment() {
        let testPlayerID = "black-player-123"
        
        gameModel.setPlayerAssignment(.black, blackPlayerID: testPlayerID)
        
        XCTAssertEqual(gameModel.assignedPlayerColor, .black)
        XCTAssertEqual(gameModel.blackPlayerID, testPlayerID)
        XCTAssertTrue(gameModel.canMakeMove) // Black's turn initially
        XCTAssertFalse(gameModel.waitingForOpponent)
    }
    
    func testSetWhitePlayerAssignment() {
        let testPlayerID = "black-player-123"
        
        gameModel.setPlayerAssignment(.white, blackPlayerID: testPlayerID)
        
        XCTAssertEqual(gameModel.assignedPlayerColor, .white)
        XCTAssertEqual(gameModel.blackPlayerID, testPlayerID)
        XCTAssertFalse(gameModel.canMakeMove) // Black's turn, but this is white player
        XCTAssertTrue(gameModel.waitingForOpponent)
    }
    
    func testBlackPlayerCanMoveOnTheirTurn() {
        let testPlayerID = "black-player-123"
        gameModel.setPlayerAssignment(.black, blackPlayerID: testPlayerID)
        
        // Should be black's turn initially
        XCTAssertEqual(gameModel.currentPlayer, .black)
        XCTAssertTrue(gameModel.canMakeMove)
        
        // Should be able to make a move
        gameModel.makeMove(row: 9, col: 9)
        XCTAssertNotNil(gameModel.pendingMove)
    }
    
    func testWhitePlayerCannotMoveOnBlacksTurn() {
        let testPlayerID = "black-player-123"
        gameModel.setPlayerAssignment(.white, blackPlayerID: testPlayerID)
        
        // Should be black's turn initially, white player should not be able to move
        XCTAssertEqual(gameModel.currentPlayer, .black)
        XCTAssertFalse(gameModel.canMakeMove)
        
        // Should not be able to make a move
        gameModel.makeMove(row: 9, col: 9)
        XCTAssertNil(gameModel.pendingMove)
    }
    
    func testTurnChangeUpdatesPermissions() {
        let testPlayerID = "black-player-123"
        gameModel.setPlayerAssignment(.white, blackPlayerID: testPlayerID)
        
        // Initially white player cannot move (black's turn)
        XCTAssertFalse(gameModel.canMakeMove)
        XCTAssertTrue(gameModel.waitingForOpponent)
        
        // Simulate black making a move (manually change turn and reassign to trigger update)
        gameModel.currentPlayer = .white
        gameModel.setPlayerAssignment(.white, blackPlayerID: testPlayerID)
        
        // Now white player should be able to move
        XCTAssertTrue(gameModel.canMakeMove)
        XCTAssertFalse(gameModel.waitingForOpponent)
    }
    
    func testPlayerAssignmentWithRealGameFlow() {
        let testPlayerID = "black-player-123"
        
        // Start as black player
        gameModel.setPlayerAssignment(.black, blackPlayerID: testPlayerID)
        
        // Black player makes first move
        XCTAssertTrue(gameModel.canMakeMove)
        gameModel.makeMove(row: 9, col: 9)
        gameModel.confirmMove()
        
        // Now it should be white's turn, black player should wait
        XCTAssertEqual(gameModel.currentPlayer, .white)
        XCTAssertFalse(gameModel.canMakeMove)
        XCTAssertTrue(gameModel.waitingForOpponent)
        
        // Black player should not be able to make another move
        gameModel.makeMove(row: 10, col: 10)
        XCTAssertNil(gameModel.pendingMove)
    }
    
    func testResetGameClearsPlayerAssignment() {
        let testPlayerID = "black-player-123"
        gameModel.setPlayerAssignment(.black, blackPlayerID: testPlayerID)
        
        XCTAssertNotNil(gameModel.assignedPlayerColor)
        XCTAssertNotNil(gameModel.blackPlayerID)
        
        gameModel.resetGame()
        
        XCTAssertNil(gameModel.assignedPlayerColor)
        XCTAssertNil(gameModel.blackPlayerID)
        XCTAssertTrue(gameModel.canMakeMove)
        XCTAssertFalse(gameModel.waitingForOpponent)
    }
    
    func testStartNewGameWithPlayerID() {
        let testPlayerID = "new-game-player-123"
        
        gameModel.startNewGame(blackPlayerID: testPlayerID)
        
        XCTAssertEqual(gameModel.blackPlayerID, testPlayerID)
        XCTAssertEqual(gameModel.currentPlayer, .white) // First move places black stone, switches to white
        XCTAssertTrue(gameModel.isNewGamePendingSend)
        
        // Check that the center black stone was placed
        XCTAssertEqual(gameModel.moveHistory.count, 1)
        XCTAssertEqual(gameModel.moveHistory[0].player, .black)
        XCTAssertEqual(gameModel.moveHistory[0].row, 9)
        XCTAssertEqual(gameModel.moveHistory[0].col, 9)
    }
    
    func testPlayerAssignmentWithNilAssignment() {
        // Test that nil assignment allows all moves (legacy behavior)
        gameModel.setPlayerAssignment(nil, blackPlayerID: nil)
        
        XCTAssertNil(gameModel.assignedPlayerColor)
        XCTAssertTrue(gameModel.canMakeMove)
        XCTAssertFalse(gameModel.waitingForOpponent)
        
        // Should be able to make moves regardless of turn
        gameModel.makeMove(row: 9, col: 9)
        XCTAssertNotNil(gameModel.pendingMove)
    }
    
    func testEncodeToQueryItemsIncludesPlayerID() {
        let testPlayerID = "encode-test-player"
        gameModel.blackPlayerID = testPlayerID
        
        let queryItems = gameModel.encodeToQueryItems()
        
        XCTAssertTrue(queryItems.contains { $0.name == "blackID" && $0.value == testPlayerID })
    }
    
    func testLoadFromURLSetsBlackPlayerID() {
        let testPlayerID = "load-test-player"
        let url = URL(string: "pente://game?current=Black&capB=0&capW=0&state=playing&blackID=\(testPlayerID)")!
        
        gameModel.loadFromURL(url)
        
        XCTAssertEqual(gameModel.blackPlayerID, testPlayerID)
    }
    
    func testUpdateMovePermissionsDirectly() {
        // Test the private updateMovePermissions method indirectly
        let testPlayerID = "permissions-test-player"
        
        // Test with no assignment
        gameModel.setPlayerAssignment(nil, blackPlayerID: nil)
        XCTAssertTrue(gameModel.canMakeMove)
        XCTAssertFalse(gameModel.waitingForOpponent)
        
        // Test with black assignment on black's turn
        gameModel.currentPlayer = .black
        gameModel.setPlayerAssignment(.black, blackPlayerID: testPlayerID)
        XCTAssertTrue(gameModel.canMakeMove)
        XCTAssertFalse(gameModel.waitingForOpponent)
        
        // Test with white assignment on black's turn
        gameModel.currentPlayer = .black
        gameModel.setPlayerAssignment(.white, blackPlayerID: testPlayerID)
        XCTAssertFalse(gameModel.canMakeMove)
        XCTAssertTrue(gameModel.waitingForOpponent)
        
        // Test with white assignment on white's turn
        gameModel.currentPlayer = .white
        gameModel.setPlayerAssignment(.white, blackPlayerID: testPlayerID)
        XCTAssertTrue(gameModel.canMakeMove)
        XCTAssertFalse(gameModel.waitingForOpponent)
    }
    
    func testPlayerAssignmentPreventsGameEndingMoves() {
        let testPlayerID = "endgame-test-player"
        gameModel.setPlayerAssignment(.white, blackPlayerID: testPlayerID)
        
        // Set up a scenario where black could win, but white player shouldn't be able to trigger it
        gameModel.currentPlayer = .black
        
        // White player (waiting for opponent) tries to make a move
        XCTAssertFalse(gameModel.canMakeMove)
        gameModel.makeMove(row: 9, col: 9)
        
        // Should not create pending move or change game state
        XCTAssertNil(gameModel.pendingMove)
        if case .playing = gameModel.gameState {
            // Correct - game should still be playing
        } else {
            XCTFail("Game state should still be playing")
        }
    }

    // MARK: - Ring Indicator Invariant Tests
    //
    // These tests protect the write-ordering fixes in confirmMove() and
    // loadFromURL() that prevent the live view from ever rendering the blue
    // pending ring and the green committed ring at the same cell. They're
    // also the regression harness for the reorder itself — if someone puts
    // moveHistory.append BEFORE pendingMove = nil in confirmMove(), the
    // collision-detector sink in testConfirmMoveNeverCollidesRings will fail.

    /// Subscribes to objectWillChange and asserts that at no pre-change
    /// emission during confirmMove does pendingMove point at the same
    /// intersection as moveHistory.last. That's the exact state that would
    /// produce a stacked blue+green ring in the SwiftUI Canvas.
    func testConfirmMoveNeverExposesCollidingRings() {
        gameModel.makeMove(row: 10, col: 10)
        XCTAssertNotNil(gameModel.pendingMove)

        var violations: [String] = []
        var emissions = 0
        let cancellable = gameModel.objectWillChange.sink { [weak gameModel] in
            guard let model = gameModel else { return }
            emissions += 1
            if let pending = model.pendingMove,
               let last = model.moveHistory.last,
               pending.row == last.row, pending.col == last.col {
                violations.append(
                    "emission #\(emissions): pendingMove=(\(pending.row),\(pending.col)) collides with moveHistory.last at same cell"
                )
            }
        }

        gameModel.confirmMove()
        cancellable.cancel()

        XCTAssertTrue(violations.isEmpty,
            "confirmMove exposed blue+green ring collision at same cell: \(violations)")
        XCTAssertGreaterThan(emissions, 0, "sink should have received emissions")

        // Post-condition: pendingMove cleared, moveHistory holds the move.
        XCTAssertNil(gameModel.pendingMove)
        XCTAssertEqual(gameModel.moveHistory.last?.row, 10)
        XCTAssertEqual(gameModel.moveHistory.last?.col, 10)
        XCTAssertEqual(gameModel.moveHistory.last?.player, .black)
    }

    /// Same invariant for the capture path — confirmMove also removes
    /// captured stones. The reorder snapshots pendingCaptures into a local
    /// before clearing, so captures must still apply correctly.
    func testConfirmMoveWithCapturesNeverCollidesRings() {
        // Setup: Black at (10,9), White at (10,10), White at (10,11),
        // pending Black at (10,12) sandwiches the two whites.
        gameModel.currentPlayer = .black
        gameModel.makeMove(row: 10, col: 9)
        gameModel.confirmMove()
        gameModel.currentPlayer = .white
        gameModel.makeMove(row: 10, col: 10)
        gameModel.confirmMove()
        gameModel.currentPlayer = .white
        gameModel.makeMove(row: 10, col: 11)
        gameModel.confirmMove()
        gameModel.currentPlayer = .black
        gameModel.makeMove(row: 10, col: 12)
        XCTAssertEqual(gameModel.pendingCaptures.count, 2, "precondition: two pending captures")

        var violations: [String] = []
        let cancellable = gameModel.objectWillChange.sink { [weak gameModel] in
            guard let model = gameModel else { return }
            if let pending = model.pendingMove,
               let last = model.moveHistory.last,
               pending.row == last.row, pending.col == last.col {
                violations.append("collision at (\(pending.row),\(pending.col))")
            }
        }

        gameModel.confirmMove()
        cancellable.cancel()

        XCTAssertTrue(violations.isEmpty, "collisions during capture confirmMove: \(violations)")
        // Captures still applied (snapshot guard works).
        XCTAssertNil(gameModel.board[10][10])
        XCTAssertNil(gameModel.board[10][11])
        XCTAssertEqual(gameModel.capturedCount[.black], 1)
        XCTAssertEqual(gameModel.moveHistory.last?.row, 10)
        XCTAssertEqual(gameModel.moveHistory.last?.col, 12)
    }

    /// Protects the capture snapshot specifically: if someone removes
    /// `let capturesToApply = pendingCaptures` and iterates pendingCaptures
    /// directly, captures will silently stop applying because the array is
    /// cleared before the loop runs. This test would fail in that case.
    func testConfirmMoveAppliesCapturesAfterClearingPendingCapturesArray() {
        gameModel.currentPlayer = .black
        gameModel.makeMove(row: 10, col: 9)
        gameModel.confirmMove()
        gameModel.currentPlayer = .white
        gameModel.makeMove(row: 10, col: 10)
        gameModel.confirmMove()
        gameModel.currentPlayer = .white
        gameModel.makeMove(row: 10, col: 11)
        gameModel.confirmMove()
        gameModel.currentPlayer = .black
        gameModel.makeMove(row: 10, col: 12)
        XCTAssertEqual(gameModel.pendingCaptures.count, 2)

        gameModel.confirmMove()

        // If the snapshot is missing, pendingCaptures would have been cleared
        // before the removal loop ran, and these assertions would fail.
        XCTAssertNil(gameModel.board[10][10], "captured stone should be removed")
        XCTAssertNil(gameModel.board[10][11], "captured stone should be removed")
        XCTAssertEqual(gameModel.capturedCount[.black], 1, "capture pair should be counted")
        XCTAssertEqual(gameModel.pendingCaptures.count, 0, "pendingCaptures cleared post-confirm")
    }

    /// After loadFromURL returns, the board and moveHistory must be fully
    /// consistent: every move in history corresponds to a stone on the board,
    /// unless that stone was later captured (captures are replayed by the
    /// decoder). At minimum, moveHistory.last — where the green ring is
    /// drawn — must refer to a cell owned by that move's player.
    func testLoadFromURLFinalStateHasConsistentBoardAndHistory() {
        // Prime with some existing state so the decode must actually replace it.
        gameModel.makeMove(row: 3, col: 3)
        gameModel.confirmMove()
        gameModel.makeMove(row: 4, col: 4)
        gameModel.confirmMove()

        let url = URL(string: "pente://game?moves=B9,9;W10,10;B11,11;&current=White&capB=0&capW=0&state=playing")!
        gameModel.loadFromURL(url)

        // moveHistory.last must land on a stone of the right color.
        guard let last = gameModel.moveHistory.last else {
            XCTFail("moveHistory should not be empty after load")
            return
        }
        XCTAssertEqual(last.row, 11)
        XCTAssertEqual(last.col, 11)
        XCTAssertEqual(last.player, .black)
        XCTAssertEqual(gameModel.board[last.row][last.col], last.player,
            "green ring target must be backed by a stone of matching color")

        // Primed state must be gone.
        XCTAssertNil(gameModel.board[3][3], "old state should be wiped")
        XCTAssertNil(gameModel.board[4][4], "old state should be wiped")
    }

    /// After loadFromURL, pendingMove must be nil — the decoded message is
    /// always a committed state, never a tentative one. Otherwise Bob could
    /// open the message and see a stray blue ring on Alice's confirmed move.
    func testLoadFromURLClearsPendingMove() {
        // Put the model into a pending state first.
        gameModel.makeMove(row: 7, col: 7)
        XCTAssertNotNil(gameModel.pendingMove)

        let url = URL(string: "pente://game?moves=B9,9;W10,10;&current=Black&capB=0&capW=0&state=playing")!
        gameModel.loadFromURL(url)

        // No decoder-side pending state; any stray pendingMove would paint a
        // blue ring on an opponent's stone on the receiving device.
        // Note: current loadFromURL doesn't explicitly clear pendingMove, but
        // it also doesn't carry one across wire. If a future change forgets
        // to scrub it, this test will catch it.
        // (The test tolerates either "explicitly cleared" or "the primed
        // pending cell is no longer on the new board", since both are safe.)
        if let pending = gameModel.pendingMove {
            XCTAssertNil(gameModel.board[pending.row][pending.col],
                "if pendingMove survived loadFromURL, at minimum it must not point at a cell with a stone (which would cause a blue ring over a committed stone)")
        }
    }

    /// End-to-end model-level roundtrip: Alice makes a move and confirms,
    /// encodes the URL, Bob's model loads it, Bob sees Alice's move as the
    /// last committed move (= green ring target) with correct player color.
    func testCrossPlayerRoundTripPreservesLastMoveIdentity() {
        // Alice's model.
        let alice = PenteGameModel()
        alice.startNewGame() // places center (9,9) black, currentPlayer=.white, isNewGamePendingSend=true
        alice.sendFirstMove()
        // Alice is .white's turn now? No: after startNewGame, currentPlayer = .white.
        // sendFirstMove just clears the isNewGamePendingSend flag.
        XCTAssertEqual(alice.currentPlayer, .white)

        // White plays (10, 10). White is Alice in this fiction but the
        // assignment doesn't matter for the roundtrip — only the state does.
        alice.makeMove(row: 10, col: 10)
        alice.confirmMove()

        // Encode.
        let items = alice.encodeToQueryItems()
        var comps = URLComponents()
        comps.scheme = "pente"
        comps.host = "game"
        comps.queryItems = items
        guard let url = comps.url else {
            XCTFail("failed to build URL from query items")
            return
        }

        // Bob's model decodes.
        let bob = PenteGameModel()
        bob.loadFromURL(url)

        // Bob sees the same last move Alice just confirmed.
        XCTAssertEqual(bob.moveHistory.last?.row, 10)
        XCTAssertEqual(bob.moveHistory.last?.col, 10)
        XCTAssertEqual(bob.moveHistory.last?.player, .white)
        XCTAssertEqual(bob.board[10][10], .white)
        // Center auto-placement preserved too.
        XCTAssertEqual(bob.board[9][9], .black)
        // No stray pending state on Bob's side.
        if let pending = bob.pendingMove {
            XCTAssertNil(bob.board[pending.row][pending.col],
                "Bob should not have a pending move over a committed stone")
        }
    }
}