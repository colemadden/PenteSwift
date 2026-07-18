# 0025 — Starting a new game auto-places Black at the center

- **Status**: Accepted
- **Date**: 2025-06-29
- **Version**: v1.0
- **Source**: `Pente MessagesExtension/PenteGameModel.swift:181-190`

## Context

In tournament Pente, Black's first move is *required* to be at the center of the board (K10 on 19×19). This is a classic rule that prevents Black from overpowering White with an arbitrary opening. In an iMessage extension, forcing the starter to tap the center, then tap Send, then wait for an opponent response feels unnecessarily ritualistic — the center move is always the same, so why make the user perform it?

## Decision

`PenteGameModel.startNewGame(blackPlayerID:)` auto-places a Black stone at `(GameBoard.size/2, GameBoard.size/2)` as a committed move in `moveHistory`, switches `currentPlayer` to `.white`, and sets `isNewGamePendingSend = true`. The starter sees a board with the center stone already placed and a single "Send" button.

## Alternatives considered

- **Require the starter to tap the center manually.** Rejected: pointless ritual; the move is forced.
- **Auto-place and auto-send without user confirmation.** Rejected: Apple's extension lifecycle and the in-extension dismissal flow both need a user gesture to trigger a send.
- **Randomize first move.** Rejected: violates the tournament rule and makes the game unfamiliar to players coming from pente.org.
- **Let the starter choose any opening.** Rejected: creates first-mover imbalance; canonical rule exists for a reason.

## Consequences

- The first `MSMessage` in a game always encodes a one-move history: `moves=B9,9;current=White;...`.
- The roadmap has no item reversing this; it's stable.
- This means the "first move" a human actually makes in a game is White's. Tutorial copy (FEATURE_ROADMAP v1.4 item 7) should account for this — "tap anywhere to place your stone" is correct regardless of whether the user is Black (responding from opening) or White (making actual first move).
- Swapping to "tournament rules" proper (restricting Black's second move to avoid forced wins) would be a rule-engine change; not currently planned.
