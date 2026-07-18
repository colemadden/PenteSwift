# 0044 — Device-test feedback: gold Send for both win conditions, red capture-preview rings, tutorial copy drops Gomoku comparison

- **Status**: Accepted
- **Date**: 2026-07-18
- **Version**: v1.4
- **Source**: Cole's device-test feedback 2026-07-18 (first v1.4 build on phones)

## Context

First on-device playthrough of v1.4. Three findings: (1) the gold Send button
fired only for five-in-a-row (via `winningLine`), not for a move completing the
fifth capture pair — inconsistent "this move wins" signal; (2) pending captures
had no visible telegraph — the orange dots from the original implementation
were drawn *beneath* the stones and therefore invisible (latent rendering bug);
(3) the tutorial's "Unlike Gomoku…" phrasing compares to a game the rule can
stand without.

## Decision

1. **`pendingMoveWins`** on the model: true when a pending move completes
   five-in-a-row OR the fifth capture pair. The Send button goes gold on
   `pendingMoveWins`, not `winningLine != nil`.
2. **Red capture-preview rings**: while a move is pending, the stones it would
   capture get a solid red ring (same stroke style as the blue/green rings).
   Replaces the invisible orange dots. Priority over the green last-move ring
   when they collide. Continuity with ADR-0042: red ring ("about to go") →
   red dot after confirm ("gone").
3. **Tutorial rule 2** reworded to describe the sandwich mechanic without the
   Gomoku comparison (en + zh-Hans; zh still uses ADR-0028's 夹吃).

Also considered and explicitly kept: the dimmed backdrop behind the tutorial
card (Cole flagged, then reversed — card floats confusingly without it).

## Alternatives considered

- **Gold ring on the capturing stone too** (mirror of ADR-0019's row ring).
  Not requested; capture-wins get the win overlay, and the gold Send already
  signals the win. Skipped.
- **Animate the preview rings (pulse).** Rejected: static ring is sufficient
  signal; animation adds LOC for polish nobody asked for.

## Consequences

- "Gold = this move wins" is now an invariant across win conditions; future
  win-condition changes must update `pendingMoveWins`.
- The green last-move ring is suppressed on a stone that is about to be
  captured — the warning outranks the history marker.
- `winningLine` retains its ADR-0019 role (gold ring on the five row stones);
  it is no longer the Send-button trigger.
