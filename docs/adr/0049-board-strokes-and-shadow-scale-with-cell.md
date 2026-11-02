# 0049 — Board ring/border widths and stone shadow offset scale with cell size

- **Status**: Accepted
- **Date**: 2026-11-02
- **Version**: next release after v1.5
- **Source**: owner report 2026-11-02 (screenshots: green ring ~85% of the stone in the compact drawer; shadows "move" while dragging the drawer); `PenteGameView.swift` `PenteBoardView` Canvas

## Context

Every board measurement in the Canvas derives from `cellSize` (stone = 0.7 cell,
capture marker = 0.4 cell) except the stroke widths and shadow offset, which were
fixed points: rings 2pt (gold win ring 2.5pt), white-stone border 0.5pt, shadow
offset +2pt. In the expanded sheet on a 6.9" phone a cell is ~22pt, so these look
right. In the compact drawer the board is ~89pt and a cell ~4.7pt (stone ~3.3pt),
so a 2pt ring swallows the stone and a 2pt shadow sits visibly off to the side —
and because the board resizes continuously while the drawer is dragged, the
shadow appears to slide.

## Decision

Derive one width, `ring = cellSize * 0.09`, and use it for the red / green / blue
rings, `ring * 1.25` for the gold winning ring, `ring / 4` for the white-stone
border, and `ring` for the shadow's x/y offset. At a ~22pt cell this reproduces
the old 2 / 2.5 / 0.5 / 2pt values.

## Alternatives considered

- **Clamp the old fixed widths to a fraction of the stone.** Rejected: more code
  (`min`/`max` per call site) for the same visual result.
- **Hide rings/shadows below some board size.** Rejected: loses the last-move cue
  in the compact drawer, which is where the "your turn" glance happens.

## Consequences

- Grid lines stay at a fixed 0.5pt (hairlines should not thicken on large boards).
- `BoardImageGenerator` (message-bubble thumbnail, ADR-0009) draws at a fixed size
  and is unaffected.
- Any new stroke or offset drawn in the board Canvas should be expressed in terms
  of `ring` / `cellSize`, not points.
- No unit test: the values live inside the Canvas closure and are only observable
  as pixels. Verified in the simulator (compact + expanded, iPhone 18 Pro Max);
  full suite 278/278 green.
