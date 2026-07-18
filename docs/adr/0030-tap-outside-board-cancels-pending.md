# 0030 — Tap outside the board cancels the pending stone

- **Status**: Accepted (code landed 2026-07-16)
- **Date**: 2026-04-28
- **Version**: v1.4
- **Source**: gomoku UX walkthrough 2026-04-28

## Context

Today, undoing a tentative placement requires tapping a separate Undo control. GamePigeon Gomoku has no Undo button — tapping anywhere outside the board bounds cancels the pending stone. This frees screen real estate, simplifies the bottom status area (ADR-0031), and is a more intuitive "deselect" gesture.

## Decision

When `pendingMove != nil`, a tap landing outside the board bounds clears `pendingMove` and any pending captures, reverting the bottom status area from "Send" to the hint text. The stone scale-out animates back out (mirror of the place animation per ADR-0033). The existing explicit Undo control is removed.

## Alternatives considered

- **Keep the explicit Undo button alongside the gesture.** Rejected: redundant once the gesture exists; clutters the bottom area.
- **Tap on the placed stone itself to undo.** Rejected: ambiguous — taps on occupied intersections currently no-op, and double-purposing them risks accidental cancels.

## Consequences

- Hit-test region for "outside the board" = everything inside the extension view that is not the drawn board bounds (top chrome + bottom status area + side margins).
- Empty-board state has no pending stone, so the gesture is a no-op there.
- Interaction with pinch-to-zoom (v1.4 item 4a): "outside the board" refers to logical board bounds, not viewport bounds. Coordinate with the zoom transform when that lands.
- Removes the bottom-area Undo control. The status area collapses to two states (hint text, Send button) — see ADR-0031.
