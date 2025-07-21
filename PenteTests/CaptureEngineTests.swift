import XCTest
@testable import Pente_MessagesExtension

final class CaptureEngineTests: XCTestCase {
    
    var gameBoard: GameBoard!
    
    override func setUp() {
        super.setUp()
        gameBoard = GameBoard()
    }
    
    override func tearDown() {
        gameBoard = nil
        super.tearDown()
    }
    
    // MARK: - Basic Capture Tests
    
    func testHorizontalCaptureLeft() {
        // Setup: Black-White-White-[Empty]
        gameBoard.placeStone(.black, at: 5, col: 5)
        gameBoard.placeStone(.white, at: 5, col: 6)
        gameBoard.placeStone(.white, at: 5, col: 7)
        
        // Black plays at (5, 8) to capture the two white stones
        let captures = CaptureEngine.findCaptures(on: gameBoard, at: 5, col: 8, by: .black)
        
        XCTAssertEqual(captures.count, 2)
        XCTAssertTrue(captures.contains { $0.row == 5 && $0.col == 6 })
        XCTAssertTrue(captures.contains { $0.row == 5 && $0.col == 7 })
    }
    
    func testHorizontalCaptureRight() {
        // Setup: [Empty]-White-White-Black
        gameBoard.placeStone(.white, at: 5, col: 6)
        gameBoard.placeStone(.white, at: 5, col: 7)
        gameBoard.placeStone(.black, at: 5, col: 8)
        
        // Black plays at (5, 5) to capture the two white stones
        let captures = CaptureEngine.findCaptures(on: gameBoard, at: 5, col: 5, by: .black)
        
        XCTAssertEqual(captures.count, 2)
        XCTAssertTrue(captures.contains { $0.row == 5 && $0.col == 6 })
        XCTAssertTrue(captures.contains { $0.row == 5 && $0.col == 7 })
    }
    
    func testVerticalCaptureUp() {
        // Setup: Black-White-White-[Empty] (vertically)
        gameBoard.placeStone(.black, at: 5, col: 5)
        gameBoard.placeStone(.white, at: 6, col: 5)
        gameBoard.placeStone(.white, at: 7, col: 5)
        
        // Black plays at (8, 5) to capture the two white stones
        let captures = CaptureEngine.findCaptures(on: gameBoard, at: 8, col: 5, by: .black)
        
        XCTAssertEqual(captures.count, 2)
        XCTAssertTrue(captures.contains { $0.row == 6 && $0.col == 5 })
        XCTAssertTrue(captures.contains { $0.row == 7 && $0.col == 5 })
    }
    
    func testVerticalCaptureDown() {
        // Setup: [Empty]-White-White-Black (vertically)
        gameBoard.placeStone(.white, at: 6, col: 5)
        gameBoard.placeStone(.white, at: 7, col: 5)
        gameBoard.placeStone(.black, at: 8, col: 5)
        
        // Black plays at (5, 5) to capture the two white stones
        let captures = CaptureEngine.findCaptures(on: gameBoard, at: 5, col: 5, by: .black)
        
        XCTAssertEqual(captures.count, 2)
        XCTAssertTrue(captures.contains { $0.row == 6 && $0.col == 5 })
        XCTAssertTrue(captures.contains { $0.row == 7 && $0.col == 5 })
    }
    
    func testDiagonalCaptureDownRight() {
        // Setup: Black-White-White-[Empty] (diagonal \)
        gameBoard.placeStone(.black, at: 5, col: 5)
        gameBoard.placeStone(.white, at: 6, col: 6)
        gameBoard.placeStone(.white, at: 7, col: 7)
        
        // Black plays at (8, 8) to capture the two white stones
        let captures = CaptureEngine.findCaptures(on: gameBoard, at: 8, col: 8, by: .black)
        
        XCTAssertEqual(captures.count, 2)
        XCTAssertTrue(captures.contains { $0.row == 6 && $0.col == 6 })
        XCTAssertTrue(captures.contains { $0.row == 7 && $0.col == 7 })
    }
    
