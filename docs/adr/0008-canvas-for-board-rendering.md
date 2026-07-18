# 0008 — SwiftUI `Canvas` for board rendering

- **Status**: Accepted
- **Date**: 2025-06-29
- **Version**: v1.0
- **Source**: `Pente MessagesExtension/PenteGameView.swift:168-346`

## Context

The board draws up to ~360 stones plus 19×19 grid lines plus capture highlights plus last-move and pending-move rings. Two reasonable SwiftUI approaches:

1. One view per stone (`ZStack { ForEach(moves) { StoneView(...) } }`).
2. A single `Canvas` view that draws everything imperatively.

Per-stone views make individual-stone animation trivially easy. Canvas is faster, draws with `CGContext`-like primitives, and lets us compute all positions from a single `cellSize`.

## Decision

Use a single `Canvas` in `PenteBoardView`. All grid lines, stones, shadows, rings (pending blue, last-move green), and capture highlights are drawn inside one `Canvas { context, size in ... }` block. Tap handling uses the parent `.onTapGesture` with manual cell-index math.

## Alternatives considered

- **One SwiftUI view per stone.** Rejected at build time: more boilerplate, higher overhead on rerender. Noted in FEATURE_ROADMAP v1.4 item 13 as a revisit option if stone-placement animation is added.
- **UIKit `UIView` subclass hosted via `UIViewRepresentable`.** Rejected: unnecessary bridge; SwiftUI Canvas is sufficient.

## Consequences

- Individual-stone animation (scale-in, fade-in, capture-removal animation) is hard — Canvas has no retained-layer hooks. Adding it requires either switching to per-stone views or timer-based Canvas redraw. FEATURE_ROADMAP v1.4 item 13.
- Pinch-to-zoom (FEATURE_ROADMAP v1.4 item 4a) requires adjusting tap hit-testing for Canvas's transform — some nontrivial math.
- Accessibility: Canvas-drawn stones are invisible to VoiceOver. This is real a11y debt (ARCHITECTURE.md §10.4).
- Rendering is fast enough that no caching is needed at current scope.
