# 0022 — Separate wire `Player.rawValue` from localized display key

- **Status**: Accepted
- **Date**: 2026-04-23
- **Version**: v1.3
- **Source**: `PenteCore/Sources/PenteCore/GameTypes.swift:3-17`

## Context

`Player` is both a runtime enum (used in rendering, messages, turn logic) and a wire-format value (serialized to URL query params: `current=Black`, `winner=White`, move prefixes `B`/`W`). Adding zh-Hans localization creates tension: the UI wants "黑方" / "白方" for Chinese users, but the URL MUST stay `Black` / `White` or every in-flight game breaks.

`WinMethod` has the identical problem — `method=fiveInARow` must stay English as a wire value, but the UI wants the right-locale win banner.

## Decision

`Player.rawValue` stays English (`"Black"`, `"White"`). A separate `displayNameKey` computed property returns the localization key (`"player.black"`, `"player.white"`), which SwiftUI resolves through `LocalizedStringKey`. Same pattern for `WinMethod.bannerKey` → `"win.method.fiveInARow"`.

A code comment in GameTypes.swift:11-16 documents the invariant: "rawValue is the wire format for URL-encoded game state and must never change. Display strings resolve through this key instead."

## Alternatives considered

- **Translate `rawValue` too.** Rejected: breaks every in-flight game on upgrade, cannot be done ever.
- **Maintain two enums (one wire, one display).** Rejected: redundant, easy to desync.
- **Store localized string alongside enum.** Rejected: conflates representation with presentation.

## Consequences

- Any new enum added to PenteCore must follow the same pattern: keep rawValue English if it ends up in the wire format; derive a `*Key` computed property for display.
- `LocalizationCatalogTests` resolves every display key against the compiled catalog and asserts the English values match expected strings. It does not validate zh-Hans translations — native-reviewer sign-off is still pending (see ADR-0028).
- If we ever drop URL encoding for a Codable-JSON payload with version negotiation, this constraint relaxes — but we'd still need to stay compatible with legacy `Black`/`White` strings for as long as old messages might be decoded.
