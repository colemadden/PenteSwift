# 0040 — Bottom slot keeps the turn indicator; fixed-height frame replaces the hidden sizing replica

- **Status**: Accepted
- **Supersedes**: ADR-0018
- **Date**: 2026-07-16
- **Version**: v1.4
- **Source**: user direction 2026-07-16 ("keep the your turn indicator as it is"); ADR-0031 open question; ADR-0031 implementation choice

## Context

ADR-0031 left one question open: replace the "Your turn" indicator with
GamePigeon's low-opacity hint text ("Place a stone on an empty tile."), or keep
an explicit turn indicator? It also left an implementation choice: keep
ADR-0018's hidden tallest-branch replica for height stability, or a fixed-height
container — "pick whichever is shorter."

## Decision

1. The empty-slot state keeps the existing turn indicator (stone circle +
   "Your turn" / "Waiting for opponent" + turn text) unchanged. No hint text.
2. The slot is a `Group` with `.frame(height: 60)` — a fixed-height container.
   ADR-0018's hidden replica (and its "X" xcstrings key) is removed.

## Alternatives considered

- **GamePigeon's hint text.** Deferred by user direction — the turn indicator
  carries more information (whose turn, which color) at no extra cost.
- **Keep the hidden replica.** Rejected: the fixed frame is strictly less code
  now that the slot's branches are all ≤60pt tall.

## Consequences

- Board size is decoupled from slot content by the fixed frame; no branch of the
  slot may grow beyond 60pt without revisiting this ADR.
- The hint-text xcstrings key from ADR-0031 was never added.
- FEATURE_ROADMAP item 12 (board layout stability overhaul) is substantially
  addressed by this change; anything residual moves out of v1.4.
