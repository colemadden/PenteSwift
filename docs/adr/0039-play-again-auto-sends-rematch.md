# 0039 — "Play Again" auto-sends the rematch message

- **Status**: Accepted
- **Date**: 2026-07-16
- **Version**: v1.4
- **Source**: ADR-0032 follow-on; FEATURE_ROADMAP §v1.4 item 9

## Context

ADR-0032's win overlay has a "Play Again" pill that "wires to the rematch flow."
The old "New Game" button reset locally into the pending-send state, requiring a
second tap on Send — and never notified the opponent if the user backed out.
Roadmap item 9 specifies rematch "creates and sends a new MSMessage with fresh
game state," and the one-tap-send philosophy (ADR-0029) says don't add taps
between intent and delivery.

## Decision

"Play Again" calls `newGameAction` (controller wires `blackPlayerID` from the
local participant and creates a fresh `MSSession`) and then `sendFirstMove()`,
dispatching the rematch message immediately through the ADR-0029 send ladder.
The tapper becomes black with the center-seeded opening (ADR-0025); the opponent
moves first as white.

## Alternatives considered

- **Land in the pending-send state (old New Game flow), user taps Send.**
  Rejected: an extra tap with nothing to decide in between — the seeded opening
  is fixed, so there is no "move to make" before sending.
- **Dedicated "rematch invitation" state the opponent accepts.** Rejected: new
  wire-format state and UI for a handshake the message itself already performs;
  the opponent "accepts" by making a move, exactly like any new game.

## Consequences

- Two players tapping Play Again near-simultaneously each start a game; the last
  message in the thread wins attention. Same race the old New Game flow had.
- The overlay and the bottom slot's Play Again share one button implementation.
- "New Game" no longer appears in the win state; the xcstrings key remains for
  any future use.