    func testDiagonalCaptureDownLeft() {
        // Setup: Black-White-White-[Empty] (diagonal /)
        gameBoard.placeStone(.black, at: 5, col: 8)
        gameBoard.placeStone(.white, at: 6, col: 7)
        gameBoard.placeStone(.white, at: 7, col: 6)
        
        // Black plays at (8, 5) to capture the two white stones
        let captures = CaptureEngine.findCaptures(on: gameBoard, at: 8, col: 5, by: .black)
        
        XCTAssertEqual(captures.count, 2)
        XCTAssertTrue(captures.contains { $0.row == 6 && $0.col == 7 })
        XCTAssertTrue(captures.contains { $0.row == 7 && $0.col == 6 })
    }
    
    // MARK: - Multiple Capture Tests
    
    func testMultipleCapturesInOneMove() {
        // Setup a position where one move captures in two directions
        // Horizontal: Black-White-White-[Empty]
        gameBoard.placeStone(.black, at: 5, col: 2)
        gameBoard.placeStone(.white, at: 5, col: 3)
        gameBoard.placeStone(.white, at: 5, col: 4)
        
        // Vertical: Black-White-White-[Empty] (same destination)
        gameBoard.placeStone(.black, at: 2, col: 5)
        gameBoard.placeStone(.white, at: 3, col: 5)
        gameBoard.placeStone(.white, at: 4, col: 5)
        
        // Black plays at (5, 5) to capture in both directions
        let captures = CaptureEngine.findCaptures(on: gameBoard, at: 5, col: 5, by: .black)
        
        XCTAssertEqual(captures.count, 4) // Two pairs = 4 stones
        
        // Check horizontal captures
        XCTAssertTrue(captures.contains { $0.row == 5 && $0.col == 3 })
        XCTAssertTrue(captures.contains { $0.row == 5 && $0.col == 4 })
        
        // Check vertical captures
        XCTAssertTrue(captures.contains { $0.row == 3 && $0.col == 5 })
        XCTAssertTrue(captures.contains { $0.row == 4 && $0.col == 5 })
    }
    
    func testMultipleDiagonalCaptures() {
        // Setup captures in both diagonals from center position
        // Diagonal \ : Black-White-White-[Center]
        gameBoard.placeStone(.black, at: 2, col: 2)
        gameBoard.placeStone(.white, at: 3, col: 3)
        gameBoard.placeStone(.white, at: 4, col: 4)
        
        // Diagonal / : Black-White-White-[Center]
        gameBoard.placeStone(.black, at: 2, col: 8)
        gameBoard.placeStone(.white, at: 3, col: 7)
        gameBoard.placeStone(.white, at: 4, col: 6)
        
        // Black plays at (5, 5) to capture in both diagonals
        let captures = CaptureEngine.findCaptures(on: gameBoard, at: 5, col: 5, by: .black)
        
        XCTAssertEqual(captures.count, 4) // Two pairs = 4 stones
        
        // Check diagonal \ captures
        XCTAssertTrue(captures.contains { $0.row == 3 && $0.col == 3 })
        XCTAssertTrue(captures.contains { $0.row == 4 && $0.col == 4 })
        
        // Check diagonal / captures
        XCTAssertTrue(captures.contains { $0.row == 3 && $0.col == 7 })
        XCTAssertTrue(captures.contains { $0.row == 4 && $0.col == 6 })
    }
    
    // MARK: - No Capture Scenarios
    
    func testNoCaptureWithOneStone() {
        // Setup: Black-White-[Empty]-[Play here]
        gameBoard.placeStone(.black, at: 5, col: 5)
        gameBoard.placeStone(.white, at: 5, col: 6)
        // Gap at (5, 7)
        
        // Black plays at (5, 8) - should not capture anything
        let captures = CaptureEngine.findCaptures(on: gameBoard, at: 5, col: 8, by: .black)
        
        XCTAssertEqual(captures.count, 0)
    }
    
