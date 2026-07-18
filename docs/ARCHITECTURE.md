# Pente — Architecture Document

*arc42-flavored Software Architecture Document. Single living masterdoc. Pairs with the decision ledger in `docs/adr/`.*

- **App**: Pente (iMessage extension game)
- **Bundle ID**: `colemadden.Pente` (host) / `colemadden.Pente.MessagesExtension` (extension)
- **Current build target** (from `project.pbxproj`): v1.4 (build 7) — `MARKETING_VERSION=1.4`, `CURRENT_PROJECT_VERSION=7`, set in the uncommitted v1.4 working tree (2026-07-16). Last committed bump: `776d8b0` (v1.3 build 6, 2026-04-23).
- **Release status** (per repo docs and project-owner attestation, not an ASC API pull): `APP_STORE_SUBMISSION.md` attests v1.0 and v1.1 as Released (Aug 2025 / Mar 2026) and last documented v1.2 as "In Review" (Apr 2026). `FEATURE_ROADMAP.md` declares v1.3 SHIPPED 2026-04-24. v1.2's transition out of "In Review" and v1.3's release status are project-owner-attested via conversation; neither is captured by an ASC API pull in the repo. Authoritative state lives in App Store Connect (App ID `6748970073`).
- **Repo**: https://github.com/colemadden/PenteSwift
- **Owner**: Cole Madden
- **Last updated**: 2026-04-24

Links:
- [Decision ledger](adr/README.md)
- [Feature roadmap](../FEATURE_ROADMAP.md)
- [Project CLAUDE.md](../CLAUDE.md) — agent guardrails
- [Release history / ASC submission notes](../APP_STORE_SUBMISSION.md)
- [Privacy policy](../PRIVACY.md)

---

## 1. Introduction and goals

### 1.1 What Pente is

Pente is the abstract strategy board game (originated 1977, Parker Brothers). Two players alternate placing stones on the intersections of a 19×19 grid. Black moves first, in the center. A player wins by either:

- getting **five of their stones in a row** (horizontal, vertical, or diagonal), OR
- **capturing five pairs** of opponent stones (ten stones total). Capture occurs by sandwiching exactly two adjacent opponent stones between two of your own along any of the eight directions.

This app ships as an **iMessage extension**: two iOS users play asynchronously by sending the game back and forth inside an iMessage conversation, one move per message.

### 1.2 Business goals

| # | Goal | Status |
|---|------|--------|
| G1 | Ship a polished, GamePigeon-caliber Pente on iMessage. | Shipping since Aug 2025 (v1.0). v1.3 is the current public version. |
| G2 | Reach the Chinese market, which is 82% of installs. | v1.3 target commit adds Simplified Chinese in-app; ASC listing-localization work queued. |
| G3 | Keep the codebase small enough that a single developer can evolve it autonomously. | ~1,270 LOC across extension + core. |
| G4 | Keep infrastructure cost at zero (no backend). | Held: pure client-side, state lives in MSMessage URL. |
| G5 | Preserve the *entire* feature set and design rationale so the app can be re-implemented on a different platform (e.g. WeChat) without archaeology. | This document + `docs/adr/` exist to satisfy this goal. |

### 1.3 Target audience and stakeholders

- **End users**: casual iMessage players. 82% of downloads are from mainland China, suggesting demand via Chinese social-media word-of-mouth. The Chinese audience defaults to assuming this is 五子棋 (Gomoku) until the capture mechanic is explained — this shapes copy and rules-surface decisions.
- **Developer**: Cole Madden (sole). Python/Flask background, learning iOS.
- **Agents**: Claude Code and Codex operate on this repo autonomously. Their guardrails are in `CLAUDE.md` and `.claude/CLAUDE.md`.

### 1.4 Non-goals (explicit)

- No backend service. No CloudKit. No analytics. No ads. (See PRIVACY.md and ADR-0005.)
- No single-player AI in v1.x. (Roadmap v2.0 item.)
- No sticker-pack mode. This is an interactive Messages app, not a sticker extension. (See ADR-0014.)
- No support for non-iOS clients. (WeChat mini-program is v2.0 aspirational.)

---

## 2. Constraints

### 2.1 Platform and technical constraints

| Constraint | Source | Consequence |
|---|---|---|
| iOS 18+, Xcode 16, Swift 5.0 | `project.pbxproj`: `IPHONEOS_DEPLOYMENT_TARGET=18.5`, `SWIFT_VERSION=5.0` | No cross-platform frameworks. SwiftUI with iOS-18 APIs is fair game. |
| iMessage extension sandbox | Apple Messages framework | Runs as `MSMessagesAppViewController`. Cannot access most system APIs. `Bundle.main` in XCTest is the test runner (see ADR-0023). |
| MSMessage URL size constraints | Apple Messages framework | All game state must fit in a URL query string. A full 19×19 game move list is ~1 KB in the current encoding, comfortably under any documented or observed limit. No fallback path exists if a future game variant or addition ever grows the URL past Apple's serializer tolerance. |
| No backend / no persistence outside the thread | Self-imposed (G4) | Resuming a game is only possible from a message in the conversation. Lose the thread → lose the game. |
| Physical device required for iMessage extension validation | Apple | Simulator-only testing cannot catch every presentation-style or message-routing bug. |
| Paid Apple Developer Program required for physical-device testing and App Store submission | Apple | $99/yr overhead. |

