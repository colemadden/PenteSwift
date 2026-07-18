# 0041 — Pinch-to-zoom + pan via transforms outside the tap gesture

- **Status**: Accepted
- **Date**: 2026-07-16
- **Version**: v1.4
- **Source**: FEATURE_ROADMAP §v1.4 item 4a; 5-star review feature request

## Context

The 19×19 grid produces mis-taps on small screens — the only user-requested
feature (5-star US review). The naive implementation transforms tap coordinates
manually through the zoom/pan matrix, which is error-prone and duplicates state
between gesture handling and hit-testing.

## Decision

`.scaleEffect(zoomScale)` + `.offset(panOffset)` are applied to the board
content *after* (outside) its `onTapGesture`. SwiftUI hit-testing maps touches
through rendering transforms onto the view they land in, so the tap handler
receives locations already in logical board coordinates — the existing tap math
is untouched. `MagnificationGesture` clamps scale to 1–3×;
`DragGesture` pans only while zoomed, clamped so board edges never pull inside
the viewport. `.clipped()` + `.contentShape(Rectangle())` bound both rendering
and hit-testing to the board frame, which keeps ADR-0030's "outside the board
cancels" semantics stable at any zoom level.

## Alternatives considered

- **Manual tap-coordinate transform.** Rejected: duplicate math, off-by-half
  bugs, and it breaks silently if the transform stack changes.
- **Auto-center on last opponent move on open** (roadmap suggestion). Rejected:
  zoom state resets to 1× on every extension activation, so there is nothing to
  re-center; add only if users ask for persistent zoom.
- **Double-tap to reset zoom.** Rejected for now: pinch-out already resets, and
  double-tap would race the single-tap placement gesture.
- **Haptic "snap" when finger crosses intersections** (roadmap bonus). Rejected:
  requires continuous drag-tracking of touch location on the Canvas; disproportionate
  to the benefit and easy to add later if requested.

## Consequences

- Zoom/pan is view-local `@State`: resets on every extension activation, never
  persisted, never encoded.
- The stone-animation overlay (ADR-0033) sits inside the transformed content, so
  it zooms/pans with the board automatically.
- Pan clamping keeps `(scale-1)·size/2` overhang; any layout change to the board
  container must preserve the GeometryReader-size coupling.
