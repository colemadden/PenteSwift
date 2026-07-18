# 0020 — No CloudKit, no backend service

- **Status**: Accepted
- **Date**: 2025-06-29
- **Version**: v1.0
- **Source**: `PRIVACY.md`; `pente-project-summary.md:25-29`

## Context

Multiplayer games typically require some shared state. Options for sharing game state between two iPhones: (a) a developer-owned backend, (b) CloudKit public database, (c) piggyback on iMessage's transport.

(c) is free, zero-ops, privacy-preserving, and matches the async turn-based nature of the game.

## Decision

No backend. No CloudKit. No network calls from the app at all. All game state lives in `MSMessage.url` query params (ADR-0005). The message thread is the single source of truth.

## Alternatives considered

- **Custom backend (e.g. Firebase, custom REST).** Rejected: cost, ops burden, privacy surface, requires user auth.
- **CloudKit public DB keyed by game ID.** Rejected: requires Apple Developer entitlements, adds complexity, availability varies by region (notably mainland China), and crosses the privacy line declared in PRIVACY.md.
- **Peer-to-peer via MultipeerConnectivity.** Rejected: only works when players are physically co-located.

## Consequences

- Privacy: no data goes to developer-run or third-party servers. Game state (including the starter's `localParticipantIdentifier` UUID as `blackID`, and all move coordinates) IS transmitted between participants through Apple's Messages pipeline, as it must be for a multiplayer game. PRIVACY.md is precise about this distinction — no *developer-side* collection, which is what "we don't collect anything" means in that document.
- Operational: nothing to break, scale, patch, or pay for.
- Resume fidelity: if a user loses or archives the message thread, the game is gone. There is no "my games" list.
- Rematch and move-history-review features must either live entirely in the message thread (limited state) or introduce the very infrastructure this ADR rules out.