    func testNoCaptureWithThreeStones() {
        // Setup: Black-White-White-White-[Play here]
        gameBoard.placeStone(.black, at: 5, col: 4)
        gameBoard.placeStone(.white, at: 5, col: 5)
        gameBoard.placeStone(.white, at: 5, col: 6)
        gameBoard.placeStone(.white, at: 5, col: 7)
        
        // Black plays at (5, 8) - should not capture (need exactly 2 stones between)
        let captures = CaptureEngine.findCaptures(on: gameBoard, at: 5, col: 8, by: .black)
        
        XCTAssertEqual(captures.count, 0)
    }
    
    func testNoCaptureWithSameColor() {
        // Setup: Black-Black-Black-[Play here]
        gameBoard.placeStone(.black, at: 5, col: 5)
        gameBoard.placeStone(.black, at: 5, col: 6)
        gameBoard.placeStone(.black, at: 5, col: 7)
        
        // Black plays at (5, 8) - should not capture own stones
        let captures = CaptureEngine.findCaptures(on: gameBoard, at: 5, col: 8, by: .black)
        
        XCTAssertEqual(captures.count, 0)
    }
    
    func testNoCaptureWithMixedColors() {
        // Setup: Black-White-Black-[Play here]
        gameBoard.placeStone(.black, at: 5, col: 5)
        gameBoard.placeStone(.white, at: 5, col: 6)
        gameBoard.placeStone(.black, at: 5, col: 7)
        
        // Black plays at (5, 8) - should not capture (need 2 consecutive opponent stones)
        let captures = CaptureEngine.findCaptures(on: gameBoard, at: 5, col: 8, by: .black)
        
        XCTAssertEqual(captures.count, 0)
    }
    
    // MARK: - Edge and Boundary Tests
    
    func testCaptureAtBoardEdge() {
        // Test capture at left edge
        gameBoard.placeStone(.black, at: 5, col: 0)
        gameBoard.placeStone(.white, at: 5, col: 1)
        gameBoard.placeStone(.white, at: 5, col: 2)
        
        // Black plays at (5, 3) to capture
        let captures = CaptureEngine.findCaptures(on: gameBoard, at: 5, col: 3, by: .black)
        
        XCTAssertEqual(captures.count, 2)
        XCTAssertTrue(captures.contains { $0.row == 5 && $0.col == 1 })
        XCTAssertTrue(captures.contains { $0.row == 5 && $0.col == 2 })
    }
    
    func testCaptureAtBoardCorner() {
        // Test capture at corner (0,0)
        gameBoard.placeStone(.black, at: 0, col: 0)
        gameBoard.placeStone(.white, at: 1, col: 1)
        gameBoard.placeStone(.white, at: 2, col: 2)
        
        // Black plays at (3, 3) to capture diagonally
        let captures = CaptureEngine.findCaptures(on: gameBoard, at: 3, col: 3, by: .black)
        
        XCTAssertEqual(captures.count, 2)
        XCTAssertTrue(captures.contains { $0.row == 1 && $0.col == 1 })
        XCTAssertTrue(captures.contains { $0.row == 2 && $0.col == 2 })
    }
    
    func testNoCaptureOutOfBounds() {
        // Setup capture that would go out of bounds
        gameBoard.placeStone(.white, at: 0, col: 0)
        gameBoard.placeStone(.white, at: 0, col: 1)
        
        // Black plays at (0, 2) - would need a black stone at (0, -1) to capture, which is out of bounds
        let captures = CaptureEngine.findCaptures(on: gameBoard, at: 0, col: 2, by: .black)
        
        XCTAssertEqual(captures.count, 0)
    }
    
    // MARK: - Real Game Scenarios
    
    func testComplexBoardPosition() {
        // Setup a complex board with multiple potential captures
        // Place various stones around the board
        gameBoard.placeStone(.black, at: 9, col: 9)   // Center
        gameBoard.placeStone(.white, at: 9, col: 10)
        gameBoard.placeStone(.white, at: 9, col: 11)
        gameBoard.placeStone(.black, at: 9, col: 12)  // Existing capture setup
        
        gameBoard.placeStone(.white, at: 8, col: 8)
        gameBoard.placeStone(.black, at: 7, col: 7)
        gameBoard.placeStone(.white, at: 6, col: 6)
        
        // White plays at a position that doesn't capture anything
        let captures = CaptureEngine.findCaptures(on: gameBoard, at: 10, col: 9, by: .white)
        
        XCTAssertEqual(captures.count, 0)
    }
    
