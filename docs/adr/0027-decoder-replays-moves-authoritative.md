# 0027 — Decoder replays moves; `capB`/`capW` in URL are informational only

- **Status**: Accepted
- **Date**: 2025-06-29 (implicit) / 2026-04-05 (formalized in PenteCore extraction)
- **Version**: v1.0 → v1.2
- **Source**: `PenteCore/Sources/PenteCore/GameStateEncoder.swift:88-116`; `PenteCore/Tests/PenteCoreTests/GameStateEncoderTests.swift`

## Context

The URL encoding includes both:

- `moves` — the ordered move history.
- `capB`, `capW` — current pair-capture counts per player.

A naive decoder would read `capB`/`capW` directly. But that trusts the sender. If a sender serializes inconsistent state, the receiver shows the wrong counts. More subtly, replaying to compute captures is the *only* way to reconstruct the board (we do not encode the board itself, just the move history).

## Decision

`GameStateDecoder.decodeFromURL` **replays every move** through `CaptureEngine.findCaptures` to rebuild the board and the per-player capture counts. The `capB`/`capW` URL fields are **not read at all** by the decoder — the encoder writes them, the decoder ignores them, and the replay is authoritative. Grep `GameStateEncoder.swift:119-136` confirms the decoder looks up only `moves`, `current`, `state`, `winner`, `method`, and `blackID`.

Move replay also applies capture removal as it goes, so the final board matches what both players see.

## Alternatives considered

- **Trust `capB`/`capW` directly.** Rejected: cheats on board reconstruction (we'd still need to replay for the board) and creates a divergence risk.
- **Drop `capB`/`capW` from the URL entirely.** Considered. They're kept because (a) they're useful for debugging and human-readable URL inspection, (b) they might be used for fast-path preview rendering elsewhere, and (c) removing them is a wire-format change. Net: keep for now, ignore on decode.

## Consequences

- **The capture rule is part of the wire contract.** Changing `CaptureEngine.findCaptures` behavior mid-series of versions would cause old games to resume with different capture state than when they were paused — a silent bug. Any rule change requires a wire-format version bump.
- `capB`/`capW` being encoded but not decoded is surprising. Must be documented — ARCHITECTURE.md §6.2 and this ADR are the record.
- Performance: replaying ~50 moves on game open is trivial; no optimization needed.
- If a future version wants to add game variants (different capture rules), the rule version would need to ride in the URL and gate the replay.
