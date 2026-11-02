# 0048 — App Store screenshots are captured from the real extension in Messages, then framed

- **Status**: Accepted
- **Date**: 2026-11-01
- **Version**: v1.5
- **Source**: owner request 2026-11-01 (old screenshots showed a 7% battery, a real contact photo, an outdated UI)

## Context

The live listing's screenshots were hand-taken on a personal phone: low-battery status
bar, a real contact's photo, pre-v1.4 UI ("New Game"), and mostly empty boards. We need
repeatable, clean captures of specific game states (mid-game, capture preview, gold
five, win overlay, chat bubble, dark mode, rules card) on 6.9" iPhone and 13" iPad.

## Decision

Capture real screenshots of the extension running inside Messages in the iOS 27.0
simulator (`simctl status_bar … override --time 9:41 --batteryLevel 100`), load each
position via a **local-only, never-committed** `#if DEBUG && targetEnvironment(simulator)`
hook that reads a URL-encoded state from `build/shot-state.txt`, then frame the raw
captures with a Pillow script (walnut gradient, New York serif headline, device bezel).
The hook diff, position designs, and framing scripts are recorded in
`marketing/screenshots/README.md`.

## Alternatives considered

- **SwiftUI `ImageRenderer` in a test.** Rejected: no Messages chrome, and the test
  bundle's `Bundle.main` is the test runner, so `Text("key")` renders raw catalog keys.
- **Xcode 27 MCP `RenderPreview`.** Not possible: previews are blocked for
  `com.apple.product-type.app-extension.messages` targets.
- **Commit the DEBUG hook.** Rejected per Code Minimization: it is a few lines but
  serves only marketing, and a file read in `willBecomeActive` is the kind of thing
  that should never be able to ship.
- **Play real games by tapping.** Rejected: the simulator has one local participant,
  so only black can move after the first send.

## Consequences

- Screenshot positions are reproducible from `marketing/screenshots/README.md`; zh-Hans
  captures only need the simulator language switched plus translated captions
  (ADR-0045 QA applies to caption copy).
- iPhone Duo screenshots (1398×2034 outer, 2007×2853 inner; optional until April
  2027) can't be captured in Messages until a Duo runtime ships with Messages.
