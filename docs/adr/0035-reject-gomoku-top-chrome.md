# 0035 — Reject gomoku-style top chrome (bowls + opponent pfp) for v1.4

- **Status**: Accepted (decision to reject the chrome is itself accepted; 2026-07-16)
- **Date**: 2026-04-28
- **Version**: v1.4
- **Source**: gomoku UX walkthrough 2026-04-28

## Context

The walkthrough described GamePigeon Gomoku's top chrome: "You" + your pfp + your stone bowl on the left; opponent's stone bowl + opponent's pfp on the right. The bowls are visually meaningful in Gomoku because stones fly *from* them on placement (fly-from-bowl animation). PFPs require a player avatar system. Pente v1.4 rejects both the fly-from-bowl animation (ADR-0033) and avatar customization (out of scope).

## Decision

Pente v1.4 does not adopt the gomoku-style top chrome. The bowls and opponent pfp are not added. Existing top-area content (whose-turn indicator, capture counts, etc.) is preserved by this ADR — refinements to it are a separate item, not in this batch.

## Alternatives considered

- **Add the bowls without the fly-from-bowl animation.** Rejected: bowls without their animation are decorative chrome that costs space without earning it. User flagged ambivalence in the walkthrough.
- **Add opponent pfp via Apple's Messages contact resolution.** Rejected: requires player-avatar plumbing, trait/permission handling, and asset work. Out of scope for v1.4.
- **Defer the entire top-chrome question to v1.5 with a redesign.** Allowed — this ADR doesn't preclude that. It just settles "not in v1.4."

## Consequences

- Current Pente top area structure is unchanged by this ADR.
- Gold pfp halo on win is therefore also out of scope (no pfp to halo).
- Visible v1.4 UX changes are: the bottom-area cleanup (ADR-0031), the win/loss overlay (ADR-0032), the placement animation (ADR-0033), the haptics (ADR-0034), the gold winning-line ring (ADR-0019), one-tap send (ADR-0029), tap-outside-undo (ADR-0030), plus pinch-to-zoom (FEATURE_ROADMAP §v1.4 item 4a, ADR pending).
