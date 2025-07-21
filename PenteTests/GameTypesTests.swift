import XCTest
@testable import Pente_MessagesExtension

final class GameTypesTests: XCTestCase {
    
    // MARK: - Player Tests
    
    func testPlayerCases() {
        XCTAssertEqual(Player.black.rawValue, "Black")
        XCTAssertEqual(Player.white.rawValue, "White")
        XCTAssertEqual(Player.allCases.count, 2)
        XCTAssertTrue(Player.allCases.contains(.black))
        XCTAssertTrue(Player.allCases.contains(.white))
    }
    
    func testPlayerOpponent() {
        XCTAssertEqual(Player.black.opponent, .white)
        XCTAssertEqual(Player.white.opponent, .black)
    }
    
    func testPlayerOpponentSymmetry() {
        // Test that opponent relationship is symmetric
        XCTAssertEqual(Player.black.opponent.opponent, .black)
        XCTAssertEqual(Player.white.opponent.opponent, .white)
    }
    
    func testPlayerCodable() {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // Test encoding and decoding black player
        do {
            let blackData = try encoder.encode(Player.black)
            let decodedBlack = try decoder.decode(Player.self, from: blackData)
            XCTAssertEqual(decodedBlack, .black)
        } catch {
            XCTFail("Failed to encode/decode black player: \(error)")
        }
        
        // Test encoding and decoding white player
        do {
            let whiteData = try encoder.encode(Player.white)
            let decodedWhite = try decoder.decode(Player.self, from: whiteData)
            XCTAssertEqual(decodedWhite, .white)
        } catch {
            XCTFail("Failed to encode/decode white player: \(error)")
        }
    }
    
    func testPlayerFromRawValue() {
        XCTAssertEqual(Player(rawValue: "Black"), .black)
        XCTAssertEqual(Player(rawValue: "White"), .white)
        XCTAssertNil(Player(rawValue: "Invalid"))
        XCTAssertNil(Player(rawValue: "black")) // Case sensitive
        XCTAssertNil(Player(rawValue: "white")) // Case sensitive
    }
    
    // MARK: - WinMethod Tests
    
    func testWinMethodCases() {
        XCTAssertEqual(WinMethod.fiveInARow.rawValue, "fiveInARow")
        XCTAssertEqual(WinMethod.fiveCaptures.rawValue, "fiveCaptures")
    }
    
    func testWinMethodCodable() {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // Test encoding and decoding fiveInARow
        do {
            let fiveInARowData = try encoder.encode(WinMethod.fiveInARow)
            let decodedFiveInARow = try decoder.decode(WinMethod.self, from: fiveInARowData)
            XCTAssertEqual(decodedFiveInARow, .fiveInARow)
        } catch {
            XCTFail("Failed to encode/decode fiveInARow: \(error)")
        }
        
        // Test encoding and decoding fiveCaptures
        do {
            let fiveCapturesData = try encoder.encode(WinMethod.fiveCaptures)
            let decodedFiveCaptures = try decoder.decode(WinMethod.self, from: fiveCapturesData)
            XCTAssertEqual(decodedFiveCaptures, .fiveCaptures)
        } catch {
            XCTFail("Failed to encode/decode fiveCaptures: \(error)")
        }
    }
    
    func testWinMethodFromRawValue() {
        XCTAssertEqual(WinMethod(rawValue: "fiveInARow"), .fiveInARow)
        XCTAssertEqual(WinMethod(rawValue: "fiveCaptures"), .fiveCaptures)
        XCTAssertNil(WinMethod(rawValue: "invalid"))
        XCTAssertNil(WinMethod(rawValue: "five_in_a_row")) // Different format
    }
    
    // MARK: - GameState Tests
    
    func testGameStatePlaying() {
        let playingState = GameState.playing
        
        switch playingState {
        case .playing:
            XCTAssertTrue(true) // Expected case
        case .won:
            XCTFail("Should be playing state")
        }
    }
    
    func testGameStateWon() {
        let wonByBlackFiveInARow = GameState.won(by: .black, method: .fiveInARow)
        let wonByWhiteCaptures = GameState.won(by: .white, method: .fiveCaptures)
        
        switch wonByBlackFiveInARow {
        case .playing:
            XCTFail("Should be won state")
        case .won(let player, let method):
            XCTAssertEqual(player, .black)
            XCTAssertEqual(method, .fiveInARow)
        }
        
        switch wonByWhiteCaptures {
        case .playing:
            XCTFail("Should be won state")
        case .won(let player, let method):
            XCTAssertEqual(player, .white)
            XCTAssertEqual(method, .fiveCaptures)
        }
    }
    
    func testGameStateCodable() {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // Test encoding and decoding playing state
        do {
            let playingData = try encoder.encode(GameState.playing)
            let decodedPlaying = try decoder.decode(GameState.self, from: playingData)
            
            switch decodedPlaying {
            case .playing:
                XCTAssertTrue(true) // Expected
            case .won:
                XCTFail("Should decode as playing")
            }
        } catch {
            XCTFail("Failed to encode/decode playing state: \(error)")
        }
        
        // Test encoding and decoding won state
        do {
            let wonState = GameState.won(by: .black, method: .fiveInARow)
            let wonData = try encoder.encode(wonState)
            let decodedWon = try decoder.decode(GameState.self, from: wonData)
            
            switch decodedWon {
            case .playing:
                XCTFail("Should decode as won")
            case .won(let player, let method):
                XCTAssertEqual(player, .black)
                XCTAssertEqual(method, .fiveInARow)
            }
        } catch {
            XCTFail("Failed to encode/decode won state: \(error)")
        }
    }
    
