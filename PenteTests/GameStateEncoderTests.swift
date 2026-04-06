import XCTest
import PenteCore

final class GameStateEncoderTests: XCTestCase {

    // MARK: - Encoding Tests

    func testEncodeEmptyGame() {
        let moveHistory: [(row: Int, col: Int, player: Player)] = []
        let currentPlayer: Player = .black
        let capturedCount: [Player: Int] = [.black: 0, .white: 0]
        let gameState: GameState = .playing

        let queryItems = GameStateEncoder.encodeToQueryItems(
            moveHistory: moveHistory,
            currentPlayer: currentPlayer,
            capturedCount: capturedCount,
            gameState: gameState
        )

        // Should have current player, capture counts, and game state
        XCTAssertEqual(queryItems.count, 4)

        // Check individual items
        XCTAssertTrue(queryItems.contains { $0.name == "current" && $0.value == "Black" })
        XCTAssertTrue(queryItems.contains { $0.name == "capB" && $0.value == "0" })
        XCTAssertTrue(queryItems.contains { $0.name == "capW" && $0.value == "0" })
        XCTAssertTrue(queryItems.contains { $0.name == "state" && $0.value == "playing" })

        // Should not have moves
        XCTAssertFalse(queryItems.contains { $0.name == "moves" })
    }

    func testEncodeSingleMove() {
        let moveHistory = [(row: 9, col: 9, player: Player.black)]
        let currentPlayer: Player = .white
        let capturedCount: [Player: Int] = [.black: 0, .white: 0]
        let gameState: GameState = .playing

        let queryItems = GameStateEncoder.encodeToQueryItems(
            moveHistory: moveHistory,
            currentPlayer: currentPlayer,
            capturedCount: capturedCount,
            gameState: gameState
        )

        // Should have moves now
        XCTAssertTrue(queryItems.contains { $0.name == "moves" && $0.value == "B9,9;" })
        XCTAssertTrue(queryItems.contains { $0.name == "current" && $0.value == "White" })
    }

    func testEncodeMultipleMoves() {
        let moveHistory = [
            (row: 9, col: 9, player: Player.black),
            (row: 10, col: 10, player: Player.white),
            (row: 8, col: 8, player: Player.black)
        ]
        let currentPlayer: Player = .white
        let capturedCount: [Player: Int] = [.black: 0, .white: 0]
        let gameState: GameState = .playing

        let queryItems = GameStateEncoder.encodeToQueryItems(
            moveHistory: moveHistory,
            currentPlayer: currentPlayer,
            capturedCount: capturedCount,
            gameState: gameState
        )

        let movesItem = queryItems.first { $0.name == "moves" }
        XCTAssertNotNil(movesItem)
        XCTAssertEqual(movesItem?.value, "B9,9;W10,10;B8,8;")
    }

    func testEncodeWithCaptures() {
        let moveHistory = [(row: 9, col: 9, player: Player.black)]
        let currentPlayer: Player = .white
        let capturedCount: [Player: Int] = [.black: 2, .white: 1]
        let gameState: GameState = .playing

        let queryItems = GameStateEncoder.encodeToQueryItems(
            moveHistory: moveHistory,
            currentPlayer: currentPlayer,
            capturedCount: capturedCount,
            gameState: gameState
        )

        XCTAssertTrue(queryItems.contains { $0.name == "capB" && $0.value == "2" })
        XCTAssertTrue(queryItems.contains { $0.name == "capW" && $0.value == "1" })
    }

    func testEncodeWonGame() {
        let moveHistory = [(row: 9, col: 9, player: Player.black)]
        let currentPlayer: Player = .black
        let capturedCount: [Player: Int] = [.black: 0, .white: 0]
        let gameState: GameState = .won(by: .black, method: .fiveInARow)

        let queryItems = GameStateEncoder.encodeToQueryItems(
            moveHistory: moveHistory,
            currentPlayer: currentPlayer,
            capturedCount: capturedCount,
            gameState: gameState
        )

        XCTAssertTrue(queryItems.contains { $0.name == "state" && $0.value == "won" })
        XCTAssertTrue(queryItems.contains { $0.name == "winner" && $0.value == "Black" })
        XCTAssertTrue(queryItems.contains { $0.name == "method" && $0.value == "fiveInARow" })
    }

