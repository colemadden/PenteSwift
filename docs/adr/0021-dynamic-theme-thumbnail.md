# 0021 — Dynamic-theme bubble thumbnail via `UIImageAsset`

- **Status**: Accepted
- **Date**: 2025-12-16 (formalized)
- **Version**: v1.1
- **Source**: commit `ec3b909`; `Pente MessagesExtension/MessagesViewController.swift:131-148`

## Context

The message bubble thumbnail is rendered once at send time but displayed in the *receiver's* device trait collection. If the sender is in light mode and we render a single light-palette image, a dark-mode receiver sees a light image in their otherwise dark transcript — jarring.

Apple's solution: `UIImageAsset.register(image, with: UITraitCollection(userInterfaceStyle: ...))`. The system auto-picks the correct registered image for the current trait collection at render time.

## Decision

`MessagesViewController.createDynamicBoardImage(size:)`:

1. Calls `gameModel.generateBoardImage(size:, colorScheme: .light)`.
2. Calls `gameModel.generateBoardImage(size:, colorScheme: .dark)`.
3. Constructs a `UIImageAsset` and registers both against `UITraitCollection(userInterfaceStyle:)`.
4. Returns `imageAsset.image(with: .current)`.

The resulting `UIImage` is set on `MSMessageTemplateLayout.image`. The bubble uses the viewer's trait collection, not the sender's.

## Alternatives considered

- **Render once in sender's theme.** Rejected: mismatches the receiver's mode.
- **Render a "neutral" palette that works in both.** Rejected: bland, loses the warm wood aesthetic.
- **Render server-side per viewer.** Rejected: violates ADR-0020 (no backend).

## Consequences

- Send-time cost is two image renders instead of one. Negligible at 300×300.
- `BoardImageGenerator` must maintain two palettes that match the SwiftUI live view exactly. Any palette drift shows as a visible handoff seam.
- **What adapts and what doesn't**: the *board palette* (background, grid, stone colors) is explicitly branched on the `colorScheme` parameter and renders per-variant correctly. The *last-move ring*, however, uses `UIColor.systemGreen.cgColor` inline — `systemGreen` resolves against the trait collection *active at render time* (the sender's), not against the `colorScheme` parameter. Both variants therefore bake in whichever RGB the sender's mode produces. ADR-0013 has the precise statement. Workaround (not currently applied): wrap the ring draw in `UITraitCollection(userInterfaceStyle:)` + `performAsCurrent`.
