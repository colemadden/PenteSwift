# 0005 — Encode game state into `MSMessage.url` query params

- **Status**: Accepted
- **Date**: 2025-06-29
- **Version**: v1.0
- **Source**: `PenteCore/Sources/PenteCore/GameStateEncoder.swift`; `pente-project-summary.md:19-21,215-229`

## Context

Two iOS clients need to share game state. Options: (a) run a backend that stores game state keyed by ID, (b) use iCloud/CloudKit, (c) encode state directly into the message. MSMessage supports a `url: URL?` field that rides with the message — Apple's intended use for per-message payloads on interactive extensions. A move list for a 19×19 Pente game is small enough to fit in a URL query string even if every intersection had a stone.

## Decision

Serialize full game state into `MSMessage.url` as URL query parameters. Schema (see `GameStateEncoder.swift` and ARCHITECTURE.md §6.2):

- `moves` — ordered move history as `[BW]<row>,<col>;` repeated.
- `current` — whose turn it is (`"Black"`/`"White"`, matching `Player.rawValue`).
- `capB`, `capW` — pair-capture counts.
- `state` — `"playing"` or `"won"`.
- `winner`, `method` — present only if `state=won`.
- `blackID` — UUID of the player who started the game (player-assignment anchor).

Only the query string matters to the decoder. `MessagesViewController.createMessage()` builds `URLComponents()` with query items and no scheme/host. Tests fabricate full `pente://game?...` URLs purely for ergonomic reasons; the production path is query-only. Scheme is not part of the contract.

## Alternatives considered

- **CloudKit game container keyed by session ID.** Rejected: violates G4 (zero infra), requires Apple Developer entitlements and availability in all user regions (including mainland China).
- **Custom backend.** Rejected: cost, ops burden, crosses privacy line declared in PRIVACY.md.
- **Base64-blob in `MSMessage.url`.** Rejected: opaque to the receiver, harder to evolve.
- **MSMessage.url + `MSMessage.liveLayout` for rich content.** Not needed at current scope.

## Consequences

- The URL query string is a wire format. **Every field here is frozen.** Renaming `capB` or changing the move separator breaks every in-flight game when a user upgrades. Additions are fine if decoders gracefully ignore unknown keys — they do.
- `Player.rawValue` ("Black"/"White") is wire format and must never be localized (ADR-0022).
- No privacy surface beyond what the OS already does with iMessage.
- Apple enforces an MSMessage payload ceiling (exact value undocumented and has varied across iOS versions); in practice a full 19×19 game is ~1 KB and we've never approached it. No fallback if a future game variant or addition pushes us near the ceiling.
- Because the decoder **replays moves and recomputes captures** (ADR-0027), the capture engine's rules are part of the wire contract too. Changing rules mid-version breaks resumes.
