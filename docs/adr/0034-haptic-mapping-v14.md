# 0034 — Haptic mapping for placement, capture, and win

- **Status**: Superseded by ADR-0038 (opponent-arrival haptic added on device-test feedback)
- **Date**: 2026-04-28
- **Version**: v1.4
- **Source**: FEATURE_ROADMAP §v1.4 item 4b; gomoku UX walkthrough 2026-04-28

## Context

The walkthrough enumerated several possible haptic moments. Some are redundant: an "opponent move arrives" haptic duplicates iMessage's own arrival haptic. A "Send-button-appears" haptic duplicates the place haptic that fires at the same instant. The remaining moments — place, capture, win — are distinct game events the user benefits from feeling.

## Decision

Three haptics, mapped to standard generators:

- **Place stone**: `UIImpactFeedbackGenerator(style: .medium)` on each successful placement (yours and the opponent-arrival animation).
- **Capture**: `UINotificationFeedbackGenerator` `.warning`. Pente-specific. Distinct feel from a normal placement.
- **Win**: `UINotificationFeedbackGenerator` `.success`. Fires once on game-end on the winner's device. Loser gets the place haptic from their losing move; no separate loss haptic.

No haptic for: opponent-move-arrival (iMessage already fires one), Send-button-appears (redundant with place), undo (subtle UI gesture, haptic feels heavy).

## Alternatives considered

- **Custom Core Haptics patterns (`CHHapticEngine`, `.haptic` files).** Rejected: setup boilerplate, asset weight, and the standard generators are sufficient.
- **Haptic on opponent move arrival.** Rejected: duplicates iMessage's arrival haptic; user flagged this concern in the walkthrough.
- **Skip haptics entirely.** Rejected: free in binary size, dramatically improve perceived polish — highest signal-to-bytes feature in v1.4.

## Consequences

- Three generator instances, prepared lazily (`prepare()` before expected use). ~15 LOC total.
- No sound effects in v1.4 — keeps the binary <1 MB. Reconsider only on explicit user feedback requesting audio.
- Haptics fire on the device whose user triggered the event: placement on placer's device; capture on placer's device; win on both devices when the game ends.
