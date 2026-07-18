# 0010 — Use `Localizable.xcstrings` string catalog

- **Status**: Accepted
- **Date**: 2026-04-23
- **Version**: v1.3
- **Source**: `Pente MessagesExtension/Localizable.xcstrings`; commit `e0c17c3`; FEATURE_ROADMAP.md §2

## Context

Adding Simplified Chinese required a localization solution. Two realistic options on iOS 18:

- Per-locale `.strings` files (the legacy approach — `en.lproj/Localizable.strings`, `zh-Hans.lproj/Localizable.strings`).
- A single `Localizable.xcstrings` catalog file (Xcode 15+ format, JSON-backed, UI for state tracking).

## Decision

Use a single `Localizable.xcstrings` catalog in the extension target (22 keys) and the host app target (2 keys). Extract strings manually; `extractionState: "manual"` for each entry so Xcode doesn't churn the file.

## Alternatives considered

- **Per-locale `.strings` files.** Rejected: two files to keep in sync per language; merging is unpleasant; no state tracking.
- **Third-party tool (Crowdin, Lokalise).** Rejected: premature at 22 keys; the data already lives in one JSON file that a native reviewer can read directly.

## Consequences

- Single source of truth for translations. `LocalizationCatalogTests` asserts key presence in both locales.
- `String(localized:bundle:)` lookups require the extension bundle (not `Bundle.main`, which in XCTest is the test runner). See ADR-0023.
- Adding a new language is an entry-level operation — add a `zh-Hant` or `ja` locale block and the rest works.
- File format is JSON; large diffs in PRs are readable but noisy. Acceptable at this scale.
