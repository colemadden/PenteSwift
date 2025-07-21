import XCTest
import UIKit
@testable import Pente_MessagesExtension

final class BoardImageGeneratorTests: XCTestCase {
    
    // MARK: - Basic Image Generation Tests
    
    func testGenerateEmptyBoardLight() {
        let emptyBoard = Array(repeating: Array(repeating: Optional<Player>.none, count: 19), count: 19)
        let moveHistory: [(row: Int, col: Int, player: Player)] = []
        
        let image = BoardImageGenerator.generateBoardImage(
            board: emptyBoard,
            moveHistory: moveHistory,
            size: CGSize(width: 300, height: 300),
            colorScheme: .light
        )
        
        XCTAssertNotNil(image)
        XCTAssertEqual(image?.size.width, 300)
        XCTAssertEqual(image?.size.height, 300)
    }
    
    func testGenerateEmptyBoardDark() {
        let emptyBoard = Array(repeating: Array(repeating: Optional<Player>.none, count: 19), count: 19)
        let moveHistory: [(row: Int, col: Int, player: Player)] = []
        
        let image = BoardImageGenerator.generateBoardImage(
            board: emptyBoard,
            moveHistory: moveHistory,
            size: CGSize(width: 300, height: 300),
            colorScheme: .dark
        )
        
        XCTAssertNotNil(image)
        XCTAssertEqual(image?.size.width, 300)
        XCTAssertEqual(image?.size.height, 300)
    }
    
    func testGenerateBoardWithSingleStone() {
        var board = Array(repeating: Array(repeating: Optional<Player>.none, count: 19), count: 19)
        board[9][9] = .black
        let moveHistory = [(row: 9, col: 9, player: Player.black)]
        
        let image = BoardImageGenerator.generateBoardImage(
            board: board,
            moveHistory: moveHistory,
            size: CGSize(width: 300, height: 300),
            colorScheme: .light
        )
        
        XCTAssertNotNil(image)
        XCTAssertEqual(image?.size.width, 300)
        XCTAssertEqual(image?.size.height, 300)
    }
    
    func testGenerateBoardWithMultipleStones() {
        var board = Array(repeating: Array(repeating: Optional<Player>.none, count: 19), count: 19)
        board[9][9] = .black
        board[10][10] = .white
        board[8][8] = .black
        board[11][11] = .white
        
        let moveHistory = [
            (row: 9, col: 9, player: Player.black),
            (row: 10, col: 10, player: Player.white),
            (row: 8, col: 8, player: Player.black),
            (row: 11, col: 11, player: Player.white)
        ]
        
        let image = BoardImageGenerator.generateBoardImage(
            board: board,
            moveHistory: moveHistory,
            size: CGSize(width: 300, height: 300),
            colorScheme: .light
        )
        
        XCTAssertNotNil(image)
    }
    
    // MARK: - Size Variation Tests
    
    func testVariousImageSizes() {
        let emptyBoard = Array(repeating: Array(repeating: Optional<Player>.none, count: 19), count: 19)
        let moveHistory: [(row: Int, col: Int, player: Player)] = []
        
        let sizes = [
            CGSize(width: 100, height: 100),
            CGSize(width: 200, height: 200),
            CGSize(width: 400, height: 400),
            CGSize(width: 150, height: 150),
            CGSize(width: 300, height: 300)
        ]
        
        for size in sizes {
            let image = BoardImageGenerator.generateBoardImage(
                board: emptyBoard,
                moveHistory: moveHistory,
                size: size,
                colorScheme: .light
            )
            
            XCTAssertNotNil(image, "Image should be generated for size \(size)")
            XCTAssertEqual(image?.size.width, size.width)
            XCTAssertEqual(image?.size.height, size.height)
        }
    }
    
    func testSquareImageSizes() {
        let emptyBoard = Array(repeating: Array(repeating: Optional<Player>.none, count: 19), count: 19)
        let moveHistory: [(row: Int, col: Int, player: Player)] = []
        
        let squareSizes: [CGFloat] = [50, 100, 200, 300, 500]
        
        for sideLength in squareSizes {
            let size = CGSize(width: sideLength, height: sideLength)
            let image = BoardImageGenerator.generateBoardImage(
                board: emptyBoard,
                moveHistory: moveHistory,
                size: size,
                colorScheme: .light
            )
            
            XCTAssertNotNil(image)
            XCTAssertEqual(image?.size.width, sideLength)
            XCTAssertEqual(image?.size.height, sideLength)
        }
    }
    
    // MARK: - Color Scheme Tests
    
