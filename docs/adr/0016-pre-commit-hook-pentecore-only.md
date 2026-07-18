# 0016 — Pre-commit hook runs only PenteCore tests

- **Status**: Accepted
- **Date**: 2026-04-05 (with the PenteCore extraction)
- **Version**: v1.2
- **Source**: `.git/hooks/pre-commit`; `CLAUDE.md` §Testing Strategy

## Context

With 258 tests in the extension's simulator-backed `PenteTests`, running "all tests" on every commit is a multi-second operation and requires a booted simulator. That's enough friction to discourage small, frequent commits. Meanwhile, the PenteCore pure-logic tests (40 tests) run in <1 second via `swift test` with no simulator.

## Decision

The pre-commit hook runs `swift test` inside `PenteCore/` only. Failure blocks the commit. Full simulator tests are a manual step before push or release (documented in `CLAUDE.md` and `.claude/CLAUDE.md` §"Release Checklist").

```bash
cd "$(git rev-parse --show-toplevel)/PenteCore" && swift test --quiet
```

## Alternatives considered

- **Full suite in pre-commit.** Rejected: too slow.
- **No pre-commit hook; rely on discipline.** Rejected: PenteCore tests catch the highest-value class of regressions (rule-engine bugs) at nearly zero cost.
- **Pre-push hook instead.** Considered; could complement pre-commit later. Not yet implemented.

## Consequences

- Commits with broken UI tests but green logic tests will pass the hook. This is an accepted tradeoff.
- No CI runs the full suite; ship discipline carries it. `.claude/CLAUDE.md` release checklist enforces the full run before uploading builds.
- If PenteCore ever gains long-running tests (e.g. an AI opponent with deep search), the hook will need a `--filter` or split.