    func testEncodeWonByCaptureGame() {
        let moveHistory = [(row: 9, col: 9, player: Player.white)]
        let currentPlayer: Player = .white
        let capturedCount: [Player: Int] = [.black: 0, .white: 5]
        let gameState: GameState = .won(by: .white, method: .fiveCaptures)

        let queryItems = GameStateEncoder.encodeToQueryItems(
            moveHistory: moveHistory,
            currentPlayer: currentPlayer,
            capturedCount: capturedCount,
            gameState: gameState
        )

        XCTAssertTrue(queryItems.contains { $0.name == "state" && $0.value == "won" })
        XCTAssertTrue(queryItems.contains { $0.name == "winner" && $0.value == "White" })
        XCTAssertTrue(queryItems.contains { $0.name == "method" && $0.value == "fiveCaptures" })
        XCTAssertTrue(queryItems.contains { $0.name == "capW" && $0.value == "5" })
    }

    // MARK: - Decoding Tests

    func testDecodeEmptyGame() {
        let url = URL(string: "pente://game?current=Black&capB=0&capW=0&state=playing")!

        guard let decoded = GameStateDecoder.decodeFromURL(url) else {
            XCTFail("Should decode successfully")
            return
        }

        XCTAssertEqual(decoded.currentPlayer, .black)
        XCTAssertEqual(decoded.capturedCount[.black], 0)
        XCTAssertEqual(decoded.capturedCount[.white], 0)
        XCTAssertEqual(decoded.gameState, .playing)
        XCTAssertEqual(decoded.moveHistory.count, 0)

        // Board should be empty
        for row in 0..<GameBoard.size {
            for col in 0..<GameBoard.size {
                XCTAssertNil(decoded.board[row, col])
            }
        }
    }

    func testDecodeSingleMove() {
        let url = URL(string: "pente://game?moves=B9,9;&current=White&capB=0&capW=0&state=playing")!

        guard let decoded = GameStateDecoder.decodeFromURL(url) else {
            XCTFail("Should decode successfully")
            return
        }

        XCTAssertEqual(decoded.currentPlayer, .white)
        XCTAssertEqual(decoded.moveHistory.count, 1)
        XCTAssertEqual(decoded.moveHistory[0].row, 9)
        XCTAssertEqual(decoded.moveHistory[0].col, 9)
        XCTAssertEqual(decoded.moveHistory[0].player, .black)
        XCTAssertEqual(decoded.board[9, 9], .black)
    }

    func testDecodeMultipleMoves() {
        let url = URL(string: "pente://game?moves=B9,9;W10,10;B8,8;&current=White&capB=0&capW=0&state=playing")!

        guard let decoded = GameStateDecoder.decodeFromURL(url) else {
            XCTFail("Should decode successfully")
            return
        }

        XCTAssertEqual(decoded.moveHistory.count, 3)

        XCTAssertEqual(decoded.moveHistory[0].row, 9)
        XCTAssertEqual(decoded.moveHistory[0].col, 9)
        XCTAssertEqual(decoded.moveHistory[0].player, .black)

        XCTAssertEqual(decoded.moveHistory[1].row, 10)
        XCTAssertEqual(decoded.moveHistory[1].col, 10)
        XCTAssertEqual(decoded.moveHistory[1].player, .white)

        XCTAssertEqual(decoded.moveHistory[2].row, 8)
        XCTAssertEqual(decoded.moveHistory[2].col, 8)
        XCTAssertEqual(decoded.moveHistory[2].player, .black)

        // Board should have the stones
        XCTAssertEqual(decoded.board[9, 9], .black)
        XCTAssertEqual(decoded.board[10, 10], .white)
        XCTAssertEqual(decoded.board[8, 8], .black)
    }

