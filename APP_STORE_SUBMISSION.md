# App Store Submission Guide

Operational reference for shipping Pente builds. Pairs with `docs/ARCHITECTURE.md` (architecture) and `.claude/CLAUDE.md` (credentials + ASC API workflow).

## Release History

| Version | Build | Status | Source of status | Key Changes |
|---------|-------|--------|------------------|-------------|
| 1.0 | 1–2 | Released, Aug 2025 | prior revision of this file | Initial release. |
| 1.1 | 3   | Released, Mar 2026 | prior revision of this file | Critical player-assignment fix; dynamic-theme bubble thumbnail; `ITSAppUsesNonExemptEncryption=NO`; new icon set. |
| 1.2 | 5   | Last documented as "In Review" (Apr 2026) | prior revision of this file; not re-verified | PenteCore SwiftPM extraction; one MSSession per game; UI streamlining. |
| 1.3 | 6   | SHIPPED 2026-04-24 | `FEATURE_ROADMAP.md` line 12; project-owner attestation in conversation | Simplified Chinese in-app localization (22 keys); last-move blue/green ring indicator; board layout stability ZStack. |
| 1.4 | 7   | SHIPPED 2026-07-18 (submitted 18:09 UTC, approved + auto-released same day) | ASC API, session 2026-07-18 | GamePigeon-ification (ADRs 0029–0044): one-tap send + failure ladder, haptics, gold win signals, win overlay + auto-rematch, stone animation, pinch-zoom, capture previews/resume, rules card. **zh-Hans ASC listing went live with this version.** Shipped from commit `cffdfba`, tag `v1.4`. |

(The earlier "v1.0 / v1.1 Released" entries originate in this file's pre-rewrite history; ASC has not been re-queried for this update. v1.2's actual disposition between "In Review" and any subsequent state is not recorded in repo. Run `GET /v1/builds?filter[app]=6748970073&sort=-uploadedDate` against ASC for authoritative state.)

### v1.5 (IN PREPARATION — 2026-11-01; absorbs the parked v1.4.1)

**State**: `MARKETING_VERSION = 1.5`, `CURRENT_PROJECT_VERSION = 9` in `project.pbxproj` (uncommitted as of 2026-11-01). ASC `appStoreVersion` **1.5 created** (id `f014f70d-63b3-4219-877b-9355a081b75d`, `PREPARE_FOR_SUBMISSION`, `AFTER_APPROVAL`). en-US screenshots **replaced** in all four sets (iPhone 6.9" ×7, iPad 13" ×4 — `marketing/screenshots/out/`, ADR-0048). zh-Hans still has no screenshot sets (falls back to en-US). **No build uploaded, no What's New set, not submitted.**

**What it contains**:
- Everything from the never-shipped v1.4.1 (tag `v1.4.1-ready`, ADR-0046): load-state hygiene, decode-gated session adoption, per-game single-flight retry, animation/zoom guards, improved zh tutorial capture string.
- iPhone Duo readiness (ADR-0047): built with Xcode 27.1+ so it fills both Duo displays; game stack vertically centered; dim overlays full-bleed.

**To ship**:
1. Commit + push; run both test suites.
2. Archive with Xcode 27.1+ (27.2 on the build Mac), export, upload build 9 per "How to build and submit" below.
3. Attach build 9 to version `f014f70d-…`, set What's New (en + zh; zh QA per ADR-0045), submit.
4. Optional: iPhone Duo screenshots (1398×2034 / 2007×2853) once capturable — they earn the "iPhone Duo" badge; required for 27.1-SDK builds from April 2027.

## How to build and submit

Credentials, API key path, App ID, and full ASC API endpoint reference are in `.claude/CLAUDE.md` (gitignored).

### Build + upload (CLI path, default)

```bash
# Tests first — see CLAUDE.md release checklist for the full sequence
cd PenteCore && swift test
xcodebuild test -project ../Pente.xcodeproj -scheme PenteTests \
  -destination "platform=iOS Simulator,id=EF30FA9D-8D3D-4EC7-9571-C0D01151374E"
cd ..

# Archive
xcodebuild -project Pente.xcodeproj -scheme "Pente MessagesExtension" \
  -archivePath build/Pente.xcarchive archive -allowProvisioningUpdates

# Export IPA
xcodebuild -exportArchive -archivePath build/Pente.xcarchive \
  -exportOptionsPlist ExportOptions.plist -exportPath build/export

# Upload via altool (uses ASC API key under the hood)
xcrun altool --upload-app --type ios --file build/export/Pente.ipa \
  --apiKey 423RCYC29Y --apiIssuer a6c794e7-34a7-412d-8694-a630ed90701c
```

### Build + upload (Xcode GUI fallback)

1. Open `Pente.xcodeproj`.
2. Product > Archive.
3. Organizer > Distribute App > App Store Connect > Upload.

### Submit for review (via ASC API)

After upload completes (build appears via `GET /v1/builds?filter[app]=6748970073&sort=-uploadedDate`):

1. `POST /v1/appStoreVersions` — create version row for the new MARKETING_VERSION.
2. `PATCH /v1/appStoreVersions/{id}/relationships/build` — attach the uploaded build.
3. `PATCH /v1/appStoreVersionLocalizations/{id}` — set "What's New" text per locale.
4. `POST /v1/reviewSubmissions` + `POST /v1/reviewSubmissionItems`, then `PATCH submitted=true`.

`releaseType` defaults to `AFTER_APPROVAL` per ADR-0015 (proposed policy — not enforced by any committed artifact). Set explicitly when creating the version if a different behavior is wanted.

## Pre-submission checklist

See `.claude/CLAUDE.md` §"Release Checklist" for the canonical, automated form. Summary:

1. PenteCore tests green (`cd PenteCore && swift test`).
2. Full simulator suite green (`xcodebuild test -scheme PenteTests`).
3. Version/build numbers bumped in `project.pbxproj` (`MARKETING_VERSION`, `CURRENT_PROJECT_VERSION`).
4. Working tree clean and pushed.
5. Localization coverage verified for any new user-visible strings.
6. Build archive + upload + submit (above).
7. Run `/codex:adversarial-review` on the release.

## What's New text — drafting guidance

Keep concise, user-facing. Cite features, not internal refactors. For zh-Hans, prefer the verb form `夹吃` for the mechanic — see ADR-0028.

v1.3 What's New (draft zh-Hans copy from `zh-hans-asc-review.txt`):

```
• 新增简体中文支持——游戏内所有文字已翻译为中文
• 新增最近一手指示器，用彩色圆环标记上一步落子
• 修复了落子或确认时棋盘短暂缩放的布局问题
```

## After release

- Verify build status: `GET /v1/builds?filter[app]=6748970073&sort=-uploadedDate`.
- Verify review state: `GET /v1/apps/6748970073/reviewSubmissions`.
- Update this file's Release History table with the actual release date.
- Update `FEATURE_ROADMAP.md` to mark shipped items.
- Update `docs/ARCHITECTURE.md` §7.3 if the version-bump table needs a new row.
- Watch ASC for new customer reviews; respond in their language.

## Project metadata

- **Bundle IDs**: `colemadden.Pente` (host), `colemadden.Pente.MessagesExtension`
- **Team ID**: `SB4A7WG2KH`
- **App ID (ASC)**: `6748970073`
- **SKU**: `PenteForIMessage`
- **Vendor Number**: `93577601`
- **Min iOS**: 18.5