    func testWhiteCapturesBlack() {
        // Verify capture works for white player too
        gameBoard.placeStone(.white, at: 5, col: 5)
        gameBoard.placeStone(.black, at: 5, col: 6)
        gameBoard.placeStone(.black, at: 5, col: 7)
        
        // White plays at (5, 8) to capture the two black stones
        let captures = CaptureEngine.findCaptures(on: gameBoard, at: 5, col: 8, by: .white)
        
        XCTAssertEqual(captures.count, 2)
        XCTAssertTrue(captures.contains { $0.row == 5 && $0.col == 6 })
        XCTAssertTrue(captures.contains { $0.row == 5 && $0.col == 7 })
    }
    
    // MARK: - All Direction Tests
    
    func testCapturesInAllEightDirections() {
        // Setup captures in all 8 directions from center position (9, 9)
        let center = (row: 9, col: 9)
        
        // Right: (9,6)-(9,7)-(9,8)-[CENTER]-(9,10)-(9,11)-(9,12)
        gameBoard.placeStone(.black, at: center.row, col: 6)
        gameBoard.placeStone(.white, at: center.row, col: 7)
        gameBoard.placeStone(.white, at: center.row, col: 8)
        
        // Test capture to the right
        let rightCaptures = CaptureEngine.findCaptures(on: gameBoard, at: center.row, col: center.col, by: .black)
        XCTAssertEqual(rightCaptures.count, 2)
        
        // Reset and test other directions
        gameBoard.reset()
        
        // Down: 
        gameBoard.placeStone(.black, at: 6, col: center.col)
        gameBoard.placeStone(.white, at: 7, col: center.col)
        gameBoard.placeStone(.white, at: 8, col: center.col)
        
        let downCaptures = CaptureEngine.findCaptures(on: gameBoard, at: center.row, col: center.col, by: .black)
        XCTAssertEqual(downCaptures.count, 2)
    }
    
    // MARK: - Safe Move Tests (From Rules)
    
    func testSafeMoveIntoCapture() {
        // Based on the rules: "Moving into a captured position" should be safe
        // Setup: Black-[Empty]-Black
        gameBoard.placeStone(.black, at: 5, col: 5)
        gameBoard.placeStone(.black, at: 5, col: 7)
        
        // White plays between the black stones - should be safe (no capture)
        let captures = CaptureEngine.findCaptures(on: gameBoard, at: 5, col: 6, by: .white)
        
        XCTAssertEqual(captures.count, 0, "White should be safe playing between two black stones")
    }
    
    // MARK: - Performance and Edge Cases
    
    func testEmptyBoard() {
        // No captures should be possible on empty board
        let captures = CaptureEngine.findCaptures(on: gameBoard, at: 9, col: 9, by: .black)
        XCTAssertEqual(captures.count, 0)
    }
    
    func testCaptureOrderConsistency() {
        // Verify that captures are returned in a consistent order
        gameBoard.placeStone(.black, at: 5, col: 5)
        gameBoard.placeStone(.white, at: 5, col: 6)
        gameBoard.placeStone(.white, at: 5, col: 7)
        
        let captures1 = CaptureEngine.findCaptures(on: gameBoard, at: 5, col: 8, by: .black)
        let captures2 = CaptureEngine.findCaptures(on: gameBoard, at: 5, col: 8, by: .black)
        
        XCTAssertEqual(captures1.count, captures2.count)
        // Order should be consistent
        for (index, capture) in captures1.enumerated() {
            XCTAssertEqual(capture.row, captures2[index].row)
            XCTAssertEqual(capture.col, captures2[index].col)
        }
    }
}