# 0042 — Capture indication on resume derives from decoder replay, not wire encoding

- **Status**: Accepted
- **Date**: 2026-07-16
- **Version**: v1.4
- **Source**: FEATURE_ROADMAP §v1.4 item 8; tester report (Mehera) — stones vanished silently after opponent's capture

## Context

A player resuming a game where the opponent just captured sees stones missing
with no explanation. The roadmap sketched encoding last-capture positions into
the URL (`&lc=5,6;5,7`). But the decoder already replays every move and
recomputes captures authoritatively (ADR-0027) — the last replayed move's
capture list IS the information we want.

## Decision

`DecodedGameState` gains `lastCaptures: [(row, col)]`, assigned during replay
(each iteration overwrites it; the loop ends holding the final move's
captures). `PenteGameModel.loadFromURL` copies it into the model's existing
`lastCaptures`, which the Canvas already renders as red translucent circles.
No wire-format change.

Additionally, `confirmMove` now sets `lastCaptures = capturesToApply` after
applying removals — previously it cleared the field and never repopulated it,
so capture sites vanished instantly on the sender's board too.

## Alternatives considered

- **Encode `&lc=` in the URL** (roadmap sketch). Rejected: redundant with the
  replay, grows every message, and can desync from the board if either side has
  a decode quirk. Replay-derived data is consistent by construction.
- **Animate the capture on resume.** Rejected per roadmap note: a static "these
  stones were just removed" indicator is sufficient; no bundle-size or LOC cost.

## Consequences

- Works retroactively for in-flight v1.3-era games — their URLs replay the same.
- The indicator persists until the player places their next tentative stone
  (makeMove overwrites `lastCaptures` with the new pending captures) — same
  lifecycle as the live-play indicator.
- `DecodedGameState.lastCaptures` is not an init parameter (defaulted `[]`,
  assigned during replay), so existing initializer call sites are unaffected.
