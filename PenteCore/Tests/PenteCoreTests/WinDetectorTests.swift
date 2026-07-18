import XCTest
@testable import PenteCore

final class WinDetectorTests: XCTestCase {

    var board: GameBoard!

    override func setUp() {
        super.setUp()
        board = GameBoard()
    }

    func testHorizontalFiveInARow() {
        for col in 5...9 {
            board.placeStone(.black, at: 10, col: col)
        }
        let line = WinDetector.checkFiveInARow(on: board, at: 10, col: 7, for: .black)
        XCTAssertEqual(line, (5...9).map { Position(row: 10, col: $0) })
    }

    func testVerticalFiveInARow() {
        for row in 5...9 {
            board.placeStone(.white, at: row, col: 10)
        }
        let line = WinDetector.checkFiveInARow(on: board, at: 7, col: 10, for: .white)
        XCTAssertEqual(line, (5...9).map { Position(row: $0, col: 10) })
    }

    func testDiagonalDownRightFiveInARow() {
        for i in 0...4 {
            board.placeStone(.black, at: 5 + i, col: 5 + i)
        }
        let line = WinDetector.checkFiveInARow(on: board, at: 7, col: 7, for: .black)
        XCTAssertEqual(line, (0...4).map { Position(row: 5 + $0, col: 5 + $0) })
    }

    func testDiagonalDownLeftFiveInARow() {
        for i in 0...4 {
            board.placeStone(.white, at: 5 + i, col: 9 - i)
        }
        let line = WinDetector.checkFiveInARow(on: board, at: 7, col: 7, for: .white)
        // Sorted by (row, col) ascending: (5,9), (6,8), (7,7), (8,6), (9,5)
        let expected = [
            Position(row: 5, col: 9),
            Position(row: 6, col: 8),
            Position(row: 7, col: 7),
            Position(row: 8, col: 6),
            Position(row: 9, col: 5),
        ]
        XCTAssertEqual(line, expected)
    }

    func testFourInARowDoesNotWin() {
        for col in 5...8 {
            board.placeStone(.black, at: 10, col: col)
        }
        XCTAssertNil(WinDetector.checkFiveInARow(on: board, at: 10, col: 7, for: .black))
    }

    func testCaptureWin() {
        XCTAssertTrue(WinDetector.checkCaptureWin(capturedCount: 5))
        XCTAssertTrue(WinDetector.checkCaptureWin(capturedCount: 10))
        XCTAssertFalse(WinDetector.checkCaptureWin(capturedCount: 4))
        XCTAssertFalse(WinDetector.checkCaptureWin(capturedCount: 0))
    }

    func testBrokenLineDoesNotWin() {
        board.placeStone(.black, at: 10, col: 5)
        board.placeStone(.black, at: 10, col: 6)
        // gap at 7
        board.placeStone(.black, at: 10, col: 8)
        board.placeStone(.black, at: 10, col: 9)
        board.placeStone(.black, at: 10, col: 10)
        XCTAssertNil(WinDetector.checkFiveInARow(on: board, at: 10, col: 5, for: .black))
    }

    func testEmptyBoard() {
        XCTAssertNil(WinDetector.checkFiveInARow(on: board, at: 9, col: 9, for: .black))
    }
}
