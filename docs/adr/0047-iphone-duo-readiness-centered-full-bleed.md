# 0047 — iPhone Duo readiness: build on the iOS 27.1+ SDK, centered stack, full-bleed hosting

- **Status**: Accepted
- **Date**: 2026-11-01
- **Version**: v1.5 (absorbs the never-uploaded v1.4.1)
- **Source**: owner request 2026-11-01 ("make it work with the new iPhone Duo"); Apple "Prepare your app for iPhone Duo" tech talk + developer.apple.com/iphone-duo/prepare; simulator verification on iPhone 18 Pro Max and iPad Pro 13" (iOS 27.0)

## Context

iPhone Duo (foldable; outer display 466×678 pt, inner 669×951 pt) shipped fall 2026.
Apps built with the iOS 26 SDK or earlier run letterboxed/centered on it. Apps built
with the **iOS 27.1+ SDK** fill both displays, may get *asymmetric* safe areas
(status bar and camera sit on the trailing edge of the outer display), and see
`regular/regular` size classes on the inner display.

Audit of our code against Apple's checklist (and Xcode 27's `app-resizability`
agent skill): no `UIScreen.main`, no orientation checks, no idiom checks, no
hard-coded device sizes. The board was already `GeometryReader` + `.aspectRatio(1, .fit)`.
So the only *required* step is rebuilding with Xcode 27.1+.

Simulator review on a 6.9" phone surfaced two layout flaws that the Duo's taller /
wider canvases make worse:
1. The game `VStack` ended with a `Spacer()`, pinning everything to the top and
   leaving ~⅓ of the expanded sheet empty below the turn indicator.
2. The hosting view was constrained to `safeAreaLayoutGuide`, so the dim overlays
   (win overlay, rules card — ADR-0032/0043) stopped short of the home-indicator
   strip, leaving a white band.

## Decision

Ship the next build from Xcode 27.1+ (27.2 on the build Mac), remove the trailing
`Spacer()` so the stack centers vertically, and pin the `UIHostingController`'s view
to the controller view's edges (SwiftUI keeps foreground content in the safe area on
its own) with `.ignoresSafeArea()` on the two `Color.black.opacity(0.55)` dim layers.

## Alternatives considered

- **Do nothing beyond the rebuild.** Rejected: the empty bottom third is the most
  visible thing on a big screen and shows up in every App Store screenshot.
- **Wide-layout variant (board left, scores/controls right) via size class.**
  Rejected for now — more code, and on iPad/regular width Messages presents the
  extension as a phone-sized app card anyway (observed on iPad Pro 13", iOS 27.0),
  so the vertical stack is what users actually see. Revisit with on-device Duo data.
- **Keep safe-area pinning and pad overlays manually.** Rejected: more code and
  re-implements what SwiftUI already does with asymmetric insets.

## Consequences

- Foreground content still respects the safe area (UIHostingController propagates
  insets). Any future full-bleed background must be a `ShapeStyle` background or use
  `.ignoresSafeArea()`; any future foreground overlay must *not*.
- ADR-0040's fixed-height bottom slot still decouples board size from slot content;
  centering only moves free space from the bottom to both ends.
- **Not verified on Duo itself**: the iPhone Duo simulator runtime (iOS 27.1,
  build 24A94425) ships without Messages, so the extension cannot be launched there.
  Verification was done on iPhone 18 Pro Max (compact + expanded) and iPad Pro 13"
  (regular width — same size class as the Duo inner display). First physical-Duo
  test should check outer-display landscape (compact/compact) and the fold.
