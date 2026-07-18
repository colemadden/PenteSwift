# 0037 — Stable `gameID` UUID in URL-encoded state

- **Status**: Accepted
- **Date**: 2026-04-29
- **Version**: v1.4
- **Source**: ADR-0029 retry-guard correctness; Codex stop-time review 2026-04-29

## Context

ADR-0029 caches a failed `MSMessage` and retries it on the next `willBecomeActive`. The retry must verify that the active context matches the game the cached message was for; otherwise a transient network failure could replay a stale move into a different chat or a different Pente game in the same chat.

`MSSession` was the first candidate identity: opaque per-game token assigned at game start, embedded in every message of that game. But `MSSession` exposes no public identity beyond Swift `===`, and Apple does not document instance stability across `willBecomeActive` reads of `selectedMessage.session`. Relying on `===` would drop legitimate retries when the framework returns a fresh wrapper for the same logical session.

## Decision

Add a `gameID: UUID` field to PenteCore's URL-encoded game state, transmitted as the `gid` query parameter. Generated in `startNewGame`, propagated unchanged through every subsequent message, and decoded back on resume. Retry-guard logic compares the cached message's decoded `gameID` against the just-loaded `gameModel.gameID` — UUID equality is stable and self-contained, no framework-identity assumptions.

## Alternatives considered

- **`MSSession` `===` identity.** Rejected: undocumented stability, brittle.
- **Heuristic `(blackPlayerID, moveHistory prefix)` matching.** Rejected: fragile; two games in the same chat with the same starter share `blackPlayerID`, and move-history prefix matching is order-dependent.
- **Compare full URL strings.** Rejected: includes turn-state and move count, not stable across retries.
- **Add a per-message UUID instead of per-game.** Rejected: solves a different problem (message identity), not game identity.

## Consequences

- `GameStateEncoder` writes `gid=<uuid>` when `gameID` is set; `GameStateDecoder` reads it into `DecodedGameState.gameID`.
- `PenteGameModel.gameID` is set on `startNewGame`, populated from URL on `loadFromURL`, cleared on `resetGame`.
- **Backward compatibility**: in-flight v1.3 games have no `gid` in their URLs. After the v1.4 upgrade, those games load with `gameID == nil`. The retry-guard requires *both* IDs non-nil to match, so v1.3-era games never trigger session-aware retry — they fall through to the simpler "drop on failure" path. Acceptable: the cohort is small and shrinking, and the regression is "no retry," not "wrong retry."
- Wire format gains one query item. Compatible with any v1.3 client because unknown query items are silently ignored by the existing decoder.
- `DecodedGameState.init` gains a trailing `gameID: UUID? = nil` parameter — additive, default-nil, no positional callers break.
