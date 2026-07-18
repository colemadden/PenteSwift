# 0002 — Two-step move (tentative place, then confirm/undo)

- **Status**: Accepted
- **Date**: 2025-06-29 (initial implementation)
- **Version**: v1.0
- **Source**: `Pente MessagesExtension/PenteGameModel.swift:49-125`; `PenteGameView.swift:73-107`

## Context

In a game played by async messaging, a misclick is expensive: it sends a move to the opponent that cannot be recalled. Users expect either a confirmation step or a "preview this move before sending" affordance. GamePigeon's Gomoku uses a place-then-send flow. The capture mechanic in Pente compounds the problem — a single placement can remove up to 8 opponent stones, and the player genuinely wants to preview which captures will happen before committing.

## Decision

Tapping an intersection places the stone *tentatively*. The UI shows:

- A blue ring around the pending stone.
- Orange-tinted empty circles at every intersection whose stone would be captured.
- An Undo/Send button pair instead of a turn indicator.

"Send" calls `confirmMove()`, which clears pending state (ADR-0017), appends to `moveHistory`, applies captures, checks win conditions, switches turns if the game continues, updates move permissions, and fires `moveDelegate.gameDidMakeMove()` (which in turn calls `MessagesViewController.sendMessage()`). "Undo" calls `undoMove()` and removes the tentative stone.

Tapping the same intersection while a pending move exists acts as Undo. Tapping a different intersection replaces the pending move.

## Alternatives considered

- **One-tap commit.** Rejected: misclick cost too high on a 19×19 grid, especially on smaller screens.
- **Long-press to commit.** Rejected: less discoverable than an explicit button; fights with other gesture recognizers.
- **Separate "preview captures" toggle.** Rejected: mode switch is confusing; captures should always be visible pre-commit.

## Consequences

- Two controls (Undo, Send) must fit in the bottom cluster, which is why the layout-stability ZStack exists (ADR-0018).
- The "pending" state adds invariants the model must maintain — see ADR-0017 for the specific ordering constraint in `confirmMove()`.
- A small number of users may expect instant commit; there is no opt-out. FEATURE_ROADMAP v1.4 item 5 proposes a one-tap-send variant that still previews captures first.
