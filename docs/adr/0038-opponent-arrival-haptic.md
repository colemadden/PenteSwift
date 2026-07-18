# 0038 — Add opponent-move-arrival haptic

- **Status**: Accepted
- **Supersedes**: ADR-0034 (effective on acceptance)
- **Date**: 2026-05-03
- **Version**: v1.4
- **Source**: device test feedback 2026-05-03

## Context

ADR-0034 mapped three haptics — placement, capture, win — and explicitly excluded an opponent-move-arrival haptic on the rationale that "iMessage already fires one." On-device testing showed the iMessage arrival haptic is too subtle (and identical for any incoming message) to register that a *new stone* has appeared on the Pente board. Players need a Pente-specific tactile cue to notice the opponent's move when they're staying in the expanded extension view.

## Decision

Fire `UIImpactFeedbackGenerator(style: .medium)` — the same generator used for local placement (ADR-0034) — when a new opponent move lands and is loaded into the model. Trigger point: `MessagesViewController.didReceive`, after `loadFromURL` succeeds and `assignPlayerRole` runs, only if the loaded state actually advanced (new move count) compared to what we had locally.

Reusing the placement generator keeps the haptic library to three (place, capture, win) and gives a consistent "stone appeared" feel regardless of whose stone it is.

## Alternatives considered

- **Distinct generator for arrival** (e.g., `.light` impact). Rejected: subtler than placement, defeats the purpose of making arrivals legible.
- **Notification haptic** (`.success`/`.warning`). Rejected: those carry semantic weight (capture/win) that arrival doesn't have.
- **Haptic only when the user is the active player about to move** (post-arrival). Rejected: spectator-mode and quick back-and-forth flows still benefit from the cue.
- **Custom `CHHapticEngine` pattern.** Rejected: same reasoning as ADR-0034 — boilerplate and binary weight outweigh the benefit.

## Consequences

- The placement generator is now shared between local-placement and opponent-arrival. Same `prepare()` cadence, no extra state.
- ADR-0034's enumeration of haptic moments is amended: arrival is now *in*, not *out*. Capture and win haptics are unchanged.
- The "no haptic on send-button-appears" exclusion still stands.
- Detection of a real arrival uses `moveHistory.count` before/after `loadFromURL`. If the message decode fails or doesn't advance state, no haptic fires (avoids spurious vibration on a redundant didReceive).
