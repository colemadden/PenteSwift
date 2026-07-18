# 0026 — Permissive fallback: no player assignment ⇒ all moves allowed

- **Status**: Accepted (documented; silent-failure risk — see Consequences)
- **Date**: 2025-12-16
- **Version**: v1.1
- **Source**: `Pente MessagesExtension/PenteGameModel.swift:32-41`; `PenteTests/PenteGameModelTests.swift:697-703`

## Context

After ADR-0007, every production game has a `blackPlayerID` set. But the model must handle the *initial* state (before `willBecomeActive` assigns anything), and must behave sensibly if a malformed or pre-v1.1 message ever omits `blackID`.

`updateMovePermissions()` is called whenever `assignedPlayerColor` changes or the turn flips.

## Decision

When `assignedPlayerColor == nil`, `canMakeMove = true` and `waitingForOpponent = false`. The UI shows as if it's the local player's turn — no lock, no warning.

When `assignedPlayerColor != nil`, `canMakeMove = (currentPlayer == assignedColor)`.

## Alternatives considered

- **Fail closed: no assignment ⇒ `canMakeMove = false`, show a warning.** Would prevent silent turn-hijack, but also locks out the initial-boot frame before `willBecomeActive` completes, producing flicker.
- **Crash / assert on missing assignment.** Rejected: would crash the extension on any pre-v1.1 message still in the wild.
- **Heuristic (e.g. infer color from move parity).** Rejected: brittle and wrong after captures.

## Consequences

- For well-formed v1.1+ game state, the fallback path is unreachable — every sent message includes `blackID`, and `assignPlayerRole(from:)` then flips `canMakeMove` to color-gated. BUT: the decoder tolerates a missing `blackID` (it's an optional field), and `assignPlayerRole` explicitly calls `setPlayerAssignment(nil, blackPlayerID: nil)` in that case. So the fallback IS reachable for malformed messages, pre-v1.1 state, or any future code path that forgets to encode `blackID`. A `#if DEBUG print` warns when the branch fires.
- In XCTest, this fallback is the *default* behavior of the raw model, which is convenient for unit testing logic without setting up participant identifiers.
- **Silent failure risk**: if a future refactor accidentally forgets to call `setPlayerAssignment`, or a malformed message omits `blackID`, both players could move either color — the exact bug ADR-0007 fixed. Mitigation: `MessagesViewControllerTests` asserts assignment happens on every `didReceive` and `willBecomeActive`.
- Future hardening candidate: surface a visible "color assignment missing — please restart the game" error when the fallback runs in production. Not currently implemented.