### 2.2 Organizational constraints

- Single developer, working async with AI agents. No code review by a second human.
- The CLAUDE.md "Code Minimization Rule" is a hard bias against abstraction. ADRs are the counterweight that preserves rationale.

### 2.3 Conventions

- Swift, 4-space indent, no separate style guide.
- Test requirement: new features ship with tests (see §8.3 and the "MANDATORY TESTING REQUIREMENTS" section in `CLAUDE.md`).
- Commit convention: single-line subject, optional body, Claude co-author trailer, version bumps in their own commit.

---

## 3. Context and scope

### 3.1 Business context

```
                                 ┌────────────────────────────┐
                                 │  App Store Connect (API)   │
                                 │  - Metadata, screenshots   │
                                 │  - Builds, submissions     │
                                 │  - Customer reviews        │
                                 │  - Sales reports           │
                                 └──────────────┬─────────────┘
                                                │ JWT (ES256)
                                                │ uploads via altool
                                                │
  ┌──────────────┐     iMessage      ┌──────────┴──────────┐     iMessage      ┌──────────────┐
  │  Player A    │ ─────────────────▶│  Apple Messages     │─────────────────▶│  Player B    │
  │  (iPhone)    │ ◀─────────────────│  (transport layer)  │◀─────────────────│  (iPhone)    │
  │  Pente ext.  │  MSMessage w/     │  Sessions + URLs    │                   │  Pente ext.  │
  │  (sender)    │  encoded state    │                     │                   │  (receiver)  │
  └──────────────┘                    └─────────────────────┘                   └──────────────┘
```

External systems the app depends on at runtime:

- **Apple Messages framework** — delivery, presentation (compact/expanded), session lifecycle. We never touch Apple servers directly.

External systems the developer depends on at build/release time:

- **App Store Connect** — versioning, TestFlight, submission, reviews, sales. Most release operations are scripted against the ASC REST API (credentials in `.claude/CLAUDE.md`); binary uploads go through `xcrun altool`; `APP_STORE_SUBMISSION.md` also documents an Xcode Organizer GUI fallback.

### 3.2 Technical scope

The app itself is two targets:

1. **`Pente` (host app)** — tiny SwiftUI stub. Users don't "launch" it in a meaningful way; it exists because iMessage extensions require a host.
2. **`Pente MessagesExtension`** — the actual product. Hosts the SwiftUI game view inside an `MSMessagesAppViewController`, reads/writes game state from `MSMessage.url`.

Both targets depend on a third, non-target unit:

3. **`PenteCore` (local SwiftPM package)** — pure game logic with no Apple-UI dependencies. Runnable with `swift test` in ~0.01 s with no simulator.

---

## 4. Solution strategy

The four load-bearing architectural decisions are all recorded in ADRs; this section summarizes the shape.

| # | Strategy | Why | ADR |
|---|---|---|---|
| S1 | **iMessage extension as the primary (only) form factor.** | Turn-based mechanics map naturally to async messaging. GamePigeon established the viability of the pattern. | ADR-0001 |
| S2 | **Stateless client. State lives in `MSMessage.url` query parameters.** No server, no CloudKit, no `UserDefaults` persistence. | Zero infra cost, trivially offline, the thread is the single source of truth. Aligns with G4. | ADR-0005 |
| S3 | **Pure game logic in a local SwiftPM package (`PenteCore/`)**, UI in the extension target. | Fast test loop (`swift test` <1 s). Makes G5 viable — PenteCore is the portable chunk of a future WeChat/AI rewrite. | ADR-0004 |
| S4 | **Two-step move UX: "place tentatively → confirm".** A pending stone shows a solid blue ring; the most recently committed stone shows a solid green ring. | Eliminates the "I misclicked and now you've seen my move" class of complaint. Captures visibly preview before firing. Matches GamePigeon's reference flow. | ADR-0002 |

Cross-cutting: the app is driven by a single `@Published`-heavy `PenteGameModel` observed by SwiftUI views. No reactive framework beyond Combine's built-in `ObservableObject`. No navigation stack (one screen).

---

## 5. Building blocks

### 5.1 Dependency graph

```
  ┌──────────────────────────────────────────────────────────┐
  │  Pente MessagesExtension (target, iOS 18.5)              │
  │                                                          │
  │    MessagesViewController (UIKit host, MSMessages)       │
  │          │                                               │
  │          ▼                                               │
  │    PenteGameView / PenteBoardView  (SwiftUI)             │
  │          │        ▲                                      │
  │          ▼        │                                      │
  │    PenteGameModel (ObservableObject)  ◀──── observes ────│
  │          │                                               │
  │          ▼                                               │
  │    BoardImageGenerator (UIKit CoreGraphics, for bubble)  │
  │          │                                               │
  │          ▼                                               │
  │  ───────────────────────────────────────────────────── PenteCore/
  │    GameTypes, GameBoard, CaptureEngine, WinDetector,
  │    GameStateEncoder (+ DecodedGameState, GameStateDecoder)
  │                                                          │
  │  Localizable.xcstrings (en + zh-Hans)                    │
  └──────────────────────────────────────────────────────────┘

  ┌──────────────────────────────────────────────────────────┐
  │  Pente (host app target)                                 │
  │    ContentView (placeholder — directs user to Messages)  │
  └──────────────────────────────────────────────────────────┘
```

