import XCTest
@testable import Pente_MessagesExtension

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
            gameState: gameState,
            blackPlayerID: nil
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
            gameState: gameState,
            blackPlayerID: nil
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
            gameState: gameState,
            blackPlayerID: nil
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
            gameState: gameState,
            blackPlayerID: nil
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
            gameState: gameState,
            blackPlayerID: nil
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
            gameState: gameState,
            blackPlayerID: nil
        )
        
        XCTAssertTrue(queryItems.contains { $0.name == "state" && $0.value == "won" })
        XCTAssertTrue(queryItems.contains { $0.name == "winner" && $0.value == "White" })
        XCTAssertTrue(queryItems.contains { $0.name == "method" && $0.value == "fiveCaptures" })
        XCTAssertTrue(queryItems.contains { $0.name == "capW" && $0.value == "5" })
    }
    
    // MARK: - Decoding Tests
    
    func testDecodeEmptyGame() {
        let url = URL(string: "pente://game?current=Black&capB=0&capW=0&state=playing")!
        
        var board = GameBoard()
        var currentPlayer: Player = .white
        var capturedCount: [Player: Int] = [.black: 1, .white: 1]
        var gameState: GameState = .won(by: .black, method: .fiveInARow)
        var moveHistory: [(row: Int, col: Int, player: Player)] = [(0, 0, .black)]
        
        var blackPlayerID: String? = nil
        GameStateDecoder.loadFromURL(
            url,
            board: &board,
            currentPlayer: &currentPlayer,
            capturedCount: &capturedCount,
            gameState: &gameState,
            moveHistory: &moveHistory,
            blackPlayerID: &blackPlayerID
        )
        
        // Verify reset and loaded state
        XCTAssertEqual(currentPlayer, .black)
        XCTAssertEqual(capturedCount[.black], 0)
        XCTAssertEqual(capturedCount[.white], 0)
        
        if case .playing = gameState {
            // Correct
        } else {
            XCTFail("Game state should be playing")
        }
        
        XCTAssertEqual(moveHistory.count, 0)
        
        // Board should be empty
        for row in 0..<GameBoard.size {
            for col in 0..<GameBoard.size {
                XCTAssertNil(board[row, col])
            }
        }
    }
    
    func testDecodeSingleMove() {
        let url = URL(string: "pente://game?moves=B9,9;&current=White&capB=0&capW=0&state=playing")!
        
        var board = GameBoard()
        var currentPlayer: Player = .black
        var capturedCount: [Player: Int] = [.black: 0, .white: 0]
        var gameState: GameState = .playing
        var moveHistory: [(row: Int, col: Int, player: Player)] = []
        
        var blackPlayerID: String? = nil
        GameStateDecoder.loadFromURL(
            url,
            board: &board,
            currentPlayer: &currentPlayer,
            capturedCount: &capturedCount,
            gameState: &gameState,
            moveHistory: &moveHistory,
            blackPlayerID: &blackPlayerID
        )
        
        XCTAssertEqual(currentPlayer, .white)
        XCTAssertEqual(moveHistory.count, 1)
        XCTAssertEqual(moveHistory[0].row, 9)
        XCTAssertEqual(moveHistory[0].col, 9)
        XCTAssertEqual(moveHistory[0].player, .black)
        
        // Board should have the stone
        XCTAssertEqual(board[9, 9], .black)
    }
    
    func testDecodeMultipleMoves() {
        let url = URL(string: "pente://game?moves=B9,9;W10,10;B8,8;&current=White&capB=0&capW=0&state=playing")!
        
        var board = GameBoard()
        var currentPlayer: Player = .black
        var capturedCount: [Player: Int] = [.black: 0, .white: 0]
        var gameState: GameState = .playing
        var moveHistory: [(row: Int, col: Int, player: Player)] = []
        
        var blackPlayerID: String? = nil
        GameStateDecoder.loadFromURL(
            url,
            board: &board,
            currentPlayer: &currentPlayer,
            capturedCount: &capturedCount,
            gameState: &gameState,
            moveHistory: &moveHistory,
            blackPlayerID: &blackPlayerID
        )
        
        XCTAssertEqual(moveHistory.count, 3)
        
        XCTAssertEqual(moveHistory[0].row, 9)
        XCTAssertEqual(moveHistory[0].col, 9)
        XCTAssertEqual(moveHistory[0].player, .black)
        
        XCTAssertEqual(moveHistory[1].row, 10)
        XCTAssertEqual(moveHistory[1].col, 10)
        XCTAssertEqual(moveHistory[1].player, .white)
        
        XCTAssertEqual(moveHistory[2].row, 8)
        XCTAssertEqual(moveHistory[2].col, 8)
        XCTAssertEqual(moveHistory[2].player, .black)
        
        // Board should have the stones
        XCTAssertEqual(board[9, 9], .black)
        XCTAssertEqual(board[10, 10], .white)
        XCTAssertEqual(board[8, 8], .black)
    }
    
    func testDecodeWithCaptures() {
        let url = URL(string: "pente://game?current=Black&capB=3&capW=1&state=playing")!
        
        var board = GameBoard()
        var currentPlayer: Player = .white
        var capturedCount: [Player: Int] = [.black: 0, .white: 0]
        var gameState: GameState = .playing
        var moveHistory: [(row: Int, col: Int, player: Player)] = []
        
        var blackPlayerID: String? = nil
        GameStateDecoder.loadFromURL(
            url,
            board: &board,
            currentPlayer: &currentPlayer,
            capturedCount: &capturedCount,
            gameState: &gameState,
            moveHistory: &moveHistory,
            blackPlayerID: &blackPlayerID
        )
        
        XCTAssertEqual(capturedCount[.black], 3)
        XCTAssertEqual(capturedCount[.white], 1)
    }
    
    func testDecodeWonGame() {
        let url = URL(string: "pente://game?current=Black&capB=0&capW=0&state=won&winner=Black&method=fiveInARow")!
        
        var board = GameBoard()
        var currentPlayer: Player = .white
        var capturedCount: [Player: Int] = [.black: 0, .white: 0]
        var gameState: GameState = .playing
        var moveHistory: [(row: Int, col: Int, player: Player)] = []
        
        var blackPlayerID: String? = nil
        GameStateDecoder.loadFromURL(
            url,
            board: &board,
            currentPlayer: &currentPlayer,
            capturedCount: &capturedCount,
            gameState: &gameState,
            moveHistory: &moveHistory,
            blackPlayerID: &blackPlayerID
        )
        
        if case .won(let winner, let method) = gameState {
            XCTAssertEqual(winner, .black)
            XCTAssertEqual(method, .fiveInARow)
        } else {
            XCTFail("Game state should be won")
        }
    }
    
    func testDecodeWonByCaptureGame() {
        let url = URL(string: "pente://game?current=White&capB=0&capW=5&state=won&winner=White&method=fiveCaptures")!
        
        var board = GameBoard()
        var currentPlayer: Player = .black
        var capturedCount: [Player: Int] = [.black: 0, .white: 0]
        var gameState: GameState = .playing
        var moveHistory: [(row: Int, col: Int, player: Player)] = []
        
        var blackPlayerID: String? = nil
        GameStateDecoder.loadFromURL(
            url,
            board: &board,
            currentPlayer: &currentPlayer,
            capturedCount: &capturedCount,
            gameState: &gameState,
            moveHistory: &moveHistory,
            blackPlayerID: &blackPlayerID
        )
        
        if case .won(let winner, let method) = gameState {
            XCTAssertEqual(winner, .white)
            XCTAssertEqual(method, .fiveCaptures)
        } else {
            XCTFail("Game state should be won")
        }
        
        XCTAssertEqual(capturedCount[.white], 5)
    }
    
    // MARK: - Round Trip Tests
    
    func testRoundTripEmptyGame() {
        let originalMoveHistory: [(row: Int, col: Int, player: Player)] = []
        let originalCurrentPlayer: Player = .black
        let originalCapturedCount: [Player: Int] = [.black: 0, .white: 0]
        let originalGameState: GameState = .playing
        
        // Encode
        let queryItems = GameStateEncoder.encodeToQueryItems(
            moveHistory: originalMoveHistory,
            currentPlayer: originalCurrentPlayer,
            capturedCount: originalCapturedCount,
            gameState: originalGameState
        )
        
        // Create URL
        var components = URLComponents()
        components.scheme = "pente"
        components.host = "game"
        components.queryItems = queryItems
        let url = components.url!
        
        // Decode
        var board = GameBoard()
        var currentPlayer: Player = .white
        var capturedCount: [Player: Int] = [.black: 0, .white: 0]
        var gameState: GameState = .playing
        var moveHistory: [(row: Int, col: Int, player: Player)] = []
        
        var blackPlayerID: String? = nil
        GameStateDecoder.loadFromURL(
            url,
            board: &board,
            currentPlayer: &currentPlayer,
            capturedCount: &capturedCount,
            gameState: &gameState,
            moveHistory: &moveHistory,
            blackPlayerID: &blackPlayerID
        )
        
        // Verify round trip
        XCTAssertEqual(currentPlayer, originalCurrentPlayer)
        XCTAssertEqual(capturedCount[.black], originalCapturedCount[.black])
        XCTAssertEqual(capturedCount[.white], originalCapturedCount[.white])
        XCTAssertEqual(moveHistory.count, originalMoveHistory.count)
    }
    
    func testRoundTripComplexGame() {
        let originalMoveHistory = [
            (row: 9, col: 9, player: Player.black),
            (row: 10, col: 10, player: Player.white),
            (row: 8, col: 8, player: Player.black),
            (row: 11, col: 11, player: Player.white)
        ]
        let originalCurrentPlayer: Player = .black
        let originalCapturedCount: [Player: Int] = [.black: 2, .white: 1]
        let originalGameState: GameState = .playing
        
        // Encode
        let queryItems = GameStateEncoder.encodeToQueryItems(
            moveHistory: originalMoveHistory,
            currentPlayer: originalCurrentPlayer,
            capturedCount: originalCapturedCount,
            gameState: originalGameState
        )
        
        // Create URL
        var components = URLComponents()
        components.scheme = "pente"
        components.host = "game"
        components.queryItems = queryItems
        let url = components.url!
        
        // Decode
        var board = GameBoard()
        var currentPlayer: Player = .white
        var capturedCount: [Player: Int] = [.black: 0, .white: 0]
        var gameState: GameState = .playing
        var moveHistory: [(row: Int, col: Int, player: Player)] = []
        
        var blackPlayerID: String? = nil
        GameStateDecoder.loadFromURL(
            url,
            board: &board,
            currentPlayer: &currentPlayer,
            capturedCount: &capturedCount,
            gameState: &gameState,
            moveHistory: &moveHistory,
            blackPlayerID: &blackPlayerID
        )
        
        // Verify round trip
        XCTAssertEqual(currentPlayer, originalCurrentPlayer)
        XCTAssertEqual(capturedCount[.black], originalCapturedCount[.black])
        XCTAssertEqual(capturedCount[.white], originalCapturedCount[.white])
        XCTAssertEqual(moveHistory.count, originalMoveHistory.count)
        
        for (index, move) in moveHistory.enumerated() {
            XCTAssertEqual(move.row, originalMoveHistory[index].row)
            XCTAssertEqual(move.col, originalMoveHistory[index].col)
            XCTAssertEqual(move.player, originalMoveHistory[index].player)
        }
    }
    
    // MARK: - Capture Replay Tests
    
    func testDecodingWithCaptureReplay() {
        // Create a scenario where moves with captures need to be replayed correctly
        // This tests that the decoder properly replays captures when loading moves
        
        // Setup a board where move B5,8 would capture W5,6 and W5,7
        let moves = [
            "B5,5",   // Black stone
            "W5,6",   // White stone 
            "W5,7",   // White stone
            "B5,8"    // Black captures the two white stones
        ]
        let movesString = moves.joined(separator: ";") + ";"
        
        let url = URL(string: "pente://game?moves=\(movesString)&current=White&capB=1&capW=0&state=playing")!
        
        var board = GameBoard()
        var currentPlayer: Player = .black
        var capturedCount: [Player: Int] = [.black: 0, .white: 0]
        var gameState: GameState = .playing
        var moveHistory: [(row: Int, col: Int, player: Player)] = []
        
        var blackPlayerID: String? = nil
        GameStateDecoder.loadFromURL(
            url,
            board: &board,
            currentPlayer: &currentPlayer,
            capturedCount: &capturedCount,
            gameState: &gameState,
            moveHistory: &moveHistory,
            blackPlayerID: &blackPlayerID
        )
        
        // Verify the final board state
        XCTAssertEqual(board[5, 5], .black)  // Original black stone
        XCTAssertNil(board[5, 6])            // Captured white stone
        XCTAssertNil(board[5, 7])            // Captured white stone  
        XCTAssertEqual(board[5, 8], .black)  // Capturing black stone
        
        // Verify move history is correct
        XCTAssertEqual(moveHistory.count, 4)
        XCTAssertEqual(capturedCount[.black], 1) // From URL parameter
    }
    
    // MARK: - Error Handling Tests
    
    func testDecodeInvalidURL() {
        let url = URL(string: "invalid://url")!
        
        var board = GameBoard()
        var currentPlayer: Player = .black
        var capturedCount: [Player: Int] = [.black: 0, .white: 0]
        var gameState: GameState = .playing
        var moveHistory: [(row: Int, col: Int, player: Player)] = []
        
        // Should not crash and should reset to defaults
        var blackPlayerID: String? = nil
        GameStateDecoder.loadFromURL(
            url,
            board: &board,
            currentPlayer: &currentPlayer,
            capturedCount: &capturedCount,
            gameState: &gameState,
            moveHistory: &moveHistory,
            blackPlayerID: &blackPlayerID
        )
        
        // Should be reset to default state
        XCTAssertEqual(currentPlayer, .black)
        XCTAssertEqual(moveHistory.count, 0)
    }
    
    func testDecodeInvalidMoveFormat() {
        let url = URL(string: "pente://game?moves=InvalidMove;B9,9;&current=White&state=playing")!
        
        var board = GameBoard()
        var currentPlayer: Player = .black
        var capturedCount: [Player: Int] = [.black: 0, .white: 0]
        var gameState: GameState = .playing
        var moveHistory: [(row: Int, col: Int, player: Player)] = []
        
        var blackPlayerID: String? = nil
        GameStateDecoder.loadFromURL(
            url,
            board: &board,
            currentPlayer: &currentPlayer,
            capturedCount: &capturedCount,
            gameState: &gameState,
            moveHistory: &moveHistory,
            blackPlayerID: &blackPlayerID
        )
        
        // Should only process valid moves
        XCTAssertEqual(moveHistory.count, 1) // Only the valid "B9,9" move
        XCTAssertEqual(board[9, 9], .black)
    }
    
    func testDecodeInvalidCoordinates() {
        let url = URL(string: "pente://game?moves=B-1,9;B9,20;B9,9;&current=White&state=playing")!
        
        var board = GameBoard()
        var currentPlayer: Player = .black
        var capturedCount: [Player: Int] = [.black: 0, .white: 0]
        var gameState: GameState = .playing
        var moveHistory: [(row: Int, col: Int, player: Player)] = []
        
        var blackPlayerID: String? = nil
        GameStateDecoder.loadFromURL(
            url,
            board: &board,
            currentPlayer: &currentPlayer,
            capturedCount: &capturedCount,
            gameState: &gameState,
            moveHistory: &moveHistory,
            blackPlayerID: &blackPlayerID
        )
        
        // Should only process the valid move
        XCTAssertEqual(moveHistory.count, 1) // Only the valid "B9,9" move
        XCTAssertEqual(board[9, 9], .black)
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
            gameState: gameState,
            blackPlayerID: nil
        )
        
        // Should not include blackID parameter
        XCTAssertFalse(queryItems.contains { $0.name == "blackID" })
    }
    
    func testDecodeWithBlackPlayerID() {
        let testPlayerID = "test-player-54321"
        let url = URL(string: "pente://game?moves=B9,9;&current=White&capB=0&capW=0&state=playing&blackID=\(testPlayerID)")!
        
        var board = GameBoard()
        var currentPlayer: Player = .black
        var capturedCount: [Player: Int] = [.black: 0, .white: 0]
        var gameState: GameState = .playing
        var moveHistory: [(row: Int, col: Int, player: Player)] = []
        var blackPlayerID: String? = nil
        
        GameStateDecoder.loadFromURL(
            url,
            board: &board,
            currentPlayer: &currentPlayer,
            capturedCount: &capturedCount,
            gameState: &gameState,
            moveHistory: &moveHistory,
            blackPlayerID: &blackPlayerID
        )
        
        XCTAssertEqual(blackPlayerID, testPlayerID)
        XCTAssertEqual(currentPlayer, .white)
        XCTAssertEqual(moveHistory.count, 1)
    }
    
    func testDecodeWithoutBlackPlayerID() {
        let url = URL(string: "pente://game?moves=B9,9;&current=White&capB=0&capW=0&state=playing")!
        
        var board = GameBoard()
        var currentPlayer: Player = .black
        var capturedCount: [Player: Int] = [.black: 0, .white: 0]
        var gameState: GameState = .playing
        var moveHistory: [(row: Int, col: Int, player: Player)] = []
        var blackPlayerID: String? = "should-be-reset"
        
        GameStateDecoder.loadFromURL(
            url,
            board: &board,
            currentPlayer: &currentPlayer,
            capturedCount: &capturedCount,
            gameState: &gameState,
            moveHistory: &moveHistory,
            blackPlayerID: &blackPlayerID
        )
        
        XCTAssertNil(blackPlayerID) // Should be reset to nil
    }
    
    func testRoundTripWithBlackPlayerID() {
        let originalMoveHistory = [(row: 9, col: 9, player: Player.black)]
        let originalCurrentPlayer: Player = .white
        let originalCapturedCount: [Player: Int] = [.black: 0, .white: 0]
        let originalGameState: GameState = .playing
        let originalBlackPlayerID = "round-trip-test-player"
        
        // Encode
        let queryItems = GameStateEncoder.encodeToQueryItems(
            moveHistory: originalMoveHistory,
            currentPlayer: originalCurrentPlayer,
            capturedCount: originalCapturedCount,
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
        var board = GameBoard()
        var currentPlayer: Player = .black
        var capturedCount: [Player: Int] = [.black: 0, .white: 0]
        var gameState: GameState = .playing
        var moveHistory: [(row: Int, col: Int, player: Player)] = []
        var blackPlayerID: String? = nil
        
        GameStateDecoder.loadFromURL(
            url,
            board: &board,
            currentPlayer: &currentPlayer,
            capturedCount: &capturedCount,
            gameState: &gameState,
            moveHistory: &moveHistory,
            blackPlayerID: &blackPlayerID
        )
        
        // Verify round trip
        XCTAssertEqual(blackPlayerID, originalBlackPlayerID)
        XCTAssertEqual(currentPlayer, originalCurrentPlayer)
        XCTAssertEqual(moveHistory.count, originalMoveHistory.count)
    }
    
    func testPlayerIDURLEncoding() {
        // Test with UUID-like string that might need URL encoding
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
        var board = GameBoard()
        var decodedCurrentPlayer: Player = .white
        var decodedCapturedCount: [Player: Int] = [.black: 0, .white: 0]
        var decodedGameState: GameState = .playing
        var decodedMoveHistory: [(row: Int, col: Int, player: Player)] = []
        var decodedBlackPlayerID: String? = nil
        
        GameStateDecoder.loadFromURL(
            url,
            board: &board,
            currentPlayer: &decodedCurrentPlayer,
            capturedCount: &decodedCapturedCount,
            gameState: &decodedGameState,
            moveHistory: &decodedMoveHistory,
            blackPlayerID: &decodedBlackPlayerID
        )
        
        XCTAssertEqual(decodedBlackPlayerID, testPlayerID)
    }
}