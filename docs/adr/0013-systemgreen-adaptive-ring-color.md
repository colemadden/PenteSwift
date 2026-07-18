# 0013 — Use `systemGreen` for the last-move ring so it adapts per viewer

- **Status**: Accepted
- **Date**: 2026-04-07
- **Version**: v1.3
- **Source**: `Pente MessagesExtension/PenteGameView.swift:298-314`; `BoardImageGenerator.swift:109-129`

## Context

The last-move ring appears in two places: the live SwiftUI view and the bubble thumbnail image. The bubble thumbnail is rendered at *send* time but displayed in the *receiver's* trait collection (via `UIImageAsset`, see ADR-0021). A hardcoded green value would look wrong in one mode or the other depending on whose theme we picked at authoring time.

## Decision

Use Apple's adaptive `systemGreen` in both places:

- Live view: `Color(.systemGreen)` (bridging from `UIColor.systemGreen`). This is resolved adaptively in the viewer's trait collection at render time, so it always matches the viewer's mode.
- Thumbnail: `UIColor.systemGreen.cgColor` inside `UIGraphicsImageRenderer`. This resolves against **the sender's trait collection at render time** and is baked into the PNG bitmap.

## What actually adapts per viewer

- **Live view ring**: yes, fully adaptive — resolves on the viewer's device.
- **Thumbnail board palette**: yes — the dual-render + `UIImageAsset` mechanism (ADR-0021) picks the right light/dark variant for the viewer.
- **Thumbnail ring color**: **no** — the ring's RGB is frozen at sender render time. A sender in dark mode bakes a dark-appropriate green into both variants; a sender in light mode bakes a light-appropriate green into both. The viewer sees one of those bitmaps, unchanged.

The practical effect is small: Apple's systemGreen light/dark values are close enough that the ring reads correctly in either viewer theme. But the docs previously overclaimed "adapts per viewer" — this ADR is the record of the real behavior.

## Alternatives considered

- **Hardcoded `#34C759`.** Rejected: would look wrong in whichever mode wasn't targeted.
- **Render the ring per-viewer-variant using `UITraitCollection.performAsCurrent { … }` in `BoardImageGenerator`.** Considered but not implemented: it would mean drawing the ring twice (once per variant) with explicit trait overrides and it's not clear it's a visible improvement. Open debt if viewers ever complain.
- **Two distinct greens switched on `colorScheme`.** Rejected: `systemGreen` already encodes Apple's chosen values; reinventing them is pointless.

## Consequences

- Live-view ring matches iOS system conventions adaptively.
- Thumbnail ring is visually "close enough" in the opposite-mode case but is not literally viewer-adaptive. If this becomes a complaint, fix by wrapping the ring-drawing block in a `UITraitCollection(userInterfaceStyle:)` + `performAsCurrent` block per variant.
- Pinning a custom brand green would require per-variant assets and is not planned.
