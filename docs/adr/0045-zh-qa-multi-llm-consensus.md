# 0045 — zh-Hans QA: multi-LLM consensus replaces the native-reviewer gate

- **Status**: Accepted
- **Date**: 2026-07-18
- **Version**: process (applies from v1.4.x onward)
- **Source**: project-owner direction 2026-07-18

## Context

Every zh-Hans batch so far (v1.3 in-app strings, the ASC listing copy) went
through the same pipeline: multiple LLMs (Claude, Codex, Gemini, occasionally a
translate API) independently draft, differences are ironed out via consensus,
then Cole's native-speaker friend reviews. Across every batch, the friend has
approved with **zero edits** — the consensus step already converges on natural
copy. Waiting for his availability was the longest pole in every release, and
Cole doesn't want to keep imposing on him.

## Decision

New zh-Hans copy ships after **multi-LLM consensus review, no human gate**:

1. Draft following the ADR-0028 glossary (`夹吃` mechanic verb, `吃对` count
   noun, `五子连珠` for five-in-a-row).
2. Cross-check with at least one independent LLM (Codex at minimum; Gemini
   and/or an online translate API when available). Independent means: ask for
   a critique or fresh translation, not confirmation of the draft.
3. Resolve disagreements toward the more natural/idiomatic phrasing; nitpick
   ties break toward the existing in-app register.
4. Ship. The native-speaker friend is no longer asked per release.

## Alternatives considered

- **Keep the native-reviewer gate.** Rejected by owner: longest step of every
  release, zero defects caught across all batches, and it burdens a friend.
- **No review at all (single-LLM draft).** Rejected: the committee step is
  cheap and has caught nitpicks; consensus is the actual quality mechanism.

## Consequences

- Release cadence no longer blocks on a human's availability.
- If a shipped string later gets user complaints (reviews, feedback), that is
  the signal to re-add human review for that surface — supersede this ADR then.
- ADR-0028's glossary remains binding; ADR-0043's "needs native review" note is
  superseded by this process.