    func testDecodeCapturesComputedFromReplay() {
        // Capture counts are computed from move replay, not URL params
        // B5,5 W5,6 W5,7 B5,8 = black captures the two white stones
        let url = URL(string: "pente://game?moves=B5,5;W5,6;W5,7;B5,8;&current=White&capB=0&capW=0&state=playing")!

        guard let decoded = GameStateDecoder.decodeFromURL(url) else {
            XCTFail("Should decode successfully")
            return
        }

        // Captures computed from replay, not from URL params
        XCTAssertEqual(decoded.capturedCount[.black], 1) // 1 pair captured
        XCTAssertEqual(decoded.capturedCount[.white], 0)

        // Captured stones should be removed from board
        XCTAssertEqual(decoded.board[5, 5], .black)
        XCTAssertNil(decoded.board[5, 6])
        XCTAssertNil(decoded.board[5, 7])
        XCTAssertEqual(decoded.board[5, 8], .black)
    }

    func testDecodeWonGame() {
        let url = URL(string: "pente://game?current=Black&capB=0&capW=0&state=won&winner=Black&method=fiveInARow")!

        guard let decoded = GameStateDecoder.decodeFromURL(url) else {
            XCTFail("Should decode successfully")
            return
        }

        XCTAssertEqual(decoded.gameState, .won(by: .black, method: .fiveInARow))
    }

    func testDecodeWonByCaptureGame() {
        let url = URL(string: "pente://game?current=White&capB=0&capW=0&state=won&winner=White&method=fiveCaptures")!

        guard let decoded = GameStateDecoder.decodeFromURL(url) else {
            XCTFail("Should decode successfully")
            return
        }

        XCTAssertEqual(decoded.gameState, .won(by: .white, method: .fiveCaptures))
    }

    // MARK: - Round Trip Tests

    func testRoundTripEmptyGame() {
        let originalCurrentPlayer: Player = .black
        let originalGameState: GameState = .playing

        // Encode
        let queryItems = GameStateEncoder.encodeToQueryItems(
            moveHistory: [],
            currentPlayer: originalCurrentPlayer,
            capturedCount: [.black: 0, .white: 0],
            gameState: originalGameState
        )

        // Create URL
        var components = URLComponents()
        components.scheme = "pente"
        components.host = "game"
        components.queryItems = queryItems
        let url = components.url!

        // Decode
        guard let decoded = GameStateDecoder.decodeFromURL(url) else {
            XCTFail("Should decode successfully")
            return
        }

        // Verify round trip
        XCTAssertEqual(decoded.currentPlayer, originalCurrentPlayer)
        XCTAssertEqual(decoded.capturedCount[.black], 0)
        XCTAssertEqual(decoded.capturedCount[.white], 0)
        XCTAssertEqual(decoded.moveHistory.count, 0)
        XCTAssertEqual(decoded.gameState, originalGameState)
    }

