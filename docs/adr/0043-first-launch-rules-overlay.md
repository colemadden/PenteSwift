# 0043 — First-launch rules overlay, one card, UserDefaults flag

- **Status**: Accepted (native-review consequence superseded by ADR-0045 — zh QA is now multi-LLM consensus)
- **Date**: 2026-07-16
- **Version**: v1.4
- **Source**: FEATURE_ROADMAP §v1.4 item 7; 1-star zh review ("帮对手下棋，谁懂啊？"); tester capture confusion (Mehera)

## Context

Pente's capture rule is the one thing nobody arriving from Gomoku expects — and
~85% of new installs are from China, where the game reads as 五子棋. Both real
user-confusion reports (the 1-star review and Mehera's vanished stones) trace to
not knowing captures exist.

## Decision

A single static card overlaid on first launch: title + three glyph-illustrated
rules (`●●●●●` five-in-a-row wins; `●○○●` sandwich a pair to capture it —
"unlike Gomoku" stated explicitly; `○○ ×5` five pairs also wins) + a "Got it!"
pill. Dismissed only by the button (no tap-outside), persisted via
`@AppStorage("hasSeenRules")` so it shows once per install. zh-Hans copy follows
the ADR-0028 glossary (`夹吃` for the mechanic, `五子连珠` for five-in-a-row).

## Alternatives considered

- **Swipeable multi-card tutorial.** Rejected: 3 rules fit one card; paging adds
  state and drop-off risk.
- **Interactive guided first game.** Rejected: large LOC for a first-session
  nicety; revisit only if confusion reports continue.
- **Tap-outside dismissal.** Rejected: too easy to dismiss accidentally before
  reading — this card exists precisely for the rule people don't know to look for.

## Consequences

- Five new xcstrings keys (`tutorial.*`), en + zh-Hans. **zh strings are
  LLM-drafted to the ADR-0028 glossary and need native review before release.**
- `hasSeenRules` lives in the extension's `UserDefaults.standard` — resets on
  reinstall, which is acceptable (arguably desirable).
- Overlay is the topmost layer; it covers the win overlay in the pathological
  first-launch-into-finished-game case, which is fine — rules first.
