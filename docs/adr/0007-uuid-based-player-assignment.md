# 0007 — UUID-based `blackPlayerID` for player color assignment

- **Status**: Accepted
- **Date**: 2025-12-16
- **Version**: v1.1
- **Source**: commit `ec3b909` "Fix critical player assignment and turn-based gameplay bugs"; `MessagesViewController.swift:50-60`; `GameStateEncoder.swift:40-42,135-136`

## Context

Pre-fix behavior: the extension had no concept of "which participant is which color." Any participant could tap the board and submit a move for either side. A player could hijack the opponent's turn. A 1-star App Store review surfaced this.

`MSConversation.localParticipantIdentifier` is a per-conversation, per-app-install opaque UUID that Apple provides. It's stable for a given (user, app, conversation) triple. It can be compared across messages to determine "this is the same local user."

## Decision

The first player to create a new game in a conversation is Black. Their `localParticipantIdentifier.uuidString` is written to the `blackID` query parameter on the first sent message. Every subsequent receiver compares their local UUID to the loaded `blackID`:

- Equal → `.black`.
- Not equal → `.white`.

`PenteGameModel.canMakeMove` is derived as `currentPlayer == assignedPlayerColor`. `makeMove()` guards on this flag.

## Alternatives considered

- **Color by message order (first-mover is Black).** Rejected: doesn't survive the receiver opening multiple games, and didn't actually solve the hijack bug.
- **Explicit "I'm playing Black" / "I'm playing White" setup screen.** Rejected: extra UX, and the `localParticipantIdentifier` already gives us what we need.
- **Store color in `UserDefaults`.** Rejected: tied to device, not conversation — breaks on cross-device play.

## Consequences

- Color assignment is anchored to the *starter* of the game. There is no "swap colors for rematch" mechanism yet (rematch itself isn't implemented — FEATURE_ROADMAP v1.4 item 9).
- `blackID` is a frozen wire-format field.
- Edge case: if `blackID` is ever missing on load (should never happen in production — only possible on malformed or pre-v1.1 state), the model falls back to "no assignment → all moves allowed." See ADR-0026 for why this fallback exists and why it's a silent-failure risk.
- `localParticipantIdentifier` can rotate if the user clears Messages data. A mid-game reset would lock them out of their color. Accepted limitation.