### 5.2 `PenteCore` (Swift package) — pure logic layer

Path: `PenteCore/Sources/PenteCore/`. No `import UIKit`, no `import SwiftUI`. iOS 16+, macOS 13+ for portability.

| File | Responsibility | LOC |
|---|---|---|
| `GameTypes.swift` | `Player` enum (wire format frozen to `"Black"`/`"White"` rawValue), `GameState`, `WinMethod`, `GameMoveDelegate` protocol. | ~36 |
| `GameBoard.swift` | 19×19 `[[Player?]]` grid with safe subscript, `placeStone`, `removeStone`, `reset`. `size = 19` is a public static constant. | ~46 |
| `CaptureEngine.swift` | Pente sandwich detection. Static `findCaptures(on:at:by:)` checks all 8 directions for the `P-O-O-P` pattern. Stateless. | ~55 |
| `WinDetector.swift` | Static `checkFiveInARow(on:at:for:)` walks from last-placed stone in 4 axes. `checkCaptureWin(capturedCount:)` is a `>= 5` check. Does **not** currently surface the winning line (ADR-0019 future). | ~44 |
| `GameStateEncoder.swift` | Two structs: `GameStateEncoder.encodeToQueryItems(...)` → `[URLQueryItem]`. `GameStateDecoder.decodeFromURL(_:)` → `DecodedGameState?`. Wire format documented in §6.2. | ~140 |

PenteCore has its own test target (`PenteCoreTests`) with five files mirroring the sources (40 tests), runnable with `cd PenteCore && swift test`.

### 5.3 `Pente MessagesExtension` — UI + platform integration layer

Path: `Pente MessagesExtension/`.

| File | Responsibility | LOC |
|---|---|---|
| `MessagesViewController.swift` | `MSMessagesAppViewController` subclass. Hosts SwiftUI via `UIHostingController`. Owns the extension lifecycle (`willBecomeActive`, `didReceive`). Assigns the local player's color from `MSConversation.localParticipantIdentifier` vs `blackPlayerID`. Builds `MSMessage` with `MSMessageTemplateLayout`, generates the dynamic-themed board thumbnail via `UIImageAsset`. Owns `currentSession: MSSession?` so every move in a game lives under the same session. | ~232 |
| `PenteGameModel.swift` | `ObservableObject`. Orchestrates PenteCore calls and exposes `@Published` state to SwiftUI. Implements the two-step move flow (`makeMove` / `confirmMove` / `undoMove`), player assignment (`canMakeMove`, `waitingForOpponent`), new-game kickoff, and URL round-trip. `confirmMove()` clears pending state *before* appending to `moveHistory` — see ADR-0017. | ~203 |
| `PenteGameView.swift` + `PenteBoardView` | SwiftUI. Title, capture counts (localized header labels), the board (Canvas-rendered), and a state-dependent bottom cluster (Undo/Send, Send, "Your turn" / "Waiting", "New Game"). A hidden-but-sized ZStack keeps the bottom cluster's height constant across states — see ADR-0018. `Color(hex:)` helper. | ~380 |
| `BoardImageGenerator.swift` | UIKit CoreGraphics renderer. Produces a 300×300 `UIImage` for the iMessage bubble thumbnail. Mirrors the live view's theme palette so light/dark handoff looks continuous. Draws the last-move green ring. | ~131 |
| `Localizable.xcstrings` | String catalog (en, zh-Hans). 22 keys. Comments distinguish transmitted-with-message strings from locally-rendered ones. | n/a |
| `Assets.xcassets` | iMessage App Icon set (Messages-27x20, Messages-32x24, iPhone-60x45, iPad-67x50, iPad-Pro-74x55, App Store 1024×768). See ADR-0014. |
| `Info.plist` | Extension metadata. `NSExtension.NSExtensionPointIdentifier = com.apple.message-payload-provider`. `ITSAppUsesNonExemptEncryption = NO` (v1.1). |

### 5.4 `Pente` (host app target)

Stub SwiftUI app. The meaningful icon set lives here too (the host app icon is what App Store shows for the listing). The host app itself is a placeholder — its only real job is to exist so the extension can be distributed.

### 5.5 `PenteTests` — simulator test target

Path: `PenteTests/`. Xcode's filesystem-synchronized group mechanism compiles the extension sources directly into the test bundle (no `@testable import` keyword; `import Messages` + direct class access is sufficient). 11 files, 258 tests as of commit `e0c17c3` (per that commit body). Duplicates some PenteCore territory — the extension target re-imports the core for integration-level assertions.

Key test files:

