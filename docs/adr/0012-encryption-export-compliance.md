# 0012 — Declare `ITSAppUsesNonExemptEncryption = NO`

- **Status**: Accepted
- **Date**: 2026-03-02
- **Version**: v1.1 (build 3)
- **Source**: commit `d6f6fbc` "Add encryption export compliance declaration"; `Pente MessagesExtension/Info.plist`

## Context

Every App Store build faces US export-compliance questions ("does your app use encryption?"). For an app that uses only iOS HTTPS/TLS via Apple-supplied frameworks and no custom cryptography, the answer is "exempt" and the declaration can be made in Info.plist to skip the ASC submission dialog on every upload.

## Decision

Set `ITSAppUsesNonExemptEncryption = NO` in the extension's Info.plist. Do not implement or link any custom crypto.

## Alternatives considered

- **Leave the key unset and answer the ASC dialog on every upload.** Rejected: wastes time per release, easy to mis-click.
- **Set `YES` and file the annual self-classification report.** Rejected: we have no non-exempt encryption; setting YES is factually wrong.

## Consequences

- ASC no longer asks about encryption on each build upload.
- Any future feature that introduces custom crypto (e.g. end-to-end encrypted game state) would require this to be re-evaluated.
- Declaration is factually accurate as of v1.3: the app has no networking, no crypto, no secure-enclave use.
