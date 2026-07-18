# 0011 — Locale-neutral circle glyphs for `trailingSubcaption`

- **Status**: Accepted
- **Date**: 2026-04-23
- **Version**: v1.3
- **Source**: `Pente MessagesExtension/MessagesViewController.swift:170-199`; `Localizable.xcstrings:39-40` comment

## Context

`MSMessageTemplateLayout` strings (caption, subcaption, trailingSubcaption) travel **with the message**. The receiver does not re-render them in their own locale. Consequence: if a Chinese sender sends a move, an English receiver sees Chinese text in the bubble.

For the subcaption we accept that asymmetry — the text is the turn indicator, it's in the sender's language, and it's descriptive rather than critical. For the trailing subcaption we use it to show capture counts ("●2 ○1"), which should be readable to everyone regardless of locale.

## Decision

- `layout.caption` — the literal string "Pente" (brand, identical in every locale).
- `layout.subcaption` — localized turn/win text in the sender's locale. A code comment documents that this is asymmetric by design.
- `layout.trailingSubcaption` — locale-neutral: `●<blackCaptures> ○<whiteCaptures>` using filled/hollow circle glyphs. Not localized. Only present if either side has >0 captures.

## Alternatives considered

- **Localize trailing subcaption too.** Rejected: same asymmetry problem, and capture counts are a numeric glance — letters add noise.
- **Drop trailing subcaption entirely.** Rejected: captures are a primary game-state dimension; the thumbnail alone doesn't surface them.
- **Re-render subcaption on receive.** Rejected: `MSMessage.layout` is set once at send time; Messages doesn't expose a hook to rewrite it per-viewer.

## Consequences

- The trailing subcaption IS safe to transmit — identical across locales.
- Any future bubble-layout copy change must decide: localize (sender-locale-only) or go glyphic (viewer-neutral).
- ● and ○ circle glyphs render consistently across iOS versions and fonts. No fallback needed.