    func testBothColorSchemes() {
        var board = Array(repeating: Array(repeating: Optional<Player>.none, count: 19), count: 19)
        board[9][9] = .black
        board[10][10] = .white
        
        let moveHistory = [
            (row: 9, col: 9, player: Player.black),
            (row: 10, col: 10, player: Player.white)
        ]
        
        let lightImage = BoardImageGenerator.generateBoardImage(
            board: board,
            moveHistory: moveHistory,
            size: CGSize(width: 300, height: 300),
            colorScheme: .light
        )
        
        let darkImage = BoardImageGenerator.generateBoardImage(
            board: board,
            moveHistory: moveHistory,
            size: CGSize(width: 300, height: 300),
            colorScheme: .dark
        )
        
        XCTAssertNotNil(lightImage)
        XCTAssertNotNil(darkImage)
        
        // Images should be different due to different color schemes
        // Note: Comparing image data would be complex, so we just verify they generate
        XCTAssertEqual(lightImage?.size, darkImage?.size)
    }
    
    // MARK: - Last Move Highlighting Tests
    
    func testLastMoveHighlighting() {
        var board = Array(repeating: Array(repeating: Optional<Player>.none, count: 19), count: 19)
        board[9][9] = .black
        board[10][10] = .white
        board[11][11] = .black
        
        let moveHistory = [
            (row: 9, col: 9, player: Player.black),
            (row: 10, col: 10, player: Player.white),
            (row: 11, col: 11, player: Player.black) // Last move
        ]
        
        let image = BoardImageGenerator.generateBoardImage(
            board: board,
            moveHistory: moveHistory,
            size: CGSize(width: 300, height: 300),
            colorScheme: .light
        )
        
        XCTAssertNotNil(image)
        // Last move should be highlighted with blue ring, but we can't easily test visual content
    }
    
    func testNoLastMoveWhenHistoryEmpty() {
        var board = Array(repeating: Array(repeating: Optional<Player>.none, count: 19), count: 19)
        board[9][9] = .black
        
        let moveHistory: [(row: Int, col: Int, player: Player)] = [] // Empty history
        
        let image = BoardImageGenerator.generateBoardImage(
            board: board,
            moveHistory: moveHistory,
            size: CGSize(width: 300, height: 300),
            colorScheme: .light
        )
        
        XCTAssertNotNil(image)
        // Should not crash when there's no last move to highlight
    }
    
    // MARK: - Edge Position Tests
    
    func testStonesAtEdgesAndCorners() {
        var board = Array(repeating: Array(repeating: Optional<Player>.none, count: 19), count: 19)
        
        // Place stones at corners
        board[0][0] = .black
        board[0][18] = .white
        board[18][0] = .white
        board[18][18] = .black
        
        // Place stones at edge midpoints
        board[0][9] = .black
        board[18][9] = .white
        board[9][0] = .white
        board[9][18] = .black
        
        let moveHistory = [
            (row: 0, col: 0, player: Player.black),
            (row: 0, col: 18, player: Player.white),
            (row: 18, col: 0, player: Player.white),
            (row: 18, col: 18, player: Player.black),
            (row: 0, col: 9, player: Player.black),
            (row: 18, col: 9, player: Player.white),
            (row: 9, col: 0, player: Player.white),
            (row: 9, col: 18, player: Player.black)
        ]
        
        let image = BoardImageGenerator.generateBoardImage(
            board: board,
            moveHistory: moveHistory,
            size: CGSize(width: 300, height: 300),
            colorScheme: .light
        )
        
        XCTAssertNotNil(image)
        // Should handle edge positions without issues
    }
    
    // MARK: - Full Board Tests
    
    func testFullBoard() {
        var board = Array(repeating: Array(repeating: Optional<Player>.none, count: 19), count: 19)
        var moveHistory: [(row: Int, col: Int, player: Player)] = []
        
        // Fill board with alternating pattern
        for row in 0..<19 {
            for col in 0..<19 {
                let player: Player = (row + col) % 2 == 0 ? .black : .white
                board[row][col] = player
                moveHistory.append((row: row, col: col, player: player))
            }
        }
        
        let image = BoardImageGenerator.generateBoardImage(
            board: board,
            moveHistory: moveHistory,
            size: CGSize(width: 300, height: 300),
            colorScheme: .light
        )
        
        XCTAssertNotNil(image)
        // Should handle full board without performance issues
    }
    
    // MARK: - Error Handling Tests
    
    func testEmptyBoardArray() {
        let emptyBoard: [[Player?]] = []
        let moveHistory: [(row: Int, col: Int, player: Player)] = []
        
        let image = BoardImageGenerator.generateBoardImage(
            board: emptyBoard,
            moveHistory: moveHistory,
            size: CGSize(width: 300, height: 300),
            colorScheme: .light
        )
        
        // Should either return nil or a blank image without crashing
        // The exact behavior depends on implementation, but it shouldn't crash
    }
    
    func testInvalidBoardSize() {
        // Create board that's not 19x19
        let invalidBoard = Array(repeating: Array(repeating: Optional<Player>.none, count: 10), count: 10)
        let moveHistory: [(row: Int, col: Int, player: Player)] = []
        
        let image = BoardImageGenerator.generateBoardImage(
            board: invalidBoard,
            moveHistory: moveHistory,
            size: CGSize(width: 300, height: 300),
            colorScheme: .light
        )
        
        // Should handle gracefully without crashing
        XCTAssertNotNil(image)
    }
    
