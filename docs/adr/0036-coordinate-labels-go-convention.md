# 0036 — Coordinate labels follow Go/Pente convention (A–T skipping I, rows 19→1)

- **Status**: Rejected on device review (2026-05-03). Labels rendered correctly per the convention chosen here, but visually crowded the 19×19 board on iPhone. Roadmap item #14 dropped from v1.4. Code removed; ADR retained as the record of the convention to use *if* labels are revisited (any future attempt should mock up visuals before committing).
- **Date**: 2026-04-29
- **Version**: v1.4
- **Source**: FEATURE_ROADMAP §v1.4 item 14

## Context

Item 14 calls for column/row labels on the board edges. The roadmap loosely says "A–S" + "1–19" but a 19×19 board needs 19 column labels. Two viable conventions:

- **Go/Pente standard (used by pente.org, online Pente clients, Go boards everywhere)**: columns `A B C D E F G H J K L M N O P Q R S T` (19 letters; skip `I` because it visually conflates with `1`), rows numbered `1` at the bottom up to `19` at the top.
- **Naive A–S alphabetic + 1–19 top-to-bottom**: matches array indexing but is not how Pente players read coordinates.

## Decision

Use Go/Pente convention: columns `A`–`T` skipping `I`, rows `19` at the top down to `1` at the bottom. Labels render on the top and left edges only (saves LOC; right/bottom are redundant on a phone screen). Labels render inside the existing `halfCell` margin between Canvas edge and the outer grid line — no change to play-area `cellSize` or tap hit-test math.

## Alternatives considered

- **A–S without skipping I.** Rejected: not how the game is notated; would confuse anyone discussing moves with a Pente player.
- **Rows numbered top-to-bottom (1 at top).** Rejected: contradicts the universal Go/Pente convention; competitive players read `1` as the bottom row.
- **Labels on all four edges.** Rejected: more LOC, no readability gain on a phone.
- **Labels outside the Canvas as SwiftUI `Text` overlays.** Rejected: would require GeometryReader math duplication; in-Canvas `context.draw(Text…)` is shorter.

## Consequences

- Labels are drawn in the existing half-cell margin; no `cellSize` recompute, no tap hit-test changes.
- Label color reuses `gridLineColor` for theme adaptivity.
- Coordinate convention is now load-bearing: any future feature that names a square (move history viewer item 10, AI opponent item 16) must use Go convention.
