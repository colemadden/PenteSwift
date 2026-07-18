# 0001 — iMessage extension as primary form factor

- **Status**: Accepted
- **Date**: 2025-06-29 (initial commit)
- **Version**: v1.0
- **Source**: `pente-project-summary.md:5-6,19-21`; initial commit `f2775af`

## Context

The developer wanted a turn-based Pente game that friends could play together without the friction of installing a dedicated multiplayer app, creating accounts, or sharing invite codes. GamePigeon had already validated that iMessage extensions are a viable distribution channel for casual turn-based games. The alternative — a standalone iOS app with networked multiplayer — requires backend infrastructure, accounts, invites, matchmaking, and ongoing cost.

## Decision

Ship Pente as an iMessage extension. The extension *is* the product. There is a host app target, but it's a placeholder — its only job is to exist so the extension can be distributed.

## Alternatives considered

- **Standalone iOS app + Game Center.** Rejected: high friction, requires accounts, Game Center matchmaking is unreliable and deprecated in practice.
- **Standalone app with custom backend.** Rejected: cost, maintenance, undermines the "$0 infra" goal.
- **Cross-platform (Flutter / React Native).** Rejected: iMessage extensions require native iOS. There is no cross-platform framework that can produce an `MSMessagesAppViewController`.

## Consequences

- We inherit every iMessage-extension limitation: sandboxed runtime, MSMessage URL size limits, extension-lifecycle quirks, and physical-device-only testing for final validation.
- Market is capped at iMessage users. This is the single largest strategic risk — 82% of downloads come from China, where WeChat dominates and iMessage is not the primary messenger.
- Removing the iMessage dependency (standalone app + Game Center multiplayer) is the v2.0 direction. See FEATURE_ROADMAP §15.
- The PenteCore package was deliberately designed to be reusable in a future standalone or WeChat port.