    func testZeroSize() {
        let emptyBoard = Array(repeating: Array(repeating: Optional<Player>.none, count: 19), count: 19)
        let moveHistory: [(row: Int, col: Int, player: Player)] = []
        
        let image = BoardImageGenerator.generateBoardImage(
            board: emptyBoard,
            moveHistory: moveHistory,
            size: CGSize(width: 0, height: 0),
            colorScheme: .light
        )
        
        // Should handle zero size gracefully
        if let image = image {
            XCTAssertEqual(image.size.width, 0)
            XCTAssertEqual(image.size.height, 0)
        }
    }
    
    func testVerySmallSize() {
        let emptyBoard = Array(repeating: Array(repeating: Optional<Player>.none, count: 19), count: 19)
        let moveHistory: [(row: Int, col: Int, player: Player)] = []
        
        let image = BoardImageGenerator.generateBoardImage(
            board: emptyBoard,
            moveHistory: moveHistory,
            size: CGSize(width: 1, height: 1),
            colorScheme: .light
        )
        
        XCTAssertNotNil(image)
        XCTAssertEqual(image?.size.width, 1)
        XCTAssertEqual(image?.size.height, 1)
    }
    
    func testVeryLargeSize() {
        let emptyBoard = Array(repeating: Array(repeating: Optional<Player>.none, count: 19), count: 19)
        let moveHistory: [(row: Int, col: Int, player: Player)] = []
        
        let image = BoardImageGenerator.generateBoardImage(
            board: emptyBoard,
            moveHistory: moveHistory,
            size: CGSize(width: 2000, height: 2000),
            colorScheme: .light
        )
        
        XCTAssertNotNil(image)
        XCTAssertEqual(image?.size.width, 2000)
        XCTAssertEqual(image?.size.height, 2000)
    }
    
    // MARK: - Move History Mismatch Tests
    
    func testMoveHistoryMismatchBoard() {
        var board = Array(repeating: Array(repeating: Optional<Player>.none, count: 19), count: 19)
        board[9][9] = .black
        board[10][10] = .white
        
        // Move history doesn't match board state
        let moveHistory = [
            (row: 5, col: 5, player: Player.black),
            (row: 6, col: 6, player: Player.white)
        ]
        
        let image = BoardImageGenerator.generateBoardImage(
            board: board,
            moveHistory: moveHistory,
            size: CGSize(width: 300, height: 300),
            colorScheme: .light
        )
        
        XCTAssertNotNil(image)
        // Should render board as-is and highlight last move from history if valid
    }
    
    func testInvalidLastMovePosition() {
        var board = Array(repeating: Array(repeating: Optional<Player>.none, count: 19), count: 19)
        board[9][9] = .black
        
        // Last move is out of bounds
        let moveHistory = [
            (row: -1, col: 20, player: Player.black) // Invalid position
        ]
        
        let image = BoardImageGenerator.generateBoardImage(
            board: board,
            moveHistory: moveHistory,
            size: CGSize(width: 300, height: 300),
            colorScheme: .light
        )
        
        XCTAssertNotNil(image)
        // Should not crash even with invalid last move position
    }
    
    // MARK: - Performance Tests
    
    func testGenerateMultpleImagesQuickly() {
        var board = Array(repeating: Array(repeating: Optional<Player>.none, count: 19), count: 19)
        board[9][9] = .black
        board[10][10] = .white
        
        let moveHistory = [
            (row: 9, col: 9, player: Player.black),
            (row: 10, col: 10, player: Player.white)
        ]
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Generate multiple images
        for _ in 0..<10 {
            let image = BoardImageGenerator.generateBoardImage(
                board: board,
                moveHistory: moveHistory,
                size: CGSize(width: 300, height: 300),
                colorScheme: .light
            )
            XCTAssertNotNil(image)
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = endTime - startTime
        
        // Should complete reasonably quickly (less than 1 second for 10 images)
        XCTAssertLessThan(totalTime, 1.0, "Image generation should be reasonably fast")
    }
    
    // MARK: - Consistency Tests
    
    func testConsistentImageGeneration() {
        var board = Array(repeating: Array(repeating: Optional<Player>.none, count: 19), count: 19)
        board[9][9] = .black
        board[10][10] = .white
        
        let moveHistory = [
            (row: 9, col: 9, player: Player.black),
            (row: 10, col: 10, player: Player.white)
        ]
        
        let image1 = BoardImageGenerator.generateBoardImage(
            board: board,
            moveHistory: moveHistory,
            size: CGSize(width: 300, height: 300),
            colorScheme: .light
        )
        
        let image2 = BoardImageGenerator.generateBoardImage(
            board: board,
            moveHistory: moveHistory,
            size: CGSize(width: 300, height: 300),
            colorScheme: .light
        )
        
        XCTAssertNotNil(image1)
        XCTAssertNotNil(image2)
        XCTAssertEqual(image1?.size, image2?.size)
        
        // Images should be identical for same input
        // Note: Direct pixel comparison would be complex, but size should match
    }
}