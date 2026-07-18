# 0046 — v1.4.1 hardening: fixes from the post-ship Codex review

- **Status**: Accepted
- **Date**: 2026-07-18
- **Version**: v1.4.1 (build 8)
- **Source**: Codex task-mode review of the v1.4 release diff (session 019f767c-bd8f), triaged 2026-07-18; none observed in human device testing — all require network-failure, multi-game, or sub-200ms timing conditions

## Context

The adversarial review of the shipped v1.4 diff surfaced seven findings. Five
were judged real (two pre-dating v1.4), one cosmetic-but-real, one overstated.
Nothing regressed v1.4 below v1.3, so the submission was left in review and the
fixes batched here.

## Decisions

1. **`loadFromURL` discards tentative state** (`pendingMove`, `pendingCaptures`,
   `isNewGamePendingSend`) before applying decoded state. Prevents a phantom
   move (stale coordinate + stale captures) being confirmed into a freshly
   loaded game, and unblocks the board when a new-game pending-send survives
   into a loaded game. Pre-existing since v1.3.
2. **`didReceive` adopts `message.session`.** Replies made after receiving a
   move for a different game in the same chat now update the correct bubble.
   Pre-existing since v1.3.
3. **Retry cache is per-game and single-flight.** `pendingFailedMessages:
   [UUID: MSMessage]` replaces the single tuple slot — a double-failure in one
   game can no longer evict another game's cached move (honoring what ADR-0029
   promised). The matching entry is removed *before* dispatch, so racing
   activations cannot double-send; a repeat double-failure re-caches.
   `clearCacheIfHolds` filters by `===` across all entries, defusing stale
   failure closures re-caching an already-delivered message.
4. **Animation completion is identity-guarded.** The delayed clear only nils
   `animatingStone` if it still holds the animation that scheduled it — an old
   timer can't clip a newer animation. Known micro-edge: same-position,
   same-direction animations within 180ms share identity; accepted.
5. **Zoom/pan reset on `gameID` change.** `gameID` became `@Published`; the
   board view resets viewport state via `onChange`. Corrects ADR-0041's wrong
   assumption that view state resets per activation (the hosting controller
   persists).

## Explicitly not fixed

- **Cross-conversation retry via forwarded bubble** (review finding 3):
  requires forwarding an interactive MSMessage bubble into another chat, which
  iMessage does not offer for app messages. Documented as accepted risk;
  revisit only if a real reproduction surfaces.

## Consequences

- ADR-0029's cache-lifecycle description is amended by decision 3 (per-game
  slots, take-before-dispatch); its guarantees now actually hold.
- ADR-0041's "resets each open" claim is corrected by decision 5.
- Two new model tests (tentative-state discard, pending-send clear) and one
  controller test (session adoption) pin the fixes.
