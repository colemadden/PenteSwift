# 0033 — Hybrid stone-placement animation: Canvas for static stones, overlay for the animating one

- **Status**: Accepted (code landed 2026-07-16)
- **Date**: 2026-04-28
- **Version**: v1.4
- **Source**: FEATURE_ROADMAP §v1.4 item 13; gomoku UX walkthrough 2026-04-28

## Context

ADR-0008 chose SwiftUI `Canvas` for board rendering — fast, scales to 19×19. Canvas is imperative and does not natively animate individual primitives. The walkthrough wants a scale-in animation when a stone is placed (yours or opponent's), and the same animation replayed once when opening a thumbnail mid-game so the just-arrived move is visually obvious. Switching the entire board to per-stone SwiftUI views is a perf regression; doing nothing fails the polish goal.

## Decision

Hybrid: `Canvas` continues to render all *committed* stones (including the green-ringed last-committed move). One SwiftUI `Circle` overlay layers on top of the Canvas for the single *animating* stone. Scale-in runs ~150ms with ease-out (0.3 → 1.0). On animation completion, the overlay is removed; the Canvas's render of that same stone takes over visually with no perceptible seam.

The overlay drives:

- **Your placement**: stone scales in on tap, before send.
- **Your undo**: stone scales out on tap-outside (ADR-0030).
- **Opponent's move arrival**: stone scales in when the new game state lands.
- **Open-from-thumbnail**: stone scales in once on first appearance, highlighting the just-arrived move.

No fly-from-bowl, no dust particles.

## Alternatives considered

- **Per-stone SwiftUI views for the entire board.** Rejected: 361 views vs 1 Canvas; perf and battery regression on a feature already chosen in ADR-0008.
- **Canvas redraw with a timer for animation.** Rejected: more code, less SwiftUI-idiomatic, harder to coordinate with overlay timing.
- **No animation, only haptic.** Rejected: scale-in is the cheapest path that delivers the visual confirmation the user wanted.

## Consequences

- Adds one SwiftUI overlay view alongside Canvas. ~30–50 LOC.
- Animation curve and duration are codified here; future tweaks should update this ADR.
- The overlay must align pixel-perfect with the Canvas-rendered stone position — share the cell-coordinate calc.
- "Replay on open" needs a way to detect "first appearance of this game state" — a `@State` flag set on first `onAppear` with a non-empty new last-move suffices.
