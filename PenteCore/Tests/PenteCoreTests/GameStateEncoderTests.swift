import XCTest
@testable import PenteCore

final class GameStateEncoderTests: XCTestCase {

    func testEncodeEmptyGame() {
        let queryItems = GameStateEncoder.encodeToQueryItems(
            moveHistory: [],
            currentPlayer: .black,
            capturedCount: [.black: 0, .white: 0],
            gameState: .playing
        )

        XCTAssertTrue(queryItems.contains { $0.name == "current" && $0.value == "Black" })
        XCTAssertTrue(queryItems.contains { $0.name == "state" && $0.value == "playing" })
        XCTAssertFalse(queryItems.contains { $0.name == "moves" })
    }

    func testEncodeMoves() {
        let moveHistory = [
            (row: 9, col: 9, player: Player.black),
            (row: 10, col: 10, player: Player.white),
        ]

        let queryItems = GameStateEncoder.encodeToQueryItems(
            moveHistory: moveHistory,
            currentPlayer: .black,
            capturedCount: [.black: 0, .white: 0],
            gameState: .playing
        )

        let movesItem = queryItems.first { $0.name == "moves" }
        XCTAssertEqual(movesItem?.value, "B9,9;W10,10;")
    }

    func testEncodeWonGame() {
        let queryItems = GameStateEncoder.encodeToQueryItems(
            moveHistory: [],
            currentPlayer: .black,
            capturedCount: [.black: 0, .white: 0],
            gameState: .won(by: .black, method: .fiveInARow)
        )

        XCTAssertTrue(queryItems.contains { $0.name == "state" && $0.value == "won" })
        XCTAssertTrue(queryItems.contains { $0.name == "winner" && $0.value == "Black" })
        XCTAssertTrue(queryItems.contains { $0.name == "method" && $0.value == "fiveInARow" })
    }

    func testDecodeRoundTrip() {
        let original = [
            (row: 9, col: 9, player: Player.black),
            (row: 10, col: 10, player: Player.white),
        ]

        let queryItems = GameStateEncoder.encodeToQueryItems(
            moveHistory: original,
            currentPlayer: .black,
            capturedCount: [.black: 0, .white: 0],
            gameState: .playing
        )

        var components = URLComponents()
        components.scheme = "pente"
        components.host = "game"
        components.queryItems = queryItems

        guard let decoded = GameStateDecoder.decodeFromURL(components.url!) else {
            XCTFail("Should decode"); return
        }

        XCTAssertEqual(decoded.moveHistory.count, 2)
        XCTAssertEqual(decoded.currentPlayer, .black)
        XCTAssertEqual(decoded.board[9, 9], .black)
        XCTAssertEqual(decoded.board[10, 10], .white)
    }

    func testDecodeCaptureReplay() {
        let url = URL(string: "pente://game?moves=B5,5;W5,6;W5,7;B5,8;&current=White&capB=0&capW=0&state=playing")!

        guard let decoded = GameStateDecoder.decodeFromURL(url) else {
            XCTFail("Should decode"); return
        }

        XCTAssertEqual(decoded.capturedCount[.black], 1)
        XCTAssertNil(decoded.board[5, 6])
        XCTAssertNil(decoded.board[5, 7])
    }

    func testDecodeInvalidURL() {
        let url = URL(string: "invalid://url")!
        XCTAssertNil(GameStateDecoder.decodeFromURL(url))
    }

    func testBlackPlayerIDRoundTrip() {
        let queryItems = GameStateEncoder.encodeToQueryItems(
            moveHistory: [],
            currentPlayer: .black,
            capturedCount: [.black: 0, .white: 0],
            gameState: .playing,
            blackPlayerID: "test-id-123"
        )

        var components = URLComponents()
        components.scheme = "pente"
        components.host = "game"
        components.queryItems = queryItems

        guard let decoded = GameStateDecoder.decodeFromURL(components.url!) else {
            XCTFail("Should decode"); return
        }

        XCTAssertEqual(decoded.blackPlayerID, "test-id-123")
    }
}
