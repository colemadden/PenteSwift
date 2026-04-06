import XCTest
@testable import PenteCore

final class CaptureEngineTests: XCTestCase {

    var board: GameBoard!

    override func setUp() {
        super.setUp()
        board = GameBoard()
    }

    func testHorizontalCapture() {
        board.placeStone(.black, at: 5, col: 5)
        board.placeStone(.white, at: 5, col: 6)
        board.placeStone(.white, at: 5, col: 7)

        let captures = CaptureEngine.findCaptures(on: board, at: 5, col: 8, by: .black)
        XCTAssertEqual(captures.count, 2)
    }

    func testVerticalCapture() {
        board.placeStone(.black, at: 5, col: 5)
        board.placeStone(.white, at: 6, col: 5)
        board.placeStone(.white, at: 7, col: 5)

        let captures = CaptureEngine.findCaptures(on: board, at: 8, col: 5, by: .black)
        XCTAssertEqual(captures.count, 2)
    }

    func testDiagonalCapture() {
        board.placeStone(.black, at: 5, col: 5)
        board.placeStone(.white, at: 6, col: 6)
        board.placeStone(.white, at: 7, col: 7)

        let captures = CaptureEngine.findCaptures(on: board, at: 8, col: 8, by: .black)
        XCTAssertEqual(captures.count, 2)
    }

    func testMultipleCaptures() {
        // Horizontal
        board.placeStone(.black, at: 5, col: 2)
        board.placeStone(.white, at: 5, col: 3)
        board.placeStone(.white, at: 5, col: 4)
        // Vertical
        board.placeStone(.black, at: 2, col: 5)
        board.placeStone(.white, at: 3, col: 5)
        board.placeStone(.white, at: 4, col: 5)

        let captures = CaptureEngine.findCaptures(on: board, at: 5, col: 5, by: .black)
        XCTAssertEqual(captures.count, 4)
    }

    func testNoCapture() {
        board.placeStone(.black, at: 5, col: 5)
        board.placeStone(.white, at: 5, col: 6)

        let captures = CaptureEngine.findCaptures(on: board, at: 5, col: 8, by: .black)
        XCTAssertEqual(captures.count, 0)
    }

    func testNoCaptureOwnStones() {
        board.placeStone(.black, at: 5, col: 5)
        board.placeStone(.black, at: 5, col: 6)
        board.placeStone(.black, at: 5, col: 7)

        let captures = CaptureEngine.findCaptures(on: board, at: 5, col: 8, by: .black)
        XCTAssertEqual(captures.count, 0)
    }

    func testEmptyBoard() {
        let captures = CaptureEngine.findCaptures(on: board, at: 9, col: 9, by: .black)
        XCTAssertEqual(captures.count, 0)
    }
}
