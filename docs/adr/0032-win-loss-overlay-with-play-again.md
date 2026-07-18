# 0032 — Win/loss overlay with "Play Again" replaces inline win subcaption

- **Status**: Accepted (code landed 2026-07-16)
- **Date**: 2026-04-28
- **Version**: v1.4
- **Source**: gomoku UX walkthrough 2026-04-28; FEATURE_ROADMAP §v1.4 item 9 (rematch flow)

## Context

Today, the win state is a subcaption text in the bottom area. The walkthrough revealed Gomoku's celebration is much more pronounced: a translucent overlay across the board with "YOU WON!" or "YOU LOST!" and a centered "Play Again" pill button. The user explicitly endorsed this energy.

## Decision

On game-end, render a translucent full-board overlay:

- **Winner**: "YOU WON!" headline + centered "Play Again" pill.
- **Loser**: "YOU LOST!" headline + centered "Play Again" pill.
- **Capture-win**: same overlay; the gold-ring (ADR-0019) does not apply to capture-wins, but the overlay does.

The overlay is dismissable by tapping outside the Play Again pill, revealing the final board for inspection. "Play Again" wires to the rematch flow (separate v1.4 item, separate ADR when that lands).

The Send button on the winning move is rendered in gold instead of the primary blue, as a small extra ceremony moment. Implementation detail of ADR-0031.

## Alternatives considered

- **Keep subcaption-only win text.** Rejected: doesn't read as celebration. User explicitly wants the gomoku treatment.
- **Confetti / particle effects.** Rejected: cosmetic, adds binary weight or LOC, on the explicit skip-list.
- **Auto-trigger rematch on win without confirmation.** Rejected: user might want to inspect the final board.

## Consequences

- Three new xcstrings entries: "YOU WON!", "YOU LOST!", "Play Again". Localize en + zh-Hans.
- Win subcaption text in the bottom slot can be removed; the overlay carries the win signal.
- Overlay must be tap-dismissable so the user can review the final position.
- "Play Again" is the rematch trigger; the rematch message-flow ADR is a follow-on when that work lands.
