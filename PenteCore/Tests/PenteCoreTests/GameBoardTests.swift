import XCTest
@testable import PenteCore

final class GameBoardTests: XCTestCase {

    var board: GameBoard!

    override func setUp() {
        super.setUp()
        board = GameBoard()
    }

    func testInitialization() {
        XCTAssertEqual(GameBoard.size, 19)
        for row in 0..<19 {
            for col in 0..<19 {
                XCTAssertNil(board[row, col])
            }
        }
    }

    func testPlaceAndRemoveStone() {
        board.placeStone(.black, at: 9, col: 9)
        XCTAssertEqual(board[9, 9], .black)

        board.removeStone(at: 9, col: 9)
        XCTAssertNil(board[9, 9])
    }

    func testIsEmpty() {
        XCTAssertTrue(board.isEmpty(at: 9, col: 9))
        board.placeStone(.black, at: 9, col: 9)
        XCTAssertFalse(board.isEmpty(at: 9, col: 9))
    }

    func testIsValidPosition() {
        XCTAssertTrue(board.isValidPosition(0, 0))
        XCTAssertTrue(board.isValidPosition(18, 18))
        XCTAssertFalse(board.isValidPosition(-1, 0))
        XCTAssertFalse(board.isValidPosition(19, 0))
    }

    func testReset() {
        board.placeStone(.black, at: 9, col: 9)
        board.placeStone(.white, at: 0, col: 0)
        board.reset()

        for row in 0..<19 {
            for col in 0..<19 {
                XCTAssertNil(board[row, col])
            }
        }
    }

    func testAsArray() {
        board.placeStone(.black, at: 5, col: 5)
        let arr = board.asArray
        XCTAssertEqual(arr[5][5], .black)
        XCTAssertNil(arr[0][0])
    }

    func testInvalidPositionSafety() {
        board.placeStone(.black, at: -1, col: 0)
        board.placeStone(.black, at: 19, col: 0)
        board.removeStone(at: -1, col: 0)
        XCTAssertNil(board[-1, 0])
        XCTAssertFalse(board.isEmpty(at: -1, col: 0))
    }
}
