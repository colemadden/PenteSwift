# 0006 — One `MSSession` per game

- **Status**: Accepted
- **Date**: 2026-04-05
- **Version**: v1.2
- **Source**: `Pente MessagesExtension/MessagesViewController.swift:10,75-83,150-153`; commit `72d99a2` introduced `currentSession: MSSession?`. Pre-v1.2 messages were constructed with a bare `MSMessage()` and did not coalesce in the transcript.

## Context

MSMessage supports optional `MSSession` objects. When an `MSMessage` shares a session with a previous one in the transcript, the Messages UI collapses them into a single evolving bubble rather than showing one bubble per move. It also allows Messages to suppress replay of outdated states (a user tapping an old bubble after a newer move shouldn't overwrite current state).

Without a session, each move would create a fresh bubble — the transcript would be a tower of duplicated board previews.

## Decision

A game owns exactly one `MSSession`. The extension caches `currentSession: MSSession?` on the view controller. On `willBecomeActive`:

- If a selected message exists, reuse `message.session` as the current session (and stay in the game it represents).
- If no selected message exists, start a fresh game and `MSSession()` a new one.

Every `MSMessage` constructed via `createMessage()` is initialized with the cached `currentSession`.

## Alternatives considered

- **No session; one bubble per move.** Rejected: transcript pollution.
- **One session per user.** Rejected: doesn't match Apple's intent; breaks across multiple simultaneous games in the same conversation.

## Consequences

- Multiple parallel games in the same conversation still work — each has a distinct session.
- The "cached session" is per-app-instance; restarting the extension picks up the session from the selected message on `willBecomeActive`.
- This is a load-bearing invariant: any future code that constructs `MSMessage` must use the cached session (or create a new one only for explicit new-game cases).
