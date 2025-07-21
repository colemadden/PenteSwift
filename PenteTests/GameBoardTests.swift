import XCTest
@testable import Pente_MessagesExtension

final class GameBoardTests: XCTestCase {
    
    var gameBoard: GameBoard!
    
    override func setUp() {
        super.setUp()
        gameBoard = GameBoard()
    }
    
    override func tearDown() {
        gameBoard = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testGameBoardInitialization() {
        XCTAssertEqual(GameBoard.size, 19)
        
        // Verify all positions are empty
        for row in 0..<GameBoard.size {
            for col in 0..<GameBoard.size {
                XCTAssertNil(gameBoard[row, col], "Position (\(row), \(col)) should be empty")
            }
        }
    }
    
    func testAsArrayProperty() {
        let boardArray = gameBoard.asArray
        XCTAssertEqual(boardArray.count, 19)
        XCTAssertEqual(boardArray[0].count, 19)
        
        // Verify all positions are nil
        for row in boardArray {
            for cell in row {
                XCTAssertNil(cell)
            }
        }
    }
    
    // MARK: - Position Validation Tests
    
    func testIsValidPosition() {
        // Valid positions
        XCTAssertTrue(gameBoard.isValidPosition(0, 0))
        XCTAssertTrue(gameBoard.isValidPosition(9, 9))
        XCTAssertTrue(gameBoard.isValidPosition(18, 18))
        XCTAssertTrue(gameBoard.isValidPosition(0, 18))
        XCTAssertTrue(gameBoard.isValidPosition(18, 0))
        
        // Invalid positions - negative
        XCTAssertFalse(gameBoard.isValidPosition(-1, 0))
        XCTAssertFalse(gameBoard.isValidPosition(0, -1))
        XCTAssertFalse(gameBoard.isValidPosition(-1, -1))
        
        // Invalid positions - out of bounds
        XCTAssertFalse(gameBoard.isValidPosition(19, 0))
        XCTAssertFalse(gameBoard.isValidPosition(0, 19))
        XCTAssertFalse(gameBoard.isValidPosition(19, 19))
        XCTAssertFalse(gameBoard.isValidPosition(100, 100))
    }
    
    // MARK: - Stone Placement Tests
    
    func testPlaceStone() {
        // Place a black stone at center
        gameBoard.placeStone(.black, at: 9, col: 9)
        XCTAssertEqual(gameBoard[9, 9], .black)
        
        // Place a white stone at corner
        gameBoard.placeStone(.white, at: 0, col: 0)
        XCTAssertEqual(gameBoard[0, 0], .white)
        
        // Verify other positions remain empty
        XCTAssertNil(gameBoard[1, 1])
        XCTAssertNil(gameBoard[18, 18])
    }
    
    func testPlaceStoneInvalidPosition() {
        // This should not crash or cause issues
        gameBoard.placeStone(.black, at: -1, col: 0)
        gameBoard.placeStone(.white, at: 0, col: -1)
        gameBoard.placeStone(.black, at: 19, col: 0)
        gameBoard.placeStone(.white, at: 0, col: 19)
        
        // Verify no stones were placed
        for row in 0..<GameBoard.size {
            for col in 0..<GameBoard.size {
                XCTAssertNil(gameBoard[row, col])
            }
        }
    }
    
    func testOverwriteStone() {
        // Place initial stone
        gameBoard.placeStone(.black, at: 9, col: 9)
        XCTAssertEqual(gameBoard[9, 9], .black)
        
        // Overwrite with different color
        gameBoard.placeStone(.white, at: 9, col: 9)
        XCTAssertEqual(gameBoard[9, 9], .white)
    }
    
    // MARK: - Stone Removal Tests
    
    func testRemoveStone() {
        // Place a stone
        gameBoard.placeStone(.black, at: 9, col: 9)
        XCTAssertEqual(gameBoard[9, 9], .black)
        
        // Remove the stone
        gameBoard.removeStone(at: 9, col: 9)
        XCTAssertNil(gameBoard[9, 9])
    }
    
    func testRemoveStoneFromEmptyPosition() {
        // Remove from empty position should not cause issues
        gameBoard.removeStone(at: 9, col: 9)
        XCTAssertNil(gameBoard[9, 9])
    }
    
    func testRemoveStoneInvalidPosition() {
        // This should not crash
        gameBoard.removeStone(at: -1, col: 0)
        gameBoard.removeStone(at: 19, col: 0)
    }
    
    // MARK: - Empty Check Tests
    
    func testIsEmpty() {
        // Initially all positions should be empty
        XCTAssertTrue(gameBoard.isEmpty(at: 9, col: 9))
        XCTAssertTrue(gameBoard.isEmpty(at: 0, col: 0))
        XCTAssertTrue(gameBoard.isEmpty(at: 18, col: 18))
        
        // Place a stone
        gameBoard.placeStone(.black, at: 9, col: 9)
        XCTAssertFalse(gameBoard.isEmpty(at: 9, col: 9))
        
        // Other positions should still be empty
        XCTAssertTrue(gameBoard.isEmpty(at: 8, col: 9))
        XCTAssertTrue(gameBoard.isEmpty(at: 10, col: 9))
    }
    
    func testIsEmptyInvalidPosition() {
        // Invalid positions should return false (not empty, but invalid)
        XCTAssertFalse(gameBoard.isEmpty(at: -1, col: 0))
        XCTAssertFalse(gameBoard.isEmpty(at: 19, col: 0))
    }
    
    // MARK: - Reset Tests
    
    func testReset() {
        // Place some stones
        gameBoard.placeStone(.black, at: 9, col: 9)
        gameBoard.placeStone(.white, at: 0, col: 0)
        gameBoard.placeStone(.black, at: 18, col: 18)
        
        // Verify stones are placed
        XCTAssertEqual(gameBoard[9, 9], .black)
        XCTAssertEqual(gameBoard[0, 0], .white)
        XCTAssertEqual(gameBoard[18, 18], .black)
        
        // Reset the board
        gameBoard.reset()
        
        // Verify all positions are empty
        for row in 0..<GameBoard.size {
            for col in 0..<GameBoard.size {
                XCTAssertNil(gameBoard[row, col], "Position (\(row), \(col)) should be empty after reset")
            }
        }
    }
    
    // MARK: - Subscript Tests
    
    func testSubscriptAccess() {
        // Test getter
        XCTAssertNil(gameBoard[9, 9])
        
        // Test setter
        gameBoard[9, 9] = .black
        XCTAssertEqual(gameBoard[9, 9], .black)
        
        gameBoard[9, 9] = .white
        XCTAssertEqual(gameBoard[9, 9], .white)
        
        gameBoard[9, 9] = nil
        XCTAssertNil(gameBoard[9, 9])
    }
    
    func testSubscriptInvalidAccess() {
        // Invalid access should return nil
        XCTAssertNil(gameBoard[-1, 0])
        XCTAssertNil(gameBoard[0, -1])
        XCTAssertNil(gameBoard[19, 0])
        XCTAssertNil(gameBoard[0, 19])
        
        // Setting invalid positions should not crash
        gameBoard[-1, 0] = .black
        gameBoard[19, 0] = .white
        
        // Verify no side effects
        XCTAssertNil(gameBoard[0, 0])
    }
    
    // MARK: - Edge Case Tests
    
    func testAllBoardPositions() {
        // Test placing stones on all valid positions
        for row in 0..<GameBoard.size {
            for col in 0..<GameBoard.size {
                let player: Player = (row + col) % 2 == 0 ? .black : .white
                gameBoard.placeStone(player, at: row, col: col)
                XCTAssertEqual(gameBoard[row, col], player)
            }
        }
        
        // Verify board is full
        for row in 0..<GameBoard.size {
            for col in 0..<GameBoard.size {
                XCTAssertNotNil(gameBoard[row, col])
            }
        }
    }
    
    func testBoardBoundaries() {
        // Test all four corners
        gameBoard.placeStone(.black, at: 0, col: 0)
        gameBoard.placeStone(.white, at: 0, col: 18)
        gameBoard.placeStone(.black, at: 18, col: 0)
        gameBoard.placeStone(.white, at: 18, col: 18)
        
        XCTAssertEqual(gameBoard[0, 0], .black)
        XCTAssertEqual(gameBoard[0, 18], .white)
        XCTAssertEqual(gameBoard[18, 0], .black)
        XCTAssertEqual(gameBoard[18, 18], .white)
        
        // Test edges
        gameBoard.placeStone(.black, at: 0, col: 9)  // Top edge
        gameBoard.placeStone(.white, at: 18, col: 9) // Bottom edge
        gameBoard.placeStone(.black, at: 9, col: 0)  // Left edge
        gameBoard.placeStone(.white, at: 9, col: 18) // Right edge
        
        XCTAssertEqual(gameBoard[0, 9], .black)
        XCTAssertEqual(gameBoard[18, 9], .white)
        XCTAssertEqual(gameBoard[9, 0], .black)
        XCTAssertEqual(gameBoard[9, 18], .white)
    }
}