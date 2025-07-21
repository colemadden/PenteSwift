import XCTest
@testable import Pente_MessagesExtension

final class WinDetectorTests: XCTestCase {
    
    var gameBoard: GameBoard!
    
    override func setUp() {
        super.setUp()
        gameBoard = GameBoard()
    }
    
    override func tearDown() {
        gameBoard = nil
        super.tearDown()
    }
    
    // MARK: - Five in a Row Tests
    
    func testHorizontalFiveInARow() {
        // Place five black stones horizontally
        for col in 5...9 {
            gameBoard.placeStone(.black, at: 10, col: col)
        }
        
        // Test win detection for each stone in the line
        for col in 5...9 {
            XCTAssertTrue(WinDetector.checkFiveInARow(on: gameBoard, at: 10, col: col, for: .black))
        }
        
        // Test that white doesn't win
        XCTAssertFalse(WinDetector.checkFiveInARow(on: gameBoard, at: 10, col: 5, for: .white))
    }
    
    func testVerticalFiveInARow() {
        // Place five white stones vertically
        for row in 5...9 {
            gameBoard.placeStone(.white, at: row, col: 10)
        }
        
        // Test win detection for each stone in the line
        for row in 5...9 {
            XCTAssertTrue(WinDetector.checkFiveInARow(on: gameBoard, at: row, col: 10, for: .white))
        }
        
        // Test that black doesn't win
        XCTAssertFalse(WinDetector.checkFiveInARow(on: gameBoard, at: 5, col: 10, for: .black))
    }
    
    func testDiagonalFiveInARowDownRight() {
        // Place five black stones diagonally (\)
        for i in 0...4 {
            gameBoard.placeStone(.black, at: 5 + i, col: 5 + i)
        }
        
        // Test win detection for each stone in the line
        for i in 0...4 {
            XCTAssertTrue(WinDetector.checkFiveInARow(on: gameBoard, at: 5 + i, col: 5 + i, for: .black))
        }
    }
    
    func testDiagonalFiveInARowDownLeft() {
        // Place five white stones diagonally (/)
        for i in 0...4 {
            gameBoard.placeStone(.white, at: 5 + i, col: 9 - i)
        }
        
        // Test win detection for each stone in the line
        for i in 0...4 {
            XCTAssertTrue(WinDetector.checkFiveInARow(on: gameBoard, at: 5 + i, col: 9 - i, for: .white))
        }
    }
    
    // MARK: - Six or More in a Row Tests (Rules say this also wins)
    
    func testSixInARowWins() {
        // Place six black stones horizontally
        for col in 5...10 {
            gameBoard.placeStone(.black, at: 10, col: col)
        }
        
        // All positions should detect the win
        for col in 5...10 {
            XCTAssertTrue(WinDetector.checkFiveInARow(on: gameBoard, at: 10, col: col, for: .black))
        }
    }
    
    func testSevenInARowWins() {
        // Place seven white stones vertically
        for row in 3...9 {
            gameBoard.placeStone(.white, at: row, col: 10)
        }
        
        // All positions should detect the win
        for row in 3...9 {
            XCTAssertTrue(WinDetector.checkFiveInARow(on: gameBoard, at: row, col: 10, for: .white))
        }
    }
    
    // MARK: - Four in a Row Tests (Should NOT Win)
    
    func testFourInARowDoesNotWin() {
        // Place only four stones horizontally
        for col in 5...8 {
            gameBoard.placeStone(.black, at: 10, col: col)
        }
        
        // Should not detect a win
        for col in 5...8 {
            XCTAssertFalse(WinDetector.checkFiveInARow(on: gameBoard, at: 10, col: col, for: .black))
        }
    }
    
    func testThreeInARowDoesNotWin() {
        // Place only three stones diagonally
        for i in 0...2 {
            gameBoard.placeStone(.white, at: 5 + i, col: 5 + i)
        }
        
        // Should not detect a win
        for i in 0...2 {
            XCTAssertFalse(WinDetector.checkFiveInARow(on: gameBoard, at: 5 + i, col: 5 + i, for: .white))
        }
    }
    
    // MARK: - Broken Line Tests
    
    func testBrokenLineDoesNotWin() {
        // Place four stones with a gap in the middle
        gameBoard.placeStone(.black, at: 10, col: 5)
        gameBoard.placeStone(.black, at: 10, col: 6)
        // Gap at (10, 7)
        gameBoard.placeStone(.black, at: 10, col: 8)
        gameBoard.placeStone(.black, at: 10, col: 9)
        gameBoard.placeStone(.black, at: 10, col: 10)
        
        // Should not detect a win due to the gap
        XCTAssertFalse(WinDetector.checkFiveInARow(on: gameBoard, at: 10, col: 5, for: .black))
        XCTAssertFalse(WinDetector.checkFiveInARow(on: gameBoard, at: 10, col: 6, for: .black))
        XCTAssertFalse(WinDetector.checkFiveInARow(on: gameBoard, at: 10, col: 8, for: .black))
        XCTAssertFalse(WinDetector.checkFiveInARow(on: gameBoard, at: 10, col: 9, for: .black))
        XCTAssertFalse(WinDetector.checkFiveInARow(on: gameBoard, at: 10, col: 10, for: .black))
    }
    
