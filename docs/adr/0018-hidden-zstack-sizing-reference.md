# 0018 — Hidden sizing reference in the bottom-cluster ZStack

- **Status**: Superseded by ADR-0040
- **Date**: 2026-04-23
- **Version**: v1.3
- **Source**: `Pente MessagesExtension/PenteGameView.swift:62-71`; commit `e0c17c3`; FEATURE_ROADMAP v1.4 item 12

## Context

The bottom of the game view shows different content depending on state: an Undo/Send button pair, a "Send" button, a "Your turn" turn indicator, a "Waiting for opponent" two-line block, or a won-state VStack with "New Game" button. Each has a different intrinsic height. In a plain SwiftUI `VStack`, the board above (which uses `.aspectRatio(1, contentMode: .fit)`) resizes to fill the remaining space — so it *visibly jumps* between states.

## Decision

Wrap the bottom cluster in a `ZStack`. Inside it, include a hidden `VStack` that matches the **tallest** branch (the won-state `VStack` with title/caption/button). The hidden branch sizes the ZStack to a constant height regardless of which real branch is visible:

```swift
ZStack {
    VStack(spacing: 5) {
        Text("X").font(.title2).bold()
        Text("X").font(.caption)
        Button("X") {}.padding(.top, 5)
    }
    .hidden()   // sizes the ZStack, renders nothing

    // then: switch on game state, render the real branch
}
```

## Alternatives considered

- **`.frame(minHeight: …)` with a fixed point value.** Rejected: brittle across Dynamic Type sizes and locales (zh-Hans text has different metrics).
- **Overlay the status controls on the board.** Tempting but adds layering complexity and hit-testing surface.
- **Lock board size to a fixed computed height via GeometryReader + @State.** Listed in FEATURE_ROADMAP v1.4 item 12 as the proper root-cause fix.

## Consequences

- The bottom cluster is now a fixed height matching the won-state branch, even when playing. No visible board jump.
- If the won-state layout ever gets *taller* than what's shown today (e.g. additional rematch controls), the hidden reference must be updated to match — otherwise the board will jump again.
- This is **interim** debt. FEATURE_ROADMAP v1.4 item 12 proposes a root-cause fix: decoupling board size from sibling heights entirely. When that lands, this ADR should be superseded.
