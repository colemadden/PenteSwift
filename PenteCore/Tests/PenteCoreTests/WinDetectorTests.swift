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
        XCTAssertTrue(WinDetector.checkFiveInARow(on: board, at: 10, col: 7, for: .black))
    }

    func testVerticalFiveInARow() {
        for row in 5...9 {
            board.placeStone(.white, at: row, col: 10)
        }
        XCTAssertTrue(WinDetector.checkFiveInARow(on: board, at: 7, col: 10, for: .white))
    }

    func testDiagonalFiveInARow() {
        for i in 0...4 {
            board.placeStone(.black, at: 5 + i, col: 5 + i)
        }
        XCTAssertTrue(WinDetector.checkFiveInARow(on: board, at: 7, col: 7, for: .black))
    }

    func testFourInARowDoesNotWin() {
        for col in 5...8 {
            board.placeStone(.black, at: 10, col: col)
        }
        XCTAssertFalse(WinDetector.checkFiveInARow(on: board, at: 10, col: 7, for: .black))
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
        XCTAssertFalse(WinDetector.checkFiveInARow(on: board, at: 10, col: 5, for: .black))
    }

    func testEmptyBoard() {
        XCTAssertFalse(WinDetector.checkFiveInARow(on: board, at: 9, col: 9, for: .black))
    }
}
