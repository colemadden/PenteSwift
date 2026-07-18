# 0028 — zh-Hans capture terminology: `夹吃` (verb/mechanic) vs `吃对` (noun/count)

- **Status**: Accepted (per project-owner direction; no native-reviewer signature is committed to the repo — see Source).
- **Date**: 2026-04-23 (in-app catalog landed in commit `e0c17c3`); ADR moved to Accepted on 2026-04-28 per project-owner instruction in conversation.
- **Version**: v1.3 (in-app); v1.4 (ASC listing rollout — not yet shipped at the time of this ADR).
- **Source**: `Pente MessagesExtension/Localizable.xcstrings:4-17,318-333` (in-app catalog, committed). `zh-hans-asc-review.txt` (draft listing copy in the repo; the file contains LLM-process notes and is not itself a reviewer-signed artifact). Project-owner attestation that a native-Chinese friend approved the listing copy is recorded in agent memory at `~/.claude/projects/-Users-colemadden/memory/project_pente_v14_zhhans_copy.md` — that memory file is owner-authored and is not a committed repo artifact. No native-reviewer signature exists in `git`-tracked files.

## Context

Pente has no single accepted Chinese name — it's not the folk term Gomoku/五子棋 (which is the plain five-in-a-row game without captures). The capture mechanic specifically is new to most Chinese players. The current `Localizable.xcstrings` catalog in the repo uses multiple terms:

- `夹吃` ("pinch-eat") — the verb for the capture action, used in win banners: `黑方以夹吃五对获胜！` ("Black wins by capturing five pairs!").
- `吃对` ("eat-pair") — used for the "Captures" header label above the count in the live game view.
- `夹吃五对` — the compound "captured five pairs" used as the tournament-win phrase.

On first read this could look like translation drift — three words for the same concept. Closer reading suggests a deliberate noun-vs-verb distinction: `夹吃` describes the *action* and mechanic, `吃对` is a shorter noun fit for a tight header label showing a count.

## Decision

Formalize the distinction:

- **`吃对`** — used as a noun for the *count* of captures. Appears in live-game capture headers, anywhere a running tally is shown.
- **`夹吃`** — used as a verb / description of the *action*. Appears in capture-win banners, rules explanations, ASC subtitle/description copy. (Five-in-a-row banners use `五子连珠` instead — unrelated.)
- Compound `夹吃五对` specifically for the "won by five captures" phrase.

The formal win-reason key `win.method.fiveCaptures` in the catalog resolves to `夹吃五对！`. The header `Captures` resolves to `吃对`. This is consistent with the distinction. The draft ASC listing copy (`zh-hans-asc-review.txt`) uses `夹吃` consistently as the mechanic word ("不止五子棋，更有夹吃" subtitle; "夹吃规则" / "夹住... 吃掉" in the description; `夹吃` in keywords) — also consistent.

## Alternatives considered

- **Use `夹吃` everywhere.** Rejected — `吃对` fits a count header better.
- **Use `吃对` everywhere.** Rejected — doesn't read as a verb in win banners.
- **Pick a single term and run with it.** Cleanest but sacrifices tonal appropriateness for consistency.

## Consequences

- Future Chinese copy (tutorial screens in v1.4 item 7, ASC description localization, anything WeChat-port-related) must follow this convention.
- The Accepted status here rests on project-owner direction plus a draft listing-copy file. If a contradicting native-reviewer note ever surfaces, supersede this ADR with a new one rather than editing in place.
- If a WeChat mini-program port (v2.0) happens, start from this glossary instead of re-litigating.