- `PenteGameModelTests.swift` — includes `objectWillChange`-based invariant tests for the `confirmMove` reorder (see ADR-0017).
- `BoardImageGeneratorTests.swift` — pixel-sampling tests. Fixed a Y-flip bug in the helper (`UIGraphicsImageRenderer`'s `cgImage` is already top-down; no flip needed) — any future pixel-sampling helper must NOT reinvent the flip.
- `LocalizationCatalogTests.swift` — resolves every key against the compiled catalog and asserts the English values match expected strings. It does NOT validate zh-Hans translations or assert translation quality (see the test-file header comment).
- `MessagesViewControllerTests.swift` — player-assignment + message round-trip.

---

## 6. Runtime view

### 6.1 Game lifecycle (happy path, two players)

```
Player A (starts)                       Player B
─────────────────                       ─────────────────
open Messages → tap Pente app
  │
  │ willBecomeActive(conversation)
  │   no selectedMessage → startNewGame()
  │   localParticipantID → blackPlayerID
  │   setPlayerAssignment(.black, blackID)
  │   currentSession = MSSession()   ◀── new game = new session
  │   center stone pre-placed, isNewGamePendingSend=true
  │
  │ tap "Send"
  │   sendFirstMove() → moveDelegate.gameDidMakeMove()
  │     createMessage(): MSMessage(session: currentSession)
  │       url = URLComponents(queryItems: encodeToQueryItems())
  │       layout.caption = "Pente"
  │       layout.subcaption = "Black's turn (Move 2)"  [sender locale]
  │       layout.trailingSubcaption = "●0 ○0"           [if captures > 0]
  │       layout.image = createDynamicBoardImage(300×300) [light + dark asset]
  │     conversation.insert(message) → dismiss()
  │                                       ──────▶
  │                                       didReceive(message, conversation)
  │                                         loadFromURL(message.url)
  │                                         assignPlayerRole(from: conversation)
  │                                           localParticipantID != blackID → .white
  │                                       (B taps an empty intersection)
  │                                       makeMove(r,c)
  │                                         place stone tentatively
  │                                         pendingCaptures = CaptureEngine.find(...)
  │                                         pendingMove=(r,c), blue ring shown
  │                                       tap Send → confirmMove()
  │                                         clear pending FIRST
  │                                         append moveHistory
  │                                         apply captures
  │                                         check 5-in-a-row / 5-captures
  │                                         flip currentPlayer if still playing
  │                                         updateMovePermissions()
  │                                         delegate.gameDidMakeMove() → sendMessage()
  │                                       ◀──────
  │ didReceive → loadFromURL, assignPlayerRole → waitingForOpponent=false
  │  ... repeat until win ...
```

### 6.1a New-game opening

The player who starts a game is Black. Their first visible action is already done for them: `startNewGame()` auto-places Black at the center (`(9,9)` on a 19×19 board) as a committed move, switches `currentPlayer` to `.white`, and sets `isNewGamePendingSend = true`. The starter only sees one button — "Send" — which fires the first message and dismisses the extension. White makes the first interactive move of the game. See ADR-0025.

### 6.2 Wire format — `MSMessage.url` query string

Per `GameStateEncoder.swift` / `GameStateDecoder.swift`:

| Key | Example value | Meaning |
|---|---|---|
| `moves` | `B9,9;W10,10;B8,10;` | Ordered move history. `[BW]<row>,<col>;`. Decoder **replays** moves and recomputes captures — captures are *not* serialized. |
| `current` | `Black` / `White` | Whose turn it is. Matches `Player.rawValue` (wire format, frozen). |
| `capB` | `2` | Pairs captured by Black. |
| `capW` | `0` | Pairs captured by White. |
| `state` | `playing` / `won` | Game state. |
| `winner` | `Black` / `White` | Present only if `state=won`. |
| `method` | `fiveInARow` / `fiveCaptures` | Present only if `state=won`. |
| `blackID` | UUID string | The iMessage local-participant identifier of the player who started this game. Used by the receiver to self-assign `.black` or `.white`. |

Design implications of this format:

- **Captures must be recomputable from the move list.** The decoder calls `CaptureEngine.findCaptures` as it replays each move. Any change to capture rules is a breaking change to game resumes (new clients would compute different captures from the same history). Note that `capB`/`capW` are encoded for debuggability but **not read by the decoder** — replay is authoritative (ADR-0027).
- **Winning line is not encoded.** If v1.4 adds a gold-ring winning-line highlight, the line is recomputed from `moveHistory` on load to keep the URL small (ADR-0019 planned).
- **Last-capture positions are not encoded.** This is why Mehera's "where did the stones go?" complaint is logged in roadmap item 8 — fixing it requires adding an `lc=` param.

### 6.3 Player-assignment logic (ADR-0007)

The critical bug fixed in Dec 2025 (commit `ec3b909`): before the fix, both participants could move either color because turn enforcement was purely client-local. Current logic:

1. The first player to open a new game becomes Black. Their `MSConversation.localParticipantIdentifier.uuidString` is written into the `blackID` URL param on the first sent message.
2. On every subsequent `didReceive` / `willBecomeActive`, the extension compares the local participant's UUID to `blackID` in the loaded state. If equal → `.black`, otherwise → `.white`.
3. `PenteGameModel.canMakeMove` is true only when `currentPlayer == assignedPlayerColor`. `makeMove` guards on this flag and exits early otherwise.
4. Before a color is assigned, `canMakeMove = true` (permissive fallback). This branch is unreachable for well-formed v1.1+ messages (every sent message includes `blackID`) but IS reachable for malformed or pre-v1.1 state — the decoder tolerates missing `blackID` and the controller then calls `setPlayerAssignment(nil, blackPlayerID: nil)`, emitting a `#if DEBUG print`. See ADR-0026 for the silent-failure surface this creates.

Note: `MSConversation.localParticipantIdentifier` is a per-app-per-conversation opaque UUID that Apple rotates with Messages-data resets. If a user clears Messages data mid-game, they will be locked out of their color — this is an accepted limitation.

### 6.4 Session model (ADR-0006)

Every game has one `MSSession`. The extension caches `currentSession: MSSession?`. On `willBecomeActive` with a selected message, it reuses `message.session`; on a new game it creates a fresh `MSSession()`. The observed behavior this enables is **transcript coalescence** — all moves in a single game update one bubble in-place rather than producing N bubbles. Apple's own Messages behavior may include additional replay or caching semantics around sessions; those are not enforced by any code in this repo.

### 6.5 Board image thumbnail (dynamic theme)

The bubble shows a 300×300 image. We render *both* a light and a dark variant and register them on a `UIImageAsset` keyed by `UITraitCollection.userInterfaceStyle`. The bubble then resolves the correct one against the **viewer's** device theme for the board palette. (Limitation: the last-move ring color is resolved at sender render time and baked in — see ADR-0013.) See ADR-0021 for the mechanism.

---

## 7. Deployment view

### 7.1 Build variants

- **Simulator Debug** — `build_run_sim` via XcodeBuildMCP, default simulator `EF30FA9D-…` (iPhone 16). Defaults persisted in `~/.xcodebuildmcp/config.yaml`.
- **Device Debug** — physical device (`00008150-00121C682E91401C`, iOS 26.3.1) for iMessage extension validation. Requires paid developer program.
- **Release** — Archive → Export IPA via `ExportOptions.plist` → `altool` upload to App Store Connect → ASC API creates version / attaches build / sets What's New / submits review.

### 7.2 Release pipeline

Release flow uses a mix of `xcodebuild`, `xcrun altool`, and the ASC REST API (`.claude/CLAUDE.md` has credentials and endpoint reference). An Xcode GUI fallback path is also documented in `APP_STORE_SUBMISSION.md`:

1. Archive: `xcodebuild … archive`
2. Export IPA: `xcodebuild -exportArchive … -exportOptionsPlist ExportOptions.plist`
3. Upload: `xcrun altool --upload-app … --apiKey 423RCYC29Y --apiIssuer a6c794e7-…`
4. `POST /v1/appStoreVersions` (create)
5. `PATCH /v1/appStoreVersions/{id}/relationships/build` (attach the uploaded build)
6. `PATCH /v1/appStoreVersionLocalizations/{id}` (What's New text)
7. `POST /v1/reviewSubmissions` + `POST /v1/reviewSubmissionItems` → `PATCH submitted=true`
8. Set `releaseType` on the new version. Intended policy is `AFTER_APPROVAL` (documented in ADR-0015 as policy only — no committed artifact records the value actually used on past submissions).

### 7.3 Version-bump and release history

Two separate kinds of fact here:

1. **Version-bump commits** — objective repo state: what `project.pbxproj` contained, which commit set it, when.
2. **Release status** — developer-authored attestation in `APP_STORE_SUBMISSION.md` and `FEATURE_ROADMAP.md`. These are committed files but they are not pulled from the ASC API and can go stale between releases. Authoritative state lives in App Store Connect.

| Version | Build | Version-bump commit | Commit date | Release per repo docs | Source changes in this version |
|---|---|---|---|---|---|
| 1.0 | 1–2 | — (initial) | 2025-06-29 (`f2775af`) | Released Aug 2025 (`APP_STORE_SUBMISSION.md`) | First playable extension. Build-2 origin not in git. |
| 1.1 | 3 | `423b75d` | 2026-03-02 | Released Mar 2026 (`APP_STORE_SUBMISSION.md`) | New icon set; `ITSAppUsesNonExemptEncryption=NO`. Includes prior player-assignment fix (`ec3b909`, Dec 2025) and dynamic-theme thumbnail. |
| 1.2 | 5 | `72d99a2` | 2026-04-05 | Last documented as "In Review" (`APP_STORE_SUBMISSION.md`); subsequent disposition not in repo | PenteCore SwiftPM extraction; MSSession per game introduced. |
| 1.3 | 6 | `776d8b0` | 2026-04-23 | SHIPPED 2026-04-24 per `FEATURE_ROADMAP.md` and project-owner conversation | Simplified Chinese localization; last-move blue/green rings; board layout stability ZStack. |
| 1.4 | 7 | uncommitted (working tree) | 2026-07-16 | In development — not submitted | GamePigeon-ification: one-tap send + failure ladder (ADR-0029/0037), haptics (0034/0038), gold win ring (0019), tap-outside cancel (0030), single-slot status (0031/0040), win overlay + auto-send rematch (0032/0039), stone animation (0033), pinch-zoom (0041), capture-on-resume (0042), rules overlay (0043). |

Cross-reference App Store Connect (App ID `6748970073`) via the ASC API endpoints in `.claude/CLAUDE.md` if you need the authoritative record.

### 7.4 ASC listing

- **Name**: "Pente"
- **Bundle ID**: `colemadden.Pente`
- **SKU**: `PenteForIMessage`
- **App ID (ASC)**: `6748970073`
- **Team ID**: `SB4A7WG2KH`
- **Vendor Number**: `93577601` (for Sales Reports API)
- **API key**: `423RCYC29Y` (in `AuthKey_423RCYC29Y.p8`, gitignored)
- Supported locales: en; zh-Hans in-app complete (landed in the v1.3 target commit); ASC listing localization queued to ride v1.4. Draft copy is in `zh-hans-asc-review.txt`; project-owner memory attests it was reviewed by a native speaker out of band, but no signed reviewer note is committed to the repo.

---

## 8. Crosscutting concepts

### 8.1 Theming (light / dark)

- Live view palette is defined in `PenteGameView.swift` via `@Environment(\.colorScheme)` and `Color(hex:)` helpers.
- Bubble thumbnail palette is mirrored in `BoardImageGenerator.swift` using `UIColor(red:green:blue:alpha:)` values that match the hex constants.
- Last-move ring uses `Color(.systemGreen)` in the live view and `UIColor.systemGreen.cgColor` in the thumbnail. The live view resolves adaptively in the viewer's trait collection. The thumbnail is dual-rendered (light + dark) for the *board palette* — but the ring itself uses whatever systemGreen resolved to against the sender's active trait collection at render time and is then baked into the bitmap. See ADR-0013 for a precise statement of what adapts and what doesn't.
- The board background is a warm tan (`#D4A574`) in light mode, dark wood (`#3E2723`) in dark mode. No accessibility knob to override. Contrast ratios have not been formally validated.

### 8.2 Localization

- String catalog is `Localizable.xcstrings`, not `.strings` files. Chose xcstrings for Xcode 15+'s state tracking and for a single-file audit surface. See ADR-0010.
- **`Player.rawValue` (`"Black"`/`"White"`) is wire format and must never be translated.** `Player.displayNameKey` returns the locale key instead. This separation is enforced by a code comment in `GameTypes.swift:11-16` and by `LocalizationCatalogTests`.
- `MSMessageTemplateLayout.caption` / `subcaption` / `trailingSubcaption` travel *with* the `MSMessage` — the receiver does NOT re-render them. That means subcaption renders in the **sender's** locale for everyone. `trailingSubcaption` therefore uses locale-neutral circle glyphs (●/○) instead of localized text. See ADR-0011 and the comment at `MessagesViewController.swift:170-199`.
- zh-Hans copy disambiguates Pente from Gomoku — `夹吃` (capture) is present in every *capture-win* banner so Chinese users understand why stones disappeared; five-in-a-row banners use `五子连珠` instead. `zh-hans-review.txt` is a questionnaire for a native reviewer; as of this writing it has not been returned populated, and `zh-hans-asc-review.txt` contains LLM-drafted ASC listing copy, not reviewer notes. Treat translations as unreviewed by a native speaker.
- Extension bundle lookup is via `Bundle(for: MessagesViewController.self)` because in XCTest `Bundle.main` resolves to the test runner. `Bundle(for:)` returns the compiled bundle that contains the class — which in this project's test layout (filesystem-synchronized group compiles the extension sources into the test bundle) also contains the xcstrings catalog. See ADR-0023 and `MessagesViewController.swift:12-16`.

### 8.3 Testing strategy

Three tiers:

1. **PenteCore unit tests** — `cd PenteCore && swift test`. 40 tests, <1 second, no simulator. These are the pre-commit gate (`.git/hooks/pre-commit`).
2. **Full extension test suite** — `xcodebuild test -scheme PenteTests`. 258 tests as of commit `e0c17c3`. Required before any App Store submission per `CLAUDE.md` release checklist. Includes UI, image, localization, and Messages-framework integration tests.
3. **Physical device** — required for final iMessage validation (Apple only exercises extension lifecycle paths fully on-device).

Test policy (see `CLAUDE.md` "MANDATORY TESTING REQUIREMENTS"): every new feature/fix ships with tests. 100% coverage of new code is the stated bar, enforced socially (not by tooling).

The pre-commit hook deliberately runs *only* PenteCore tests — it must stay fast enough to not discourage small commits. The full suite runs in CI-style manual invocation before releases. See ADR-0016.

### 8.4 Error handling

Minimal. The two guard points are:

- URL decoding — `GameStateDecoder.decodeFromURL` returns `nil` only when the URL has no `URLComponents`/query items at all. Individual malformed fields are tolerated: unrecognized move entries are skipped, bad `current`/`winner`/`method` fall back to defaults (`.black` / `.playing`). `loadFromURL` silently does nothing when the decoder returns nil; otherwise it applies whatever it managed to reconstruct.
- Move legality — `PenteGameModel.makeMove` short-circuits on: game over, new-game-pending, `!canMakeMove`, occupied intersection.

No analytics, no crash reporting, no error UI. If something goes wrong the user sees a stale or unchanged board. This is a deliberate tradeoff for G4 (zero infra).

### 8.5 Secrets management

- ASC API key (`AuthKey_*.p8`), distribution cert, and `.claude/` are all gitignored.
- The project CLAUDE.md references credentials at the path `./.claude/CLAUDE.md` — local file, never committed. The `0ee9c40` commit (2026-04-06) moved credentials out of the committed `CLAUDE.md` into that local file.

### 8.6 AI agent workflow

- **Claude Code** drives most development. `CLAUDE.md` sets its guardrails: code minimization + the decision documentation rule (this doc + `docs/adr/`).
- **Codex** runs adversarial reviews on plans, code reviews on diffs, and investigation rescues. `/codex:adversarial-review` is mandatory before non-trivial plans per the global CLAUDE.md. A review gate can be enabled per-project.

---

## 9. Quality requirements

| Quality | Requirement | How it's enforced |
|---|---|---|
| Correctness | Capture rules and win detection must match canonical Pente. | Pente® Rules PDF kept in repo as canonical source. 258+ tests. |
| Performance | Tap-to-stone-render < 1 frame (16 ms). Canvas redraw is the hot path but stays fast because the board is only 19×19 with at most ~50 stones mid-game. | No formal measurement; acceptance is visual. |
| Correctness under theme handoff | Last-move ring must visibly match in live view and bubble thumbnail. | Pixel-sampling tests in `BoardImageGeneratorTests.swift`. |
| Install size | Minimal. No bundled audio/video yet. | v1.4 sound effects must budget-check this. |
| Localization fidelity | Every user-visible string has en + zh-Hans. | `LocalizationCatalogTests.swift` asserts coverage. |
| Privacy | No PII leaves the device. No network calls from the app. | Code review (no URLSession in the extension). See PRIVACY.md. |
| Accessibility | Open debt. No VoiceOver audit. No Dynamic Type test. No contrast audit. | Untested risk — see §10.4. |

---

## 10. Risks and technical debt

### 10.1 Product-level risks

- **iMessage-only distribution caps the market.** 1,800+ Chinese downloads despite zero WeChat presence implies latent demand we cannot serve. Mitigation path is a v2.0 standalone app + Game Center multiplayer or a WeChat mini-program port (FEATURE_ROADMAP §15–§17; the whole point of ADR-0004 making PenteCore portable).
- **No rematch flow.** "New Game" resets locally without notifying the opponent. Users in session momentum have to manually re-engage. Roadmap v1.4 item 9.
- **No AI opponent.** A user with no friend willing to respond bounces. Roadmap v2.0 item 16.
- **Capture ambiguity on resume.** Receivers see stones disappear with no visible cue. Reported by Mehera. Roadmap v1.4 item 8. Requires wire-format change (`lc=` param).

### 10.2 Code / design debt

- **Board layout instability.** The board resizes when the bottom status cluster changes state. Mitigated in the v1.3 target commit with a hidden-sized ZStack (ADR-0018) but not fixed at root. `PenteGameView.swift` layout is flagged for overhaul in v1.4 (item 12).
- **`PenteTests/` duplicates `PenteCoreTests/`.** Both cover core logic. This is historical (the PenteCore extraction in v1.2 left the extension-side tests in place). Not yet reconciled.
- **`WinDetector` does not surface the winning line.** Blocks the planned gold-ring highlight. Will require a minor API change (ADR-0019).
- **Move-history tuples, not a struct.** `(row: Int, col: Int, player: Player)` tuples flow through encoder/decoder/model. Works but is noisy. Breaking change deferred.
- **`MessagesViewController` handles too much.** Session management, player assignment, message construction, and image generation are all in one class. Fine at current size; worth splitting if it grows.

### 10.3 Operational debt

- **No CI.** Tests run pre-commit (fast path) or manually (full path). No GitHub Actions.
- **No crash reporting / analytics.** Deliberate (privacy stance), but it means we only find bugs via user reviews.
- **No structured error channel.** `#if DEBUG print()` statements are the only telemetry.

### 10.4 Accessibility debt

- No VoiceOver labels. Canvas-drawn stones are invisible to screen readers.
- Contrast ratios not formally validated (dark-mode `#3E2723` on a dark system background may be borderline).
- No Dynamic Type support audit.

### 10.5 Internationalization debt

- App Store listing localization (name/subtitle/description/screenshots) for zh-Hans is not yet live — draft copy is in `zh-hans-asc-review.txt`, queued to apply with v1.4. Native-reviewer signoff is owner-attested in agent memory but not present in any committed repo artifact.
- `MSMessageTemplateLayout` subcaption asymmetry is documented but not resolved: a Chinese sender sending to an English receiver shows Chinese in the bubble. This is intrinsic to Messages and probably unfixable without switching to locale-neutral glyphs for all layout strings.

### 10.6 Product UX debt

- **`conversation.insert` vs `conversation.send`** — today's Send button pops the user into the compose field for a second tap. GamePigeon Gomoku sends immediately. See ADR-0024 — the current behavior is accepted as status-quo and not a principled decision. FEATURE_ROADMAP v1.4 item 5 proposes flipping to `send`.
- **No rematch protocol** — the "New Game" button on the win screen resets locally without notifying the opponent. Treated as product debt; see FEATURE_ROADMAP v1.4 item 9.
- **No capture cue on resume** — a receiver opens the game and sees stones just… gone. Mehera reported this; fix requires an `lc=` wire-format addition. FEATURE_ROADMAP v1.4 item 8.

---

## 11. Glossary

| Term | Meaning |
|---|---|
| **Five in a row** | First win condition. Five of your stones consecutive along any axis. Equivalent to Gomoku win condition. |
| **Capture / sandwich** | Pente's distinguishing mechanic. Placing your stone such that exactly two adjacent opponent stones are bracketed between two of yours (`P-O-O-P`) along one of 8 directions removes those two stones. |
| **Capture win / five captures** | Second win condition. Capturing 5 pairs (10 stones) ends the game. Tracked as `capturedCount[.black]` / `[.white]` — these count *pairs*, not stones. |
| **`PenteCore`** | The pure-logic SwiftPM package. Portable, testable without a simulator. |
| **Pending move** | A stone the local player has tapped but not yet sent. Shown with a blue ring. Can be undone. |
| **Committed move / last move** | The most recent confirmed move, shown with a green ring. Matches GamePigeon Gomoku's convention. |
| **`MSSession`** | Apple's per-game-thread identifier. Causes related messages to coalesce into a single updating transcript bubble rather than producing N bubbles. No repo-side logic enforces replay protection — any additional session-level semantics come from Apple's own Messages implementation. |
| **`blackPlayerID`** | The UUID (from `MSConversation.localParticipantIdentifier`) of the player who started the game. Used by receivers to resolve their color. |
| **`MSMessageTemplateLayout`** | Apple's bubble layout type. Caption, subcaption, trailingSubcaption, image. Text fields travel with the message — rendered in sender locale. |
| **`UIImageAsset` trait registration** | UIKit mechanism to register distinct images for different `UITraitCollection`s so the system auto-picks the right one at render time. Used for light/dark bubble thumbnails. |
| **Wire format** | Anything that appears in a `MSMessage.url` query param. Must stay stable across versions or old games break on resume. Includes `Player.rawValue`, `WinMethod.rawValue`, `state` values, and the `moves` move-list syntax. |
| **xcstrings** | Xcode 15+ string catalog format. Single JSON file replacing per-locale `.strings`. |
| **ADR** | Architecture Decision Record. See `docs/adr/README.md`. |

---

## Appendix A — Source file index

```
.
├── CLAUDE.md                          # agent guardrails (code-min + decision doc rules)
├── .claude/CLAUDE.md                  # local/secret credentials (gitignored)
├── FEATURE_ROADMAP.md                 # ranked v1.3 / v1.4 / v2.0 features
├── APP_STORE_SUBMISSION.md            # release process + version history
├── PRIVACY.md                         # privacy policy (public)
├── README.md                          # store-facing README
├── pente-project-summary.md           # historical project journal (gitignored, not always present)
├── zh-hans-review.txt                 # questionnaire for native-reviewer notes (in-app strings)
├── zh-hans-asc-review.txt             # draft zh-Hans ASC listing copy (LLM-derived; owner attests out-of-band native review, not committed)
├── Pente® Rules.pdf                   # canonical rules reference
├── PenteCore/                         # pure-logic SwiftPM package
│   ├── Package.swift
│   ├── Sources/PenteCore/*.swift      # GameTypes, GameBoard, CaptureEngine, WinDetector, GameStateEncoder
│   └── Tests/PenteCoreTests/*.swift
├── Pente/                             # host app target (stub)
├── Pente MessagesExtension/           # the product
│   ├── MessagesViewController.swift
│   ├── PenteGameModel.swift
│   ├── PenteGameView.swift
│   ├── BoardImageGenerator.swift
│   ├── Localizable.xcstrings
│   └── Info.plist
├── PenteTests/                        # simulator test target (258 tests)
├── Pente.xcodeproj/
├── ExportOptions.plist                # release export config
├── docs/
│   ├── ARCHITECTURE.md                # THIS FILE
│   └── adr/                           # decision ledger
└── .git/hooks/pre-commit              # runs PenteCore tests
```

## Appendix B — Related documents

- `docs/adr/README.md` — decision ledger index
- `docs/adr/0001-imessage-extension-primary-form-factor.md` through `docs/adr/0028-*.md` — individual decisions
- `FEATURE_ROADMAP.md` — forward-looking feature plan
- `CLAUDE.md` — agent development rules (code minimization + decision documentation)
