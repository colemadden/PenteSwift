# 0003 — 19×19 board size

- **Status**: Accepted
- **Date**: 2025-06-29
- **Version**: v1.0
- **Source**: `PenteCore/Sources/PenteCore/GameBoard.swift:4`

## Context

Pente has historically been played on boards of various sizes — 13×13, 15×15, and 19×19 are all attested. The 19×19 board is the traditional Go/Pente size and is what virtually every competitive Pente site (pente.org, Board Game Arena, Pente Live) uses. A smaller board would make stones easier to hit on a phone screen, but shortens capture-rich middlegames.

## Decision

Fix the board at 19×19. `GameBoard.size = 19` is a public constant exposed by PenteCore and used by both the live board renderer and the thumbnail image generator.

## Alternatives considered

- **13×13 or 15×15.** Rejected: breaks player expectations and shortens games below the point where capture strategy meaningfully plays out.
- **User-configurable board size.** Rejected: changing board size is a wire-format change (games resumed on a different-size board would break) and adds UI surface for a setting almost no user wants to touch.

## Consequences

- 19×19 on a phone means stones are ~18pt wide — mis-taps are real. FEATURE_ROADMAP v1.4 item 4a (pinch-to-zoom) addresses this.
- The URL-encoded wire format uses literal row/col integers; there's no compression. A full game rarely exceeds ~1 KB of query string, comfortably under iMessage's limits.
- `GameBoard.size` is load-bearing — every stone-position check compares against it. Changing it mid-series of versions would break decoding of historical games.
