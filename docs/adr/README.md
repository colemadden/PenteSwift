# Pente — Architecture Decision Records

This directory is Pente's decision ledger. Every ADR captures a single non-trivial choice at the moment it was made (or, for backfilled records, reconstructed from the best available source).

Read `../ARCHITECTURE.md` for the big-picture view. Read these to understand **why** a specific thing is the way it is.

## Conventions

- Filename: `NNNN-short-slug.md`, zero-padded, monotonic.
- Never edit an accepted ADR in place — write a new ADR that supersedes it, link both directions.
- Status: `Accepted` | `Superseded by ADR-XXXX` | `Deprecated` | `Proposed`.
- Format: see `CLAUDE.md` §"Decision Documentation Rule".

Backfilled ADRs (0001–0028) were reconstructed on 2026-04-24 from git history, existing documentation, and source-code archaeology. Their `Date` reflects when the underlying decision was *made* (usually the commit that introduced it), not when the ADR was written. For ADRs where the decision date cannot be established from any committed artifact, `Date` is `unknown` rather than invented.

**What the `Version` field means.** `Version: v1.X` in an ADR's header indicates the `MARKETING_VERSION` in `project.pbxproj` at the commit where the decision landed in source — i.e., which build-target revision carries it. Whether that build reached users is a separate question, partially attested by `FEATURE_ROADMAP.md` and `APP_STORE_SUBMISSION.md`, which can conflict or go stale. Authoritative release state lives in App Store Connect. See `docs/ARCHITECTURE.md` §7.3 for the combined version-bump and release table.

## Index

### Product / distribution

| # | Title | Status | Sources |
|---|---|---|---|
| [0001](0001-imessage-extension-primary-form-factor.md) | iMessage extension as primary form factor | Accepted | `pente-project-summary.md`, `fa6bc15` |
| [0003](0003-nineteen-by-nineteen-board.md) | 19×19 board size | Accepted | `PenteCore/Sources/PenteCore/GameBoard.swift:4` |
| [0014](0014-messages-app-not-stickers.md) | Interactive Messages app, not sticker pack | Accepted | `8854fac`, `README.md` |
| [0015](0015-after-approval-release-type.md) | AFTER_APPROVAL release type (proposed policy) | Proposed | documented in the ADR only |
| [0020](0020-no-cloudkit-no-backend.md) | No CloudKit, no backend service | Accepted | `PRIVACY.md`, `pente-project-summary.md` |

### Core architecture

| # | Title | Status | Sources |
|---|---|---|---|
| [0004](0004-pentecore-swiftpm-module-split.md) | Extract pure logic into `PenteCore` SwiftPM package | Accepted | `72d99a2` (v1.2) |
| [0005](0005-url-encoded-state-in-msmessage.md) | Encode game state into `MSMessage.url` query params | Accepted | `GameStateEncoder.swift`, `pente-project-summary.md` |
| [0006](0006-mssession-per-game.md) | One `MSSession` per game | Accepted | `MessagesViewController.swift:10,82` |
| [0007](0007-uuid-based-player-assignment.md) | UUID-based `blackPlayerID` for color assignment | Accepted | `ec3b909` |
| [0008](0008-canvas-for-board-rendering.md) | SwiftUI `Canvas` for board rendering | Accepted | `PenteGameView.swift:177` |
| [0019](0019-windetector-returns-winning-line.md) | `WinDetector` returns the winning line for gold-ring highlight | Accepted | FEATURE_ROADMAP §v1.4 item 6 |
| [0037](0037-gameid-in-url-state.md) | Stable `gameID` UUID in URL-encoded state | Accepted | ADR-0029 retry guard; `GameStateEncoder.swift` |
| [0042](0042-last-captures-derived-from-replay.md) | Capture indication on resume derives from decoder replay | Accepted | FEATURE_ROADMAP §v1.4 item 8; `GameStateEncoder.swift` |

### UX

