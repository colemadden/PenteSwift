# 0004 — Extract pure logic into `PenteCore` SwiftPM package

- **Status**: Accepted
- **Date**: 2026-04-05
- **Version**: v1.2
- **Source**: version-bump commit `72d99a2` (message begins "Release v1.2 — Modular PenteCore refactor and UI improvements"; the word "Release" is the committer's phrasing, not a claim about ASC release status); `PenteCore/Package.swift`; `APP_STORE_SUBMISSION.md:13-22`

## Context

Before v1.2, all game logic lived in the extension target. Running the full test suite required booting a simulator and taking 10+ seconds per iteration. This discouraged tight TDD loops. The logic (board state, capture detection, win detection, URL encoding) had no UIKit/SwiftUI dependencies and was genuinely portable — it was only in the extension target because that's where the files were born.

## Decision

Extract all pure logic into a local Swift package `PenteCore/` with targets `PenteCore` and `PenteCoreTests`. Extension code imports `PenteCore`. PenteCore declares `platforms: [.iOS(.v16), .macOS(.v13)]` — intentionally broader than the extension's iOS 18.5 deployment target, to keep PenteCore usable in future ports.

Files moved into PenteCore: `GameTypes.swift`, `GameBoard.swift`, `CaptureEngine.swift`, `WinDetector.swift`, `GameStateEncoder.swift`.

## Alternatives considered

- **Leave everything in the extension.** Rejected: simulator boot makes the inner dev loop too slow.
- **Separate framework target inside the Xcode project.** Rejected: SwiftPM is lighter and lets `swift test` work outside Xcode.
- **Separate git repo.** Rejected: premature — versioning and distributing an unused-by-others package is pure overhead.

## Consequences

- `cd PenteCore && swift test` runs the logic suite in <1 second. This is the pre-commit gate (ADR-0016).
- PenteCore is the portable chunk for any future port (standalone app, WeChat mini-program reimplementation, or AI opponent that needs to run the rules engine).
- The extension still keeps a `PenteTests/` target that re-covers PenteCore territory — these duplicate each other and are documented debt (ARCHITECTURE.md §10.2).
- Public API of PenteCore is a wire contract: breaking signature changes break the extension. Changes to types that appear in `MSMessage.url` are breaking for *old games* too (see ADR-0005).
