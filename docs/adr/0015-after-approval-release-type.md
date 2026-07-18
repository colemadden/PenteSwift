# 0015 — `AFTER_APPROVAL` release type (proposed policy)

- **Status**: Proposed — policy documented only; no committed repo artifact shows this setting being used for any specific submission.
- **Date**: unknown. Per the repo convention documented in `docs/adr/README.md`, the `Date` field records when the underlying decision was made. No committed artifact attests to when (or whether) this policy was decided, so the field is left unknown rather than invented. If evidence surfaces (a scripted submission payload, a dated note in `.claude/CLAUDE.md`, a reviewer comment), update this field.
- **Version**: n/a — this is a release-process policy, not a source-code change; it does not map to a `MARKETING_VERSION`.
- **Source**: no committed repo artifact. `.claude/CLAUDE.md` is gitignored and cannot be cited from a versioned document.

## Context

App Store Connect supports three release types when a version is submitted for review: MANUAL (developer clicks Release after approval), SCHEDULED (release on a specific date), and AFTER_APPROVAL (release immediately when Apple approves). Choosing one per submission is required. The choice has no impact on source code — it's a per-submission field in ASC.

This ADR exists to record which of the three we intend to select by default going forward, so future agent-driven or scripted submissions have a documented default.

## Decision (intended policy)

Intend to set `releaseType = AFTER_APPROVAL` when creating a new `appStoreVersion` via the ASC API.

Nothing in the repo presently verifies or enforces this: `APP_STORE_SUBMISSION.md` does not mention `releaseType`, no sample API-request payload is committed, and no test or script gates on it. If a future submission reveals we've actually been using MANUAL or SCHEDULED, this ADR should be updated rather than treated as ground truth.

## Alternatives considered

- **MANUAL**: adds a human step after approval. Acceptable if we ever want a release window we control (e.g. coordinating with marketing).
- **SCHEDULED**: lets us pin a specific launch date. No current use case.

## Consequences if the policy is actually applied

- Time between build upload and user availability is bounded by Apple review time (historically 24–48h, not guaranteed).
- A critical bug caught after approval cannot be held — next build is the only fix path.
- No manual "release" click is needed.

These are the *expected* consequences of the intended policy. They are not claimed observations.
