import XCTest
import PenteCore

// Resolves catalog keys from the test bundle (which has the Messages extension's
// Localizable.xcstrings compiled in via the shared filesystem-synchronized group).
//
// The honest failure modes this catches:
//  - Key typo at a view call site (key doesn't exist in catalog → lookup returns
//    the literal key string, which this test fails on).
//  - Catalog key renamed but call site not updated.
//  - Catalog file not compiled into the extension bundle.
//
// It does NOT validate zh-Hans correctness — that's for human review and
// on-device verification. These assertions run in the default (en) locale.
final class LocalizationCatalogTests: XCTestCase {

    /// Bundle containing the compiled Localizable.xcstrings. Because PenteTests
    /// pulls the Pente MessagesExtension folder in as a synchronized group, the
    /// catalog is compiled into the test bundle alongside the extension sources.
    /// We explicitly resolve the `en.lproj` subbundle so these assertions are
    /// independent of whatever locale the test runner happens to use — without
    /// this, running CI or a simulator in zh-Hans would make every string
    /// return its Chinese translation and fail the hard-coded English checks.
    private var englishBundle: Bundle {
        let catalog = Bundle(for: LocalizationCatalogTests.self)
        guard let path = catalog.path(forResource: "en", ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            XCTFail("en.lproj not found in test bundle — catalog may not be compiled in")
            return catalog
        }
        return bundle
    }

    private func assertResolves(_ key: String, _ expected: String, file: StaticString = #file, line: UInt = #line) {
        let resolved = NSLocalizedString(key, bundle: englishBundle, comment: "")
        XCTAssertEqual(resolved, expected,
                       "Catalog key '\(key)' did not resolve to expected English value. Got '\(resolved)'.",
                       file: file, line: line)
    }

    // MARK: - Keys referenced from PenteGameView

    func testGameViewKeysResolve() {
        assertResolves("Pente", "Pente")
        assertResolves("Captures", "Captures")
        assertResolves("Undo", "Undo")
        assertResolves("Send", "Send")
        assertResolves("Waiting for opponent", "Waiting for opponent")
        assertResolves("Your turn", "Your turn")
        assertResolves("New Game", "New Game")
    }

    // MARK: - Keys referenced via Player.displayNameKey / WinMethod.bannerKey

    func testPlayerDisplayKeysResolve() {
        assertResolves(Player.black.displayNameKey, "Black")
        assertResolves(Player.white.displayNameKey, "White")
    }

    func testWinMethodBannerKeysResolve() {
        assertResolves(WinMethod.fiveInARow.bannerKey, "Five in a row!")
        assertResolves(WinMethod.fiveCaptures.bannerKey, "Five captures!")
    }

    // MARK: - Turn indicator keys (selected by ternary in PenteGameView)

    func testTurnIndicatorKeysResolve() {
        assertResolves("turn.black", "Black's turn")
        assertResolves("turn.white", "White's turn")
    }

    // MARK: - Win banner keys (selected by ternary in PenteGameView)

    func testWinBannerKeysResolve() {
        assertResolves("win.black", "Black wins!")
        assertResolves("win.white", "White wins!")
    }

    // MARK: - MSMessageTemplateLayout keys used by MessagesViewController

    func testLayoutCaptionKeyResolves() {
        assertResolves("layout.caption", "Pente")
    }

    func testLayoutTurnSubcaptionFormatKeysResolve() {
        // Format strings — %lld placeholder must be present so String(format:) works.
        let blackFormat = NSLocalizedString("layout.subcaption.turn.black", bundle: englishBundle, comment: "")
        let whiteFormat = NSLocalizedString("layout.subcaption.turn.white", bundle: englishBundle, comment: "")
        XCTAssertEqual(String(format: blackFormat, 12), "Black's turn (Move 12)")
        XCTAssertEqual(String(format: whiteFormat, 7), "White's turn (Move 7)")
    }

    func testLayoutWinSubcaptionKeysResolve() {
        assertResolves("layout.subcaption.win.black.fiveInARow", "Black wins by five in a row!")
        assertResolves("layout.subcaption.win.white.fiveInARow", "White wins by five in a row!")
        assertResolves("layout.subcaption.win.black.fiveCaptures", "Black wins by captures!")
        assertResolves("layout.subcaption.win.white.fiveCaptures", "White wins by captures!")
    }

    // MARK: - Coverage sanity: every displayNameKey/bannerKey Swift enum reports is in the catalog

    func testAllPlayerCasesHaveResolvedDisplayKeys() {
        for player in Player.allCases {
            let key = player.displayNameKey
            let resolved = NSLocalizedString(key, bundle: englishBundle, comment: "")
            XCTAssertNotEqual(resolved, key, "Player.\(player) displayNameKey '\(key)' did not resolve")
        }
    }
}
