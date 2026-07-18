# 0029 — Switch in-app Send to `MSConversation.send` (one-tap send)

- **Status**: Accepted
- **Supersedes**: ADR-0024 (effective on acceptance)
- **Date**: 2026-04-28
- **Version**: v1.4
- **Source**: FEATURE_ROADMAP §v1.4 item 5; gomoku UX walkthrough 2026-04-28

## Context

ADR-0024 documented the status quo: `conversation.insert(message)` followed by `dismiss()`, requiring a second tap on the iMessage compose Send arrow. The walkthrough of GamePigeon Gomoku confirmed it sends in a single tap. The second tap costs us mid-game momentum and looks unpolished next to the reference. ADR-0024 explicitly anticipated this supersede.

## Decision

Use `conversation.send(message)` from the in-app Send button. No second tap. No fallback to `insert` for an "edit before sending" path — that affordance has never been requested.

## Alternatives considered

- **Conditional `send` in expanded, `insert` in compact** (ADR-0024's hedge). Rejected: the extension is in expanded presentation when the in-app Send button is tapped; compact-mode send is not a real path.
- **Long-press for "send with caption" via `insert`.** Rejected: speculative future-proofing for a use case nobody asks for.

## Consequences

- The in-app Send commits the move and posts the message immediately; the extension stays open in expanded view.
- No "Sent ✓ / Waiting…" overlay — the blue ring on the just-sent stone clearing is sufficient confirmation. Sidelined per FEATURE_ROADMAP update.
- Verify on physical device: `send(_:)` historically had presentation-style preconditions that `insert` did not.
- **Failure handling — three-tier ladder**: `confirmMove` updates local state *before* the message is dispatched, so any silent dispatch failure would let the local game advance while the opponent never sees the move. The dispatch path therefore has three tiers:
  1. `conversation.send(message)` — happy path, one-tap delivery, extension stays expanded.
  2. On failure, fall back to `conversation.insert(message)` — message lands in the compose bar, user can tap iMessage Send to recover. ADR-0024's flow as a recovery path.
  3. On `insert` failure too, cache `(message, gameID)` in `pendingFailedMessage` (ADR-0037). On every subsequent `willBecomeActive`, re-dispatch only if `gameModel.gameID == cached.gameID`. UUID equality is stable across framework reads (unlike `MSSession ===`), and per-game uniqueness means a match implies same chat *and* same game — a cached move cannot be replayed into a different chat or into a different Pente game in the same chat. **On mismatch the cache is preserved**, not cleared, so a user who opens a different Pente game (or a fresh chat) in the interim does not silently lose the failed move from the original game; the cache waits in memory and retries the next time they return to the matching game.
- **Cache lifecycle**: the cache is dropped only by (a) a successful `send` for the same `MSMessage` instance, (b) a successful `insert` for the same instance (the message lands in the compose bar and the user can recover manually), or (c) extension process termination. Identity is checked with `MSMessage ===` so an unrelated successful dispatch in another game does not clear a different game's pending retry.
- **Local state realignment on retry**: between failure and retry, `willBecomeActive` reloads the model from `selectedMessage` — which is the opponent's last-seen position, *before* the user's failed move. Without further action the UI would show a board missing the user's own move while we redeliver it in the background, and a re-tap could produce a duplicate. Before the retry dispatch, we therefore reload the model from the cached message's URL so the local view matches the state we are about to send. The reapply uses `loadFromURL` followed by `assignPlayerRole`, mirroring the normal load path. If the retry then fails again, the local state still reflects the user's move and the cache is preserved for a future retry — the only loss is that the opponent has not yet seen it.
- **Known limitation — first-move-of-new-game failure**: if the first message of a brand-new game fails both `send` and `insert`, no message ever lands in the thread. On reopen, `selectedMessage` is `nil`, the extension takes the new-game branch, and a fresh `gameID` is generated. The cached `gameID` won't match → cache is dropped and the first move is lost. Acceptable rare edge case — the user simply starts the game again.
- **v1.3-era games**: in-flight games started before v1.4 have no `gid` in their URL. After upgrade their `gameID` decodes as `nil`, and the retry guard requires both IDs non-nil to match — so v1.3-era games never trigger session-aware retry, falling back to the simpler "drop on dispatch failure" path. The cohort is small and shrinking; acceptable.
- The cached message survives extension backgrounding within a Messages session but not a full process termination — acceptable given the rarity of double-failure plus process kill.