    func testGameStateEquality() {
        let playing1 = GameState.playing
        let playing2 = GameState.playing
        
        let wonBlackFiveInARow1 = GameState.won(by: .black, method: .fiveInARow)
        let wonBlackFiveInARow2 = GameState.won(by: .black, method: .fiveInARow)
        let wonWhiteCaptures = GameState.won(by: .white, method: .fiveCaptures)
        
        // Note: GameState doesn't conform to Equatable in the implementation,
        // but we can test the associated values when extracted
        
        switch (playing1, playing2) {
        case (.playing, .playing):
            XCTAssertTrue(true) // Both are playing
        default:
            XCTFail("Both should be playing")
        }
        
        switch (wonBlackFiveInARow1, wonBlackFiveInARow2) {
        case (.won(let p1, let m1), .won(let p2, let m2)):
            XCTAssertEqual(p1, p2)
            XCTAssertEqual(m1, m2)
        default:
            XCTFail("Both should be won states with same values")
        }
        
        // Test different won states
        switch (wonBlackFiveInARow1, wonWhiteCaptures) {
        case (.won(let p1, let m1), .won(let p2, let m2)):
            XCTAssertNotEqual(p1, p2) // Different players
            XCTAssertNotEqual(m1, m2) // Different methods
        default:
            XCTFail("Both should be won states")
        }
    }
    
    // MARK: - GameMoveDelegate Protocol Tests
    
    func testGameMoveDelegateProtocol() {
        // Create a mock implementation
        class MockGameMoveDelegate: GameMoveDelegate {
            var moveCallCount = 0
            
            func gameDidMakeMove() {
                moveCallCount += 1
            }
        }
        
        let mockDelegate = MockGameMoveDelegate()
        XCTAssertEqual(mockDelegate.moveCallCount, 0)
        
        mockDelegate.gameDidMakeMove()
        XCTAssertEqual(mockDelegate.moveCallCount, 1)
        
        mockDelegate.gameDidMakeMove()
        XCTAssertEqual(mockDelegate.moveCallCount, 2)
    }
    
    func testGameMoveDelegateWeakReference() {
        // Test that delegate can be used as weak reference
        class MockGameMoveDelegate: GameMoveDelegate {
            func gameDidMakeMove() {
                // Implementation not important for this test
            }
        }
        
        class MockGameModel {
            weak var moveDelegate: GameMoveDelegate?
        }
        
        let gameModel = MockGameModel()
        
        do {
            let delegate = MockGameMoveDelegate()
            gameModel.moveDelegate = delegate
            XCTAssertNotNil(gameModel.moveDelegate)
            // delegate goes out of scope here
        }
        
        // Delegate should be nil due to weak reference
        XCTAssertNil(gameModel.moveDelegate)
    }
    
    // MARK: - Integration Tests
    
    func testAllTypesWorkTogether() {
        // Test that all types can be used together as intended
        let player = Player.black
        let opponent = player.opponent
        let method = WinMethod.fiveInARow
        let gameState = GameState.won(by: player, method: method)
        
        XCTAssertEqual(opponent, .white)
        
        switch gameState {
        case .playing:
            XCTFail("Should be won state")
        case .won(let winner, let winMethod):
            XCTAssertEqual(winner, player)
            XCTAssertEqual(winMethod, method)
        }
    }
    
    func testCompleteGameStateTransition() {
        // Test a typical game state transition
        var currentState = GameState.playing
        let currentPlayer = Player.black
        
        // Game starts as playing
        switch currentState {
        case .playing:
            XCTAssertTrue(true)
        case .won:
            XCTFail("Should start as playing")
        }
        
        // Player wins by five in a row
        currentState = .won(by: currentPlayer, method: .fiveInARow)
        
        switch currentState {
        case .playing:
            XCTFail("Should be won after victory")
        case .won(let winner, let method):
            XCTAssertEqual(winner, .black)
            XCTAssertEqual(method, .fiveInARow)
        }
    }
    
    // MARK: - Serialization Edge Cases
    
    func testPlayerSerializationEdgeCases() {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        // Test with custom encoding/decoding if needed
        for player in Player.allCases {
            do {
                let data = try encoder.encode(player)
                let decoded = try decoder.decode(Player.self, from: data)
                XCTAssertEqual(decoded, player)
            } catch {
                XCTFail("Failed to round-trip player \(player): \(error)")
            }
        }
    }
    
    func testWinMethodSerializationEdgeCases() {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let allMethods: [WinMethod] = [.fiveInARow, .fiveCaptures]
        
        for method in allMethods {
            do {
                let data = try encoder.encode(method)
                let decoded = try decoder.decode(WinMethod.self, from: data)
                XCTAssertEqual(decoded, method)
            } catch {
                XCTFail("Failed to round-trip win method \(method): \(error)")
            }
        }
    }
    
    func testComplexGameStateSerialization() {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let complexStates: [GameState] = [
            .playing,
            .won(by: .black, method: .fiveInARow),
            .won(by: .white, method: .fiveInARow),
            .won(by: .black, method: .fiveCaptures),
            .won(by: .white, method: .fiveCaptures)
        ]
        
        for state in complexStates {
            do {
                let data = try encoder.encode(state)
                let decoded = try decoder.decode(GameState.self, from: data)
                
                // Compare the states
                switch (state, decoded) {
                case (.playing, .playing):
                    XCTAssertTrue(true)
                case (.won(let p1, let m1), .won(let p2, let m2)):
                    XCTAssertEqual(p1, p2)
                    XCTAssertEqual(m1, m2)
                default:
                    XCTFail("States don't match: \(state) vs \(decoded)")
                }
            } catch {
                XCTFail("Failed to round-trip game state \(state): \(error)")
            }
        }
    }
}