| # | Title | Status | Sources |
|---|---|---|---|
| [0002](0002-two-step-move-confirm.md) | Two-step move (place tentatively → confirm) | Accepted | `PenteGameModel.swift:49-125` |
| [0009](0009-last-move-blue-green-rings.md) | Blue ring for pending, green ring for last committed move | Accepted | `a292b98` (v1.3) |
| [0013](0013-systemgreen-adaptive-ring-color.md) | Use `systemGreen` so last-move ring adapts per viewer | Accepted | `PenteGameView.swift:311`, `BoardImageGenerator.swift:121` |
| [0018](0018-hidden-zstack-sizing-reference.md) | Hidden sizing reference in the bottom-cluster ZStack | Superseded by ADR-0040 | `PenteGameView.swift` (removed) |
| [0021](0021-dynamic-theme-thumbnail.md) | Dynamic-themed bubble thumbnail via `UIImageAsset` | Accepted | `MessagesViewController.swift:131-148`, `ec3b909` |
| [0024](0024-insert-not-send-message-flow.md) | `conversation.insert` vs `send` for the in-app Send button | Superseded by ADR-0029 | `MessagesViewController.swift` |
| [0025](0025-center-seeded-black-opening.md) | Auto-place Black's first move at the center | Accepted | `PenteGameModel.swift:181-190` |
| [0029](0029-one-tap-send-via-msconversation-send.md) | One-tap send via `MSConversation.send` + failure ladder (supersedes 0024) | Accepted | `MessagesViewController.swift` |
| [0030](0030-tap-outside-board-cancels-pending.md) | Tap outside the board cancels the pending stone | Accepted | gomoku UX walkthrough 2026-04-28 |
| [0031](0031-bottom-status-single-slot.md) | Bottom status area: single slot | Accepted (amended by 0040) | gomoku UX walkthrough 2026-04-28 |
| [0032](0032-win-loss-overlay-with-play-again.md) | "YOU WON!" / "YOU LOST!" overlay with Play Again | Accepted | gomoku UX walkthrough 2026-04-28 |
| [0033](0033-stone-placement-animation-hybrid.md) | Hybrid Canvas + overlay stone-placement animation | Accepted | FEATURE_ROADMAP §v1.4 item 13 |
| [0034](0034-haptic-mapping-v14.md) | Haptic mapping: place / capture / win | Superseded by ADR-0038 | FEATURE_ROADMAP §v1.4 item 4b |
| [0035](0035-reject-gomoku-top-chrome.md) | Reject gomoku-style top chrome (bowls + opponent pfp) for v1.4 | Accepted | gomoku UX walkthrough 2026-04-28 |
| [0036](0036-coordinate-labels-go-convention.md) | Coordinate labels, Go convention (A–T skip I) | Rejected on device review 2026-05-03 | FEATURE_ROADMAP §v1.4 item 14 |
| [0038](0038-opponent-arrival-haptic.md) | Opponent-move-arrival haptic (supersedes 0034) | Accepted | device test feedback 2026-05-03 |
| [0039](0039-play-again-auto-sends-rematch.md) | "Play Again" auto-sends the rematch message | Accepted | ADR-0032 follow-on; roadmap item 9 |
| [0040](0040-bottom-slot-keeps-turn-indicator.md) | Bottom slot keeps turn indicator; fixed-height frame (supersedes 0018) | Accepted | user direction 2026-07-16 |
| [0041](0041-pinch-zoom-transform-outside-tap-gesture.md) | Pinch-zoom/pan via transforms outside the tap gesture | Accepted | FEATURE_ROADMAP §v1.4 item 4a |
| [0043](0043-first-launch-rules-overlay.md) | First-launch rules overlay, one card, UserDefaults flag | Accepted | FEATURE_ROADMAP §v1.4 item 7 |
| [0044](0044-device-test-feedback-gold-send-capture-preview.md) | Gold Send for both win conditions; red capture-preview rings; tutorial copy | Accepted | device-test feedback 2026-07-18 |

### Localization

| # | Title | Status | Sources |
|---|---|---|---|
| [0010](0010-localizable-xcstrings-catalog.md) | `Localizable.xcstrings` (catalog) vs `.strings` files | Accepted | `Pente MessagesExtension/Localizable.xcstrings` |
| [0011](0011-locale-neutral-trailing-subcaption.md) | Locale-neutral circle glyphs for trailing subcaption | Accepted | `MessagesViewController.swift:195-199` |
| [0022](0022-player-rawvalue-wire-vs-display.md) | Separate wire `Player.rawValue` from display key | Accepted | `PenteCore/Sources/PenteCore/GameTypes.swift:11-16` |
| [0023](0023-extension-bundle-lookup-for-xcstrings.md) | `Bundle(for: self)` to find the xcstrings catalog in XCTest | Accepted | `MessagesViewController.swift:12-16` |
| [0028](0028-zh-hans-capture-terminology.md) | zh-Hans: `夹吃` verb vs `吃对` noun distinction | Accepted (per owner direction; no committed reviewer signature) | `Localizable.xcstrings`, draft `zh-hans-asc-review.txt` |

### Implementation invariants

| # | Title | Status | Sources |
|---|---|---|---|
| [0017](0017-confirmmove-clear-before-append.md) | `confirmMove()` clears pending state before appending history | Accepted | `a292b98`, `PenteGameModel.swift:85-125` |
| [0026](0026-permissive-fallback-unassigned-player.md) | No player assignment ⇒ all moves allowed (fallback) | Accepted (silent-failure risk) | `PenteGameModel.swift:32-41` |
| [0027](0027-decoder-replays-moves-authoritative.md) | Decoder replays moves; `capB`/`capW` are informational | Accepted | `GameStateEncoder.swift:88-116` |

### Engineering workflow

| # | Title | Status | Sources |
|---|---|---|---|
| [0016](0016-pre-commit-hook-pentecore-only.md) | Pre-commit runs only PenteCore tests | Accepted | `.git/hooks/pre-commit` |
| [0012](0012-encryption-export-compliance.md) | Declare `ITSAppUsesNonExemptEncryption=NO` | Accepted | `d6f6fbc`, `Info.plist` |

### Known gaps (documented for future ADRs when the decision lands)

| # | Topic |
|---|---|
| tbd | Board layout stability at root (v1.4 item 12, supersedes 0018) |
| tbd | Pinch-to-zoom coordinate-transform approach (v1.4 item 4a) |
| tbd | Rematch flow message schema (v1.4 item 9) |
| tbd | Last-capture positions wire-format addition `lc=` (v1.4 item 8) |
