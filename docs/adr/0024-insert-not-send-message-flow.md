# 0024 — `conversation.insert(message)` for the in-app Send action

- **Status**: Superseded by ADR-0029
- **Date**: 2025-06-29
- **Version**: v1.0
- **Source**: `Pente MessagesExtension/MessagesViewController.swift:206-221`; FEATURE_ROADMAP §4 v1.4 item 5

## Context

When the user taps "Send" in our UI, we have two ways to get the move into the thread:

- `MSConversation.insert(message)` — puts the message into the compose field and exits the extension. The user must tap the blue iMessage Send arrow a second time to actually send.
- `MSConversation.send(message)` — sends immediately, no second tap.

GamePigeon Gomoku's in-app Send sends immediately (single tap, no compose step). Our current two-tap flow is less polished. This was the shape of the initial implementation and has never been revisited.

## Decision

Use `conversation.insert(message)` followed by `dismiss()`. The user confirms with the iMessage compose field's Send arrow as the second tap.

## Alternatives considered

- **`conversation.send(message)`** (preferred direction): immediate send. Matches GamePigeon. Requires testing in compact vs expanded presentation — `send` historically had restrictions around which presentation styles allow it.
- **Conditional: `send` in expanded, `insert` in compact.** Rejected for now as premature; need to confirm actual `send` constraints first.

## Consequences

- Users get a two-tap flow. Less polished than GamePigeon.
- Switching to `send` is proposed as v1.4 item 5 in FEATURE_ROADMAP. The change is ~1 line plus testing. This ADR should be superseded when that behavior lands in a version-bump commit.
- An "edit before sending" affordance would be preserved by the current flow; if switching to `send`, consider an opt-in "attach note" path.
- **Open question**: was `insert` chosen deliberately (e.g. to let users add a caption or decide not to send) or was it just the first API we tried? No surviving chat/commit documents the reasoning. This ADR documents the *status quo*, not a principled decision.
