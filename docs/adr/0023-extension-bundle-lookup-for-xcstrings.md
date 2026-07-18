# 0023 — `Bundle(for: MessagesViewController.self)` to find the xcstrings catalog

- **Status**: Accepted
- **Date**: 2026-04-23
- **Version**: v1.3
- **Source**: `Pente MessagesExtension/MessagesViewController.swift:12-16`

## Context

`String(localized:)` and `String(localized:bundle:)` look up catalog entries relative to a bundle. In production the extension's `Bundle.main` is the extension bundle, which owns `Localizable.xcstrings` — everything just works. **In XCTest**, `Bundle.main` resolves to the *test runner* bundle, which does not contain the catalog, and every localized lookup returns the raw key string instead of the translation. This breaks `LocalizationCatalogTests` and every test that exercises message-layout copy.

## Decision

Define a static property on `MessagesViewController`:

```swift
private static let localizationBundle = Bundle(for: MessagesViewController.self)
```

Use `bundle: Self.localizationBundle` on every `String(localized:)` call in the extension. `Bundle(for: aClass.self)` returns the compiled bundle that *contains* the class. In production that's the extension bundle. In XCTest, this repo's test target compiles the extension sources (and the xcstrings catalog) directly via a filesystem-synchronized group — so `Bundle(for: MessagesViewController.self)` resolves to the test bundle, which has the catalog compiled in. Either way it reaches a bundle that contains the translations.

## Alternatives considered

- **`Bundle.main`.** Rejected: in XCTest that's the test runner, which does not contain the catalog.
- **Custom bundle identifier lookup (`Bundle(identifier: "colemadden.Pente.MessagesExtension")`).** Rejected: brittle — breaks if the bundle ID changes, and breaks in XCTest because the extension bundle isn't actually loaded.
- **Skip tests that exercise localization.** Rejected: catalog coverage is exactly what needs to be tested.

## Consequences

- Every localized string lookup in the extension MUST pass `bundle: Self.localizationBundle`. Forgetting this causes test failures that only manifest in XCTest, not in runtime.
- This approach depends on the current test-target setup (extension sources compiled into the test bundle via filesystem-synchronized groups — see `Pente.xcodeproj/project.pbxproj:196-198`). If the test target is ever restructured to host-test the extension rather than compile-in its sources, `Bundle(for:)` would resolve differently and the lookup may need to switch to a host-bundle strategy.
- Keep the static on `MessagesViewController` and route other classes through it, rather than duplicating the pattern per class.
- `SwiftUI.Text(LocalizedStringKey(...))` is unaffected — it uses the view's `EnvironmentValues.bundle` which is already correct.
