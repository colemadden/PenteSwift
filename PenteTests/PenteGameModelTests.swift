import XCTest
@testable import Pente_MessagesExtension

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
        XCTAssertFalse(gameModel.isFirstMoveReadyToSend)
        
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
        XCTAssertTrue(gameModel.isFirstMoveReadyToSend)
    }
    
    func testSendFirstMove() {
        gameModel.startNewGame()
        
        let expectation = XCTestExpectation(description: "Move delegate called")
        mockDelegate.expectation = expectation
        
        gameModel.sendFirstMove()
        
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertFalse(gameModel.isNewGamePendingSend)
        XCTAssertFalse(gameModel.isFirstMoveReadyToSend)
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
        
        // Setup a capture scenario
        gameModel.currentPlayer = .white
        gameModel.makeMove(row: 10, col: 10)
        gameModel.confirmMove()
        
        gameModel.makeMove(row: 10, col: 11)
        gameModel.confirmMove()
        
        // Black captures to win
        gameModel.currentPlayer = .black
        gameModel.makeMove(row: 10, col: 9) // Place supporting stone first
        gameModel.confirmMove()
        
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
        XCTAssertEqual(gameModel.capturedCount[.black], 1)
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
        XCTAssertFalse(gameModel.isFirstMoveReadyToSend)
        
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
}