    func testOpponentStoneBreaksLine() {
        // Place stones with opponent stone in the middle
        gameBoard.placeStone(.black, at: 10, col: 5)
        gameBoard.placeStone(.black, at: 10, col: 6)
        gameBoard.placeStone(.white, at: 10, col: 7) // Opponent stone
        gameBoard.placeStone(.black, at: 10, col: 8)
        gameBoard.placeStone(.black, at: 10, col: 9)
        gameBoard.placeStone(.black, at: 10, col: 10)
        
        // Should not detect a win due to opponent stone
        XCTAssertFalse(WinDetector.checkFiveInARow(on: gameBoard, at: 10, col: 5, for: .black))
        XCTAssertFalse(WinDetector.checkFiveInARow(on: gameBoard, at: 10, col: 6, for: .black))
        XCTAssertFalse(WinDetector.checkFiveInARow(on: gameBoard, at: 10, col: 8, for: .black))
    }
    
    // MARK: - Edge and Corner Tests
    
    func testFiveInARowAtLeftEdge() {
        // Place five stones starting from left edge
        for col in 0...4 {
            gameBoard.placeStone(.black, at: 10, col: col)
        }
        
        // Should detect win
        for col in 0...4 {
            XCTAssertTrue(WinDetector.checkFiveInARow(on: gameBoard, at: 10, col: col, for: .black))
        }
    }
    
    func testFiveInARowAtRightEdge() {
        // Place five stones ending at right edge
        for col in 14...18 {
            gameBoard.placeStone(.white, at: 10, col: col)
        }
        
        // Should detect win
        for col in 14...18 {
            XCTAssertTrue(WinDetector.checkFiveInARow(on: gameBoard, at: 10, col: col, for: .white))
        }
    }
    
    func testFiveInARowAtTopEdge() {
        // Place five stones starting from top edge
        for row in 0...4 {
            gameBoard.placeStone(.black, at: row, col: 10)
        }
        
        // Should detect win
        for row in 0...4 {
            XCTAssertTrue(WinDetector.checkFiveInARow(on: gameBoard, at: row, col: 10, for: .black))
        }
    }
    
    func testFiveInARowAtBottomEdge() {
        // Place five stones ending at bottom edge
        for row in 14...18 {
            gameBoard.placeStone(.white, at: row, col: 10)
        }
        
        // Should detect win
        for row in 14...18 {
            XCTAssertTrue(WinDetector.checkFiveInARow(on: gameBoard, at: row, col: 10, for: .white))
        }
    }
    
    func testDiagonalAtCorner() {
        // Place five stones diagonally from top-left corner
        for i in 0...4 {
            gameBoard.placeStone(.black, at: i, col: i)
        }
        
        // Should detect win
        for i in 0...4 {
            XCTAssertTrue(WinDetector.checkFiveInARow(on: gameBoard, at: i, col: i, for: .black))
        }
    }
    
    func testDiagonalAtBottomRightCorner() {
        // Place five stones diagonally ending at bottom-right area
        for i in 0...4 {
            gameBoard.placeStone(.white, at: 14 + i, col: 14 + i)
        }
        
        // Should detect win
        for i in 0...4 {
            XCTAssertTrue(WinDetector.checkFiveInARow(on: gameBoard, at: 14 + i, col: 14 + i, for: .white))
        }
    }
    
    // MARK: - Complex Board Scenarios
    
    func testFiveInARowWithSurroundingStones() {
        // Create a complex board with many stones
        // Place random stones
        gameBoard.placeStone(.white, at: 5, col: 5)
        gameBoard.placeStone(.black, at: 6, col: 6)
        gameBoard.placeStone(.white, at: 7, col: 8)
        gameBoard.placeStone(.black, at: 8, col: 7)
        
        // Place the winning line
        for col in 10...14 {
            gameBoard.placeStone(.black, at: 10, col: col)
        }
        
        // Should still detect the win despite other stones
        XCTAssertTrue(WinDetector.checkFiveInARow(on: gameBoard, at: 10, col: 12, for: .black))
    }
    
    func testMultiplePotentialWins() {
        // Create multiple lines that could be wins, but only one actually is
        
        // Almost-win line (only 4 stones)
        for col in 5...8 {
            gameBoard.placeStone(.black, at: 5, col: col)
        }
        
        // Actual win line (5 stones)
        for row in 10...14 {
            gameBoard.placeStone(.black, at: row, col: 10)
        }
        
        // Should detect win in the complete line only
        XCTAssertFalse(WinDetector.checkFiveInARow(on: gameBoard, at: 5, col: 7, for: .black))
        XCTAssertTrue(WinDetector.checkFiveInARow(on: gameBoard, at: 12, col: 10, for: .black))
    }
    