    func testRoundTripComplexGame() {
        let originalMoveHistory = [
            (row: 9, col: 9, player: Player.black),
            (row: 10, col: 10, player: Player.white),
            (row: 8, col: 8, player: Player.black),
            (row: 11, col: 11, player: Player.white)
        ]
        let originalCurrentPlayer: Player = .black
        let originalGameState: GameState = .playing

        // Encode
        let queryItems = GameStateEncoder.encodeToQueryItems(
            moveHistory: originalMoveHistory,
            currentPlayer: originalCurrentPlayer,
            capturedCount: [.black: 0, .white: 0],
            gameState: originalGameState
        )

        // Create URL
        var components = URLComponents()
        components.scheme = "pente"
        components.host = "game"
        components.queryItems = queryItems
        let url = components.url!

        // Decode
        guard let decoded = GameStateDecoder.decodeFromURL(url) else {
            XCTFail("Should decode successfully")
            return
        }

        // Verify round trip
        XCTAssertEqual(decoded.currentPlayer, originalCurrentPlayer)
        XCTAssertEqual(decoded.capturedCount[.black], 0) // No captures in these moves
        XCTAssertEqual(decoded.capturedCount[.white], 0)
        XCTAssertEqual(decoded.moveHistory.count, originalMoveHistory.count)
        XCTAssertEqual(decoded.gameState, originalGameState)

        for (index, move) in decoded.moveHistory.enumerated() {
            XCTAssertEqual(move.row, originalMoveHistory[index].row)
            XCTAssertEqual(move.col, originalMoveHistory[index].col)
            XCTAssertEqual(move.player, originalMoveHistory[index].player)
        }
    }

    // MARK: - Capture Replay Tests

    func testDecodingWithCaptureReplay() {
        // B5,5 W5,6 W5,7 B5,8 = black captures the two white stones
        let moves = ["B5,5", "W5,6", "W5,7", "B5,8"]
        let movesString = moves.joined(separator: ";") + ";"

        let url = URL(string: "pente://game?moves=\(movesString)&current=White&capB=0&capW=0&state=playing")!

        guard let decoded = GameStateDecoder.decodeFromURL(url) else {
            XCTFail("Should decode successfully")
            return
        }

        // Verify the final board state
        XCTAssertEqual(decoded.board[5, 5], .black)
        XCTAssertNil(decoded.board[5, 6])      // Captured white stone
        XCTAssertNil(decoded.board[5, 7])      // Captured white stone
        XCTAssertEqual(decoded.board[5, 8], .black)

        // Verify capture count computed from replay
        XCTAssertEqual(decoded.moveHistory.count, 4)
        XCTAssertEqual(decoded.capturedCount[.black], 1) // 1 pair captured from replay
    }

    // MARK: - Error Handling Tests

    func testDecodeInvalidURL() {
        let url = URL(string: "invalid://url")!

        // Should return nil for URL without query items
        let decoded = GameStateDecoder.decodeFromURL(url)
        XCTAssertNil(decoded)
    }

    func testDecodeInvalidMoveFormat() {
        let url = URL(string: "pente://game?moves=InvalidMove;B9,9;&current=White&state=playing")!

        guard let decoded = GameStateDecoder.decodeFromURL(url) else {
            XCTFail("Should decode successfully")
            return
        }

        // Should only process valid moves
        XCTAssertEqual(decoded.moveHistory.count, 1)
        XCTAssertEqual(decoded.board[9, 9], .black)
    }

    func testDecodeInvalidCoordinates() {
        let url = URL(string: "pente://game?moves=B-1,9;B9,20;B9,9;&current=White&state=playing")!

        guard let decoded = GameStateDecoder.decodeFromURL(url) else {
            XCTFail("Should decode successfully")
            return
        }

        // Should only process the valid move
        XCTAssertEqual(decoded.moveHistory.count, 1)
        XCTAssertEqual(decoded.board[9, 9], .black)
    }

    // MARK: - Player Assignment Tests

    func testEncodeWithBlackPlayerID() {
        let moveHistory = [(row: 9, col: 9, player: Player.black)]
        let currentPlayer: Player = .white
        let capturedCount: [Player: Int] = [.black: 0, .white: 0]
        let gameState: GameState = .playing
        let testPlayerID = "test-player-12345"

        let queryItems = GameStateEncoder.encodeToQueryItems(
            moveHistory: moveHistory,
            currentPlayer: currentPlayer,
            capturedCount: capturedCount,
            gameState: gameState,
            blackPlayerID: testPlayerID
        )

        // Should include blackID parameter
        XCTAssertTrue(queryItems.contains { $0.name == "blackID" && $0.value == testPlayerID })
    }

