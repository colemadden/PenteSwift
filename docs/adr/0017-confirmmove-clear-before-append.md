# 0017 — `confirmMove()` clears pending state before appending to history

- **Status**: Accepted
- **Date**: 2026-04-07
- **Version**: v1.3
- **Source**: commit `a292b98`; `Pente MessagesExtension/PenteGameModel.swift:85-125`

## Context

With the blue-ring/green-ring convention (ADR-0009), blue is the pending stone and green is the last committed move. The risk is a single intersection being both "pending" and "last-committed" for one SwiftUI render pass during `confirmMove()` — which would show *both* rings overlapping at the same place. Even if imperceptible, this is a state invariant violation.

SwiftUI normally coalesces multiple `@Published` emissions inside a synchronous method into a single view update. In principle we could rely on that. In practice, future refactors (async work, tasks, inserting a network call) could accidentally break the invariant — and the test suite needs a deterministic rule to assert against.

## Decision

`confirmMove()` follows this exact order (belt-and-suspenders):

1. Snapshot `pendingCaptures` into a local `capturesToApply` array.
2. Set `pendingMove = nil`, `pendingCaptures = []`, `lastCaptures = []`.
3. Append `(row, col, player)` to `moveHistory`.
4. Apply `capturesToApply` to the board and update capture counts.
5. Check win conditions.
6. Flip `currentPlayer` if game continues.
7. `updateMovePermissions()`.
8. `moveDelegate?.gameDidMakeMove()`.

The snapshot in step 1 is essential — if we cleared `pendingCaptures` first and then tried to apply them from the cleared array, we'd apply nothing.

`loadFromURL()` has a parallel invariant: assign `gameBoard` and `moveHistory` **together at the top** of the function, so any intermediate render sees a consistent (board, moveHistory) pair. Otherwise the green ring would briefly point at an old intersection on the new board.

## Alternatives considered

- **Clear pending state AFTER appending.** Rejected: creates the brief blue+green coexistence window. Original buggy order.
- **Use an explicit single-transaction mechanism.** Rejected: SwiftUI already coalesces; the reorder is sufficient and cheaper.

## Consequences

- Any future edit to `confirmMove()` must preserve the order. A code comment explains why.
- Tests in `PenteGameModelTests.swift:776-888` assert the ordering via `objectWillChange` observation. Don't let anyone "clean up" those tests without understanding what they protect.
- Similar invariant in `loadFromURL()` (PenteGameModel.swift:151-163) must be preserved across refactors.