    // MARK: - Capture Win Tests
    
    func testCaptureWinWithExactlyFive() {
        XCTAssertTrue(WinDetector.checkCaptureWin(capturedCount: 5))
    }
    
    func testCaptureWinWithMoreThanFive() {
        XCTAssertTrue(WinDetector.checkCaptureWin(capturedCount: 6))
        XCTAssertTrue(WinDetector.checkCaptureWin(capturedCount: 10))
        XCTAssertTrue(WinDetector.checkCaptureWin(capturedCount: 100))
    }
    
    func testNoCaptureWinWithLessThanFive() {
        XCTAssertFalse(WinDetector.checkCaptureWin(capturedCount: 0))
        XCTAssertFalse(WinDetector.checkCaptureWin(capturedCount: 1))
        XCTAssertFalse(WinDetector.checkCaptureWin(capturedCount: 4))
    }
    
    // MARK: - Edge Cases and Error Conditions
    
    func testEmptyBoard() {
        // No win should be detected on empty board
        XCTAssertFalse(WinDetector.checkFiveInARow(on: gameBoard, at: 9, col: 9, for: .black))
        XCTAssertFalse(WinDetector.checkFiveInARow(on: gameBoard, at: 9, col: 9, for: .white))
    }
    
    func testSingleStone() {
        gameBoard.placeStone(.black, at: 9, col: 9)
        XCTAssertFalse(WinDetector.checkFiveInARow(on: gameBoard, at: 9, col: 9, for: .black))
    }
    
    func testInvalidPosition() {
        // Place valid win condition
        for col in 5...9 {
            gameBoard.placeStone(.black, at: 10, col: col)
        }
        
        // Test with invalid position - should not crash
        XCTAssertFalse(WinDetector.checkFiveInARow(on: gameBoard, at: -1, col: 0, for: .black))
        XCTAssertFalse(WinDetector.checkFiveInARow(on: gameBoard, at: 19, col: 0, for: .black))
        XCTAssertFalse(WinDetector.checkFiveInARow(on: gameBoard, at: 0, col: -1, for: .black))
        XCTAssertFalse(WinDetector.checkFiveInARow(on: gameBoard, at: 0, col: 19, for: .black))
    }
    
    // MARK: - Specific Game Rule Tests
    
    func testExactlyFiveRequired() {
        // Test that exactly 5 stones (not 6 or more) can win
        // This tests the rule: "five (or more) stones in a row"
        
        // Place exactly 5 stones
        for col in 7...11 {
            gameBoard.placeStone(.black, at: 10, col: col)
        }
        
        XCTAssertTrue(WinDetector.checkFiveInARow(on: gameBoard, at: 10, col: 9, for: .black))
        
        // Add a 6th stone
        gameBoard.placeStone(.black, at: 10, col: 12)
        
        // Should still win (6 in a row is also a win according to rules)
        XCTAssertTrue(WinDetector.checkFiveInARow(on: gameBoard, at: 10, col: 9, for: .black))
    }
    
    func testWinFromAnyStoneInLine() {
        // According to Pente rules, any stone in a winning line should detect the win
        for col in 5...9 {
            gameBoard.placeStone(.black, at: 10, col: col)
        }
        
        // Test detection from each stone in the line
        XCTAssertTrue(WinDetector.checkFiveInARow(on: gameBoard, at: 10, col: 5, for: .black), "First stone should detect win")
        XCTAssertTrue(WinDetector.checkFiveInARow(on: gameBoard, at: 10, col: 6, for: .black), "Second stone should detect win")
        XCTAssertTrue(WinDetector.checkFiveInARow(on: gameBoard, at: 10, col: 7, for: .black), "Middle stone should detect win")
        XCTAssertTrue(WinDetector.checkFiveInARow(on: gameBoard, at: 10, col: 8, for: .black), "Fourth stone should detect win")
        XCTAssertTrue(WinDetector.checkFiveInARow(on: gameBoard, at: 10, col: 9, for: .black), "Last stone should detect win")
    }
    
    // MARK: - Performance Tests
    
    func testLargeScaleBoardChecking() {
        // Fill most of the board and test performance
        for row in 0..<18 {
            for col in 0..<18 {
                let player: Player = (row + col) % 2 == 0 ? .black : .white
                gameBoard.placeStone(player, at: row, col: col)
            }
        }
        
        // Create one winning line
        for col in 5...9 {
            gameBoard.placeStone(.black, at: 18, col: col)
        }
        
        // Should still detect win efficiently
        XCTAssertTrue(WinDetector.checkFiveInARow(on: gameBoard, at: 18, col: 7, for: .black))
    }
}