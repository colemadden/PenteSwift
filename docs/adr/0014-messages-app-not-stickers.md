# 0014 — Interactive Messages app, not a sticker pack

- **Status**: Accepted
- **Date**: 2025-07-20 (corrected from sticker config in commit `fa6bc15`, finalized in `8854fac`)
- **Version**: v1.0 → v1.1
- **Source**: commits `fa6bc15`, `8854fac`; `Pente MessagesExtension/Info.plist`; `Pente MessagesExtension/Assets.xcassets/iMessage App Icon.stickersiconset/`

## Context

iMessage extensions come in two flavors: sticker packs (no interactive UI, just image catalogs) and interactive Messages apps (full `MSMessagesAppViewController` with your own SwiftUI/UIKit). An early misconfiguration had the app registered as a sticker icon set, which caused blank icons in the Messages app drawer.

## Decision

- `NSExtensionPointIdentifier = com.apple.message-payload-provider` in `Info.plist` — this alone is what makes the extension interactive. No value in Info.plist identifies it as a sticker pack.
- Icon asset catalog holds the required Messages app-icon sizes (27×20, 32×24, 60×45, 67×50, 74×55 at @2x/@3x for iPad/iPhone) plus a 1024×768 App Store marketing icon.

Note: the asset catalog folder on disk is confusingly named `iMessage App Icon.stickersiconset`, and the project's `ASSETCATALOG_COMPILER_APPICON_NAME` build setting points at `iMessage App Icon`. The **folder suffix does not determine extension type** — the `NSExtensionPointIdentifier` does. The folder name is historical from the early sticker-pack configuration and could be renamed cosmetically, but it has no runtime effect.

## Alternatives considered

- **Sticker pack format.** Rejected: cannot host interactive game UI.
- **Combined sticker + app.** Rejected: adds complexity for zero gain — we never ship static stickers.

## Consequences

- Required icon sizes are fixed by Apple. Any icon update must generate all sizes.
- Icon set is a release-blocker: blank icons fail App Store review. Icon changes require verification on-device.
- A free developer account cannot ship Messages apps in iMessage — paid program membership is required (documented in CLAUDE.md §"Apple Developer Account Requirements").
