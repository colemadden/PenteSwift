# 0019 — `WinDetector` returns the winning line for gold-ring highlight

- **Status**: Accepted
- **Date**: 2026-04-28
- **Version**: v1.4
- **Source**: FEATURE_ROADMAP §v1.4 item 6; gomoku UX walkthrough 2026-04-28

## Context

When a 5-in-a-row win lands, the 5 winning stones are visually indistinguishable from the rest of the board. The user wants a gold ring around exactly those 5 (per GamePigeon Gomoku reference). To draw the ring, the renderer needs the 5 coordinates. `WinDetector` already locates the line internally to declare the win — it just doesn't surface it.

## Decision

`WinDetector` returns the 5 winning coordinates as `[Position]?` on a 5-in-a-row win, and `nil` on capture-win or no-win. `PenteGameModel` exposes this as `winningLine: [Position]?` for the view layer. Capture-win has no line and renders no gold-ring overlay.

## Alternatives considered

- **Recompute the line in the view layer.** Rejected: duplicates win-detection logic, drift risk.
- **Encode the line in the URL state.** Rejected: bloats wire format. Recomputable from `moveHistory` on resume — decoder re-runs win detection.

## Consequences

- `WinDetector` signature changes — public type. `PenteCoreTests` must assert returned coordinates for horizontal / vertical / both diagonals.
- View layer branches: if `winningLine != nil`, draw gold ring on those stones, suppressing green/blue rings on those same intersections to avoid double-ringing.
- Capture-win path is unchanged from the user's perspective.
