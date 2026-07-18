# 0031 — Bottom status area collapses to one slot: hint text or Send button

- **Status**: Accepted (code landed 2026-07-16)
- **Date**: 2026-04-28
- **Version**: v1.4
- **Source**: gomoku UX walkthrough 2026-04-28

## Context

The bottom of the screen currently hosts multiple controls (status text, Undo, Send) and switches layout based on game state. ADR-0018 documents a hidden ZStack sizing reference that exists *because* this area changes height across states and the board would otherwise resize. Gomoku's bottom area has a single slot with two states: low-opacity hint text "Place a stone on an empty tile." when no pending move, or a Send button when one exists. Simpler, and removes a class of layout instability.

## Decision

The bottom status area renders one slot with two mutually exclusive contents:

- **No pending move**: low-opacity grey hint text. New xcstrings key, en + zh-Hans.
- **Pending move**: primary Send button (gold variant on the winning move).

Both states have the same vertical footprint, so the board does not resize between them. ADR-0018's hidden sizing reference is either kept as load-bearing for the single-slot height or replaced with a fixed-height container during implementation — pick whichever is shorter.

## Alternatives considered

- **Keep multiple controls and animate transitions.** Rejected: more LOC, more states, more sizing edge cases.
- **Move the Send button into the top chrome.** Rejected: violates user expectation set by GamePigeon and competing apps.

## Consequences

- New xcstrings entry for the hint text. Localize en + zh-Hans.
- The existing Undo control is removed (per ADR-0030).
- "Your turn / Opponent's turn" status copy must move elsewhere or be subsumed. Open question for implementation: does the user need a "your turn" indicator at all when the green ring on the opponent's last move already implies it?
- Win-state replaces the slot with the win overlay's "Play Again" button (ADR-0032), so hint/Send are hidden during win.
