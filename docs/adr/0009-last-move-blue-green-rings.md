# 0009 — Blue ring for pending, green ring for last committed move

- **Status**: Accepted
- **Date**: 2026-04-07
- **Version**: v1.3
- **Source**: commit `a292b98` "Add last move indicator with blue/green rings (GamePigeon Gomoku style)"; `PenteGameView.swift:298-329`; `BoardImageGenerator.swift:109-129`

## Context

On a 19×19 board it's hard to find the opponent's last move, especially after reopening a game. The user's explicit rule: "check how GamePigeon's Gomoku does it first." GamePigeon Gomoku uses a solid blue ring for the pending stone and a solid green ring for the most recently committed stone. Those two colors are distinct and readable in both light and dark mode.

## Decision

- **Pending stone** (placed but not yet sent): solid blue ring, lineWidth 2.
- **Last committed move** (most recent `moveHistory.last`): solid green ring, lineWidth 2, using `Color(.systemGreen)` live and `UIColor.systemGreen` in the thumbnail (ADR-0013 explains why).
- The thumbnail in the iMessage bubble shows the same green ring so the live-view→thumbnail handoff is visually continuous.

## Alternatives considered

- **Dot instead of ring.** Rejected: a filled dot inside the stone clashes with the stone color; rings are cleaner.
- **Pulsing animation.** Rejected: too busy; adds animation complexity inside Canvas (ADR-0008).
- **Color per-player (e.g. orange for Black's last move, cyan for White's).** Rejected: the player making the observation already knows whose stone is whose; what they care about is "which stone is new."

## Consequences

- The thumbnail renderer guards on `board[lastMove.row][lastMove.col] != nil` before drawing the ring. This protects against a board/history mismatch or a malformed load where `moveHistory.last` points at an intersection that ended up empty (captures remove the *opponent's* stones, not the placing stone, so this should never happen in well-formed state — but the guard is cheap defense).
- Blue and green must never be drawn at the same intersection simultaneously (a brief race is what motivated ADR-0017).
- Colorblind accessibility: not validated. Green + blue is a reasonable pairing for most forms of deuteranopia/protanopia but not perfect.