    func testEncodeWithoutBlackPlayerID() {
        let moveHistory = [(row: 9, col: 9, player: Player.black)]
        let currentPlayer: Player = .white
        let capturedCount: [Player: Int] = [.black: 0, .white: 0]
        let gameState: GameState = .playing

        let queryItems = GameStateEncoder.encodeToQueryItems(
            moveHistory: moveHistory,
            currentPlayer: currentPlayer,
            capturedCount: capturedCount,
            gameState: gameState
        )

        // Should not include blackID parameter
        XCTAssertFalse(queryItems.contains { $0.name == "blackID" })
    }

    func testDecodeWithBlackPlayerID() {
        let testPlayerID = "test-player-54321"
        let url = URL(string: "pente://game?moves=B9,9;&current=White&capB=0&capW=0&state=playing&blackID=\(testPlayerID)")!

        guard let decoded = GameStateDecoder.decodeFromURL(url) else {
            XCTFail("Should decode successfully")
            return
        }

        XCTAssertEqual(decoded.blackPlayerID, testPlayerID)
        XCTAssertEqual(decoded.currentPlayer, .white)
        XCTAssertEqual(decoded.moveHistory.count, 1)
    }

    func testDecodeWithoutBlackPlayerID() {
        let url = URL(string: "pente://game?moves=B9,9;&current=White&capB=0&capW=0&state=playing")!

        guard let decoded = GameStateDecoder.decodeFromURL(url) else {
            XCTFail("Should decode successfully")
            return
        }

        XCTAssertNil(decoded.blackPlayerID)
    }

    func testRoundTripWithBlackPlayerID() {
        let originalMoveHistory = [(row: 9, col: 9, player: Player.black)]
        let originalCurrentPlayer: Player = .white
        let originalGameState: GameState = .playing
        let originalBlackPlayerID = "round-trip-test-player"

        // Encode
        let queryItems = GameStateEncoder.encodeToQueryItems(
            moveHistory: originalMoveHistory,
            currentPlayer: originalCurrentPlayer,
            capturedCount: [.black: 0, .white: 0],
            gameState: originalGameState,
            blackPlayerID: originalBlackPlayerID
        )

        // Create URL
        var components = URLComponents()
        components.scheme = "pente"
        components.host = "game"
        components.queryItems = queryItems
        let url = components.url!

        // Decode
        guard let decoded = GameStateDecoder.decodeFromURL(url) else {
            XCTFail("Should decode successfully")
            return
        }

        // Verify round trip
        XCTAssertEqual(decoded.blackPlayerID, originalBlackPlayerID)
        XCTAssertEqual(decoded.currentPlayer, originalCurrentPlayer)
        XCTAssertEqual(decoded.moveHistory.count, originalMoveHistory.count)
    }

    func testPlayerIDURLEncoding() {
        // Test with UUID-like string
        let testPlayerID = "550e8400-e29b-41d4-a716-446655440000"
        let moveHistory: [(row: Int, col: Int, player: Player)] = []
        let currentPlayer: Player = .black
        let capturedCount: [Player: Int] = [.black: 0, .white: 0]
        let gameState: GameState = .playing

        let queryItems = GameStateEncoder.encodeToQueryItems(
            moveHistory: moveHistory,
            currentPlayer: currentPlayer,
            capturedCount: capturedCount,
            gameState: gameState,
            blackPlayerID: testPlayerID
        )

        // Create URL and verify it can be properly created and decoded
        var components = URLComponents()
        components.scheme = "pente"
        components.host = "game"
        components.queryItems = queryItems
        let url = components.url!

        // Decode back
        guard let decoded = GameStateDecoder.decodeFromURL(url) else {
            XCTFail("Should decode successfully")
            return
        }

        XCTAssertEqual(decoded.blackPlayerID, testPlayerID)
    }
}
