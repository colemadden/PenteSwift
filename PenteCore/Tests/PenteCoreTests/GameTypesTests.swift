import XCTest
@testable import PenteCore

final class GameTypesTests: XCTestCase {

    // MARK: - Player Tests

    func testPlayerCases() {
        XCTAssertEqual(Player.black.rawValue, "Black")
        XCTAssertEqual(Player.white.rawValue, "White")
        XCTAssertEqual(Player.allCases.count, 2)
    }

    func testPlayerOpponent() {
        XCTAssertEqual(Player.black.opponent, .white)
        XCTAssertEqual(Player.white.opponent, .black)
    }

    func testPlayerOpponentSymmetry() {
        XCTAssertEqual(Player.black.opponent.opponent, .black)
        XCTAssertEqual(Player.white.opponent.opponent, .white)
    }

    func testPlayerCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let blackData = try encoder.encode(Player.black)
        let decodedBlack = try decoder.decode(Player.self, from: blackData)
        XCTAssertEqual(decodedBlack, .black)

        let whiteData = try encoder.encode(Player.white)
        let decodedWhite = try decoder.decode(Player.self, from: whiteData)
        XCTAssertEqual(decodedWhite, .white)
    }

    func testPlayerFromRawValue() {
        XCTAssertEqual(Player(rawValue: "Black"), .black)
        XCTAssertEqual(Player(rawValue: "White"), .white)
        XCTAssertNil(Player(rawValue: "Invalid"))
        XCTAssertNil(Player(rawValue: "black"))
    }

    // MARK: - WinMethod Tests

    func testWinMethodCases() {
        XCTAssertEqual(WinMethod.fiveInARow.rawValue, "fiveInARow")
        XCTAssertEqual(WinMethod.fiveCaptures.rawValue, "fiveCaptures")
    }

    // MARK: - Localization key contract
    //
    // These keys must match entries in Localizable.xcstrings exactly.
    // If a key changes, the UI silently falls through to the raw key string.
    // Wire format (rawValue) must stay decoupled from display keys.

    func testPlayerDisplayNameKeysAreStable() {
        XCTAssertEqual(Player.black.displayNameKey, "player.black")
        XCTAssertEqual(Player.white.displayNameKey, "player.white")
    }

    func testWinMethodBannerKeysAreStable() {
        XCTAssertEqual(WinMethod.fiveInARow.bannerKey, "win.method.fiveInARow")
        XCTAssertEqual(WinMethod.fiveCaptures.bannerKey, "win.method.fiveCaptures")
    }

    func testPlayerDisplayKeysAreNotWireFormat() {
        // Regression guard: displayNameKey must never equal rawValue.
        // If it did, localizing would break URL-encoded game state transport.
        XCTAssertNotEqual(Player.black.displayNameKey, Player.black.rawValue)
        XCTAssertNotEqual(Player.white.displayNameKey, Player.white.rawValue)
    }

    // MARK: - GameState Tests

    func testGameStateEquality() {
        XCTAssertEqual(GameState.playing, GameState.playing)
        XCTAssertEqual(GameState.won(by: .black, method: .fiveInARow), GameState.won(by: .black, method: .fiveInARow))
        XCTAssertNotEqual(GameState.playing, GameState.won(by: .black, method: .fiveInARow))
    }

    func testGameStateCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let states: [GameState] = [
            .playing,
            .won(by: .black, method: .fiveInARow),
            .won(by: .white, method: .fiveCaptures),
        ]

        for state in states {
            let data = try encoder.encode(state)
            let decoded = try decoder.decode(GameState.self, from: data)
            XCTAssertEqual(decoded, state)
        }
    }
}
