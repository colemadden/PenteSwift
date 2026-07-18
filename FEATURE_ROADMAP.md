# Pente Feature Roadmap

## Market Context
- **2,183 total downloads** (633 in 2025, 1,550 in 2026 YTD)
- **82% from China** (~1,800 downloads)
- Download spikes: Jan 15, Mar 16 — possibly mini-viral on Chinese social media
- 2 reviews: 5-star (USA, wants zoom), 1-star (China, player assignment bug — fixed in v1.1)
- Competitors: Pente Live (iOS/Android/web), Board Game Arena (web), pente.org (web). No Pente on WeChat.

---

## v1.3 — SHIPPED 2026-04-24 (Build 6)

What actually went out: **Simplified Chinese localization** (#2 below) and **Last Move Indicator** (#4 below). Pinch-to-zoom and Sound/Haptics did NOT ship in 1.3 — they have been moved to v1.4 as items 4a and 4b.

### 2. Chinese (Simplified) Localization — In-app ✅ FULLY DONE (v1.3 in-app; ASC listing applied with v1.4 on 2026-07-18)
- **Impact**: Critical — 82% of users read a foreign-language UI
- **China relevance**: Highest possible
- **Status**: Shipped. In-app strings via `Localizable.xcstrings`; native-speaker review completed for v1.3 strings and the ASC listing copy. NOTE (2026-07-18): per ADR-0045, future zh copy is QA'd by multi-LLM consensus, not native review.
- **Remaining work**: none — (a) native review done (v1.3-era), (b) on-device check done, (c) ASC listing localization applied with the v1.4 submission (2026-07-18).
- ~~Bonus TODO: First-launch rules overlay~~ ✅ DONE — shipped in v1.4 as item 7 (ADR-0043)

#### 2a. ASC Listing Localization for zh-Hans ✅ DONE (2026-07-18, applied with the v1.4 submission)

> **Completion note**: subtitle 不止五子棋，更有夹吃, description, keywords, and
> promotional text applied verbatim from `zh-hans-asc-review.txt` via the ASC
> API; zh whatsNew drafted fresh for v1.4 and Codex-consensus-checked (ADR-0045).
> Only skipped step: localized zh screenshots (step 4 below) — the store falls
> back to the en-US screenshots; add zh captures later if conversion warrants.
> The instructions below are retained as historical reference; "decide/tune with
> native reviewer" steps are superseded by ADR-0045.

<details><summary>Original task plan (historical)</summary>


**Context handoff**: The in-app strings for Simplified Chinese are already done and tested. This task is ONLY about the App Store listing itself (what Chinese users see on the App Store before installing). It is deliberately deferred to a separate session because it is administrative / data-entry work, not code, and should happen only once the build is verified on-device.

**Prerequisites before starting this task**:
1. Native-speaker review of `zh-hans-review.txt` has been incorporated.
2. Build has been verified on a physical device in Simplified Chinese.
3. A new build has been uploaded to App Store Connect (TestFlight).

**What to do**:
1. **Add zh-Hans as a supported language** on the app in App Store Connect (if not already present from a prior locale add — check `GET /v1/apps/6748970073/appInfos` → `appInfoLocalizations`).
2. **Create `appInfoLocalization` for locale `zh-Hans`** with:
   - `name` — the app name shown on the store. Options: keep "Pente" as-is, or use a hybrid like `Pente - 五连珠加夹吃` to disambiguate from Gomoku. Decide with native reviewer.
   - `subtitle` — short tagline, 30 char max. Suggested: `独特的夹吃玩法` ("unique capture gameplay") to explicitly differentiate from 五子棋 (Gomoku), which Chinese players will otherwise assume this is.
   - `privacyPolicyUrl` — same as English.
3. **Create `appStoreVersionLocalization` for locale `zh-Hans`** on the current editable version, with:
   - `description` — full store description. Must explain the capture rule prominently since Chinese audience defaults to Gomoku assumptions. English source to translate is in App Store Connect; draft a zh-Hans version that emphasizes "与五子棋不同" (unlike Gomoku) and the capture mechanic.
   - `keywords` — 100 char max, comma-separated. Candidate terms: `五子棋,棋,围棋,对战,双人,策略,夹吃,连珠,Pente,iMessage` (tune with native reviewer; check App Store search volume).
   - `promotionalText` — 170 char max.
   - `whatsNew` — "新增简体中文支持" ("Added Simplified Chinese support") plus any other v1.3 items.
   - `marketingUrl`, `supportUrl` — same as English.
4. **Upload zh-Hans screenshots** (5-6 per device size) to the `appStoreVersionLocalization`. Screens to capture in Chinese: empty board with "轮到黑方" status, mid-game with captures shown, win banner "黑方以夹吃五对获胜！". These can be produced via XcodeBuildMCP `screenshot` after toggling the simulator language to Simplified Chinese.

**API endpoints** (JWT details in `.claude/CLAUDE.md`, API Key `423RCYC29Y`, App ID `6748970073`):
- `GET /v1/apps/6748970073/appInfos` — find editable appInfo
- `POST /v1/appInfoLocalizations` — create zh-Hans appInfo localization (name, subtitle, privacyPolicyUrl)
- `PATCH /v1/appInfoLocalizations/{id}` — update if already exists
- `GET /v1/apps/6748970073/appStoreVersions?filter[appStoreState]=PREPARE_FOR_SUBMISSION` — find editable version
- `POST /v1/appStoreVersionLocalizations` — create zh-Hans version localization (description, keywords, promotionalText, whatsNew, marketingUrl, supportUrl)
- `PATCH /v1/appStoreVersionLocalizations/{id}` — update if already exists
- `POST /v1/appScreenshotSets` + `POST /v1/appScreenshots` + reservation upload flow — attach localized screenshots

**Source strings to translate for the listing** (different from in-app strings — these are marketing copy, not UI text):
| Field | English source (check ASC for current value) | Translation guidance |
|---|---|---|
| name | "Pente" | Likely keep as-is |
| subtitle | (current English subtitle) | Use `独特的夹吃玩法` or similar — must disambiguate from 五子棋 |
| description | (current English description) | Lead with capture mechanic. Avoid implying this is plain Gomoku. |
| keywords | (current English keywords) | Include `五子棋` for discovery but also `夹吃`, `连珠`, `策略` |
| whatsNew | "Added Simplified Chinese support." | `新增简体中文支持。` |

**Validation after upload**:
- `GET /v1/apps/6748970073/appInfoLocalizations` — confirm zh-Hans localization is attached
- `GET /v1/appStoreVersions/{id}/appStoreVersionLocalizations` — confirm zh-Hans version localization is attached with all fields
- Visual check in App Store Connect web UI before submission

**Files**: None in this repo. All work is via ASC API. No code changes needed.

</details>

### 4. Last Move Indicator ✅ DONE (shipped in v1.3, 2026-04-24)
- **Impact**: High — on a 19x19 board, finding the opponent's last move is frustrating
- **Effort**: Very low (~10 lines in Canvas renderer)
- **Implementation**: Draw a colored dot/ring on the most recently placed stone. Use `moveHistory.last` which already exists.
- **Files**: `PenteGameView.swift:247-310` (Canvas stone drawing section)

---

## v1.4 — Engagement & Retention

### 4a. Pinch-to-Zoom + Pan Board ✅ DONE (2026-07-16, ADR-0041)
- **Impact**: Critical — only user-requested feature, 19x19 grid causes mis-taps on small screens
- **China relevance**: High — many users on smaller/lower-end devices
- **Effort**: Medium
- **Implementation**: Wrap `PenteBoardView` Canvas in `MagnificationGesture` + `DragGesture`, clamp min/max scale, adjust tap hit-testing for transforms. Auto-center on last opponent move when opening a game.
- **Files**: `PenteGameView.swift:158-327` (PenteBoardView)
- **Bonus**: Add haptic "snap" feedback when finger is over a valid intersection

### 4b. Haptics (no sound) ✅ DONE (ADR-0034 + ADR-0038 arrival haptic)
- **Impact**: High — game feels like a prototype without tactile feedback
- **China relevance**: High — casual players expect tactile feedback (standard in Tencent games)
- **Effort**: Low (~15 LOC)
- **Decision**: ADR-0034. Three haptics, no sound effects in v1.4.
  - Stone placement: `UIImpactFeedbackGenerator(.medium)` — yours and opponent-arrival animation
  - Capture: `UINotificationFeedbackGenerator(.warning)` — Pente-specific
  - Win: `UINotificationFeedbackGenerator(.success)` — fires on winner's device only
  - Dropped: opponent-arrival haptic (iMessage handles), Send-button-appears haptic (redundant with placement)
  - Sound dropped from v1.4: bundling AAC files would push the binary toward several hundred KB. Reconsider only on explicit user feedback requesting audio.
- **Files**: `PenteGameModel.swift` (capture/win triggers), `PenteGameView.swift` (placement trigger)

### 5. One-Tap Send ✅ DONE (ADR-0029 send ladder + ADR-0037 gameID retry guard)
- **Impact**: High — current flow is two taps across two screens (in-app "Send" → exits to compose → tap iMessage send). GamePigeon Gomoku sends immediately when the in-app Send is tapped.
- **Effort**: Low (~1-line change, plus device testing)
- **Decision**: ADR-0029 (supersedes ADR-0024). Switch to `MSConversation.send(_:)` unconditionally. No `insert` fallback for "edit before sending" — never requested.
- **Files**: `MessagesViewController.swift` (current `conversation.insert(`)
- **Risk**: `send(_:)` historically had presentation-style preconditions `insert` did not. Verify on physical device before merging.

### 6. Winning-Row Gold Ring Highlight ✅ DONE (ADR-0019; live board + thumbnail)
- **Impact**: Medium-High — on a 19×19 board the winning line can be hard to spot. Gold ring on the 5 winning stones makes the win unmistakable.
- **Effort**: Low
- **Decision**: ADR-0019. `WinDetector` returns `[Position]?` for 5-in-a-row wins; capture-wins return nil. View renders gold rings from that array.
- **Files**: `PenteCore/Sources/PenteCore/WinDetector.swift`, `PenteGameModel.swift`, `PenteGameView.swift` Canvas drawing block. Not encoded in URL — recomputable on resume.
- **Tests**: `WinDetector` tests asserting returned coordinates for horizontal / vertical / both diagonals.

### 7. First-Launch Rules / Tutorial Screen ✅ DONE (2026-07-16, ADR-0043; zh strings cleared via ADR-0045 LLM consensus 2026-07-18 — one wording improvement rides v1.4.1)
- **Impact**: High — Pente's capture rule is unique and unexpected. Chinese users coming from Gomoku (五子棋) won't know about it. The 1-star Chinese review ("帮对手下棋，谁懂啊？") and Mehera's capture confusion both stem from players not understanding the rules.
- **China relevance**: Highest — 86% of users likely assume this is Gomoku.
- **Effort**: Low-Medium
- **Implementation**: Show a brief rules overlay on first game launch (or first install). Cover: (1) goal is 5 in a row, (2) you can capture by sandwiching a pair, (3) 5 captures also wins. Could be a few swipeable cards or a single illustrated screen. Persist a "has seen tutorial" flag in UserDefaults. Localize for zh-Hans.
- **Files**: New view in `PenteGameView.swift` or separate `TutorialView.swift`, `PenteGameModel.swift` (flag check)

### 8. Capture Indication on Game Resume ✅ DONE (2026-07-16, ADR-0042 — replay-derived, no lc= param)
- **Impact**: High — real user report: player didn't realize opponent had captured stones when reopening the game. Causes confusion about missing stones.
- **China relevance**: High — Pente's capture mechanic is unfamiliar to Chinese players coming from Gomoku.
- **Effort**: Low-Medium
- **Implementation**: Encode last capture positions in the URL (e.g. `&lc=5,6;5,7`). On game resume, render them as highlighted empty intersections (red circles already exist via `lastCaptures` rendering in Canvas — just need to persist them across message boundary). Check GamePigeon Gomoku for visual reference. No animation needed — static visual indicator of "these stones were just removed" is sufficient. Keep it minimal to avoid bloating bundle size.
- **Files**: `GameStateEncoder.swift` (encode/decode `lc` param), `PenteGameModel.swift` (populate `lastCaptures` on load), `PenteGameView.swift:228-245` (already renders `lastCaptures`)
- **User report**: Mehera (tester) was confused when stones disappeared after opponent's capture move.

### 9. Rematch Flow ✅ DONE (2026-07-16, ADR-0039 — Play Again auto-sends)
- **Impact**: Medium-High — currently "New Game" resets locally without notifying opponent
- **Effort**: Medium
- **Implementation**: Replace "New Game" with "Rematch" button that creates and sends a new `MSMessage` with fresh game state. Add "rematch pending" UI state. Opponent sees a rematch invitation they can accept.
- **Files**: `PenteGameView.swift:131-145` (win state UI), `MessagesViewController.swift:144-181` (message creation)
- **Codex note**: Rival board-game extensions don't offer structured rematch UX — differentiator

### 10. Move History Viewer — DEFERRED to v1.5
- **Impact**: Medium — strategy players (especially in China/Go culture) expect move review
- **Effort**: Medium
- **Implementation**: `moveHistory` array already persisted in model and encoded into URLs. Build a slider/stepper UI to replay moves on a miniature board. Could also export GIF via `BoardImageGenerator`.
- **Files**: `PenteGameModel.swift:7` (moveHistory), `BoardImageGenerator.swift`

### 11. Improved Message Thumbnail — DEFERRED to v1.5 (gold win ring did land in thumbnail via ADR-0019)
- **Impact**: Medium — the thumbnail is the "ad" for continuing the game
- **Effort**: Low
- **Implementation**: Show last move highlighted, move count, player indicator more prominently. Currently 300x300 static board image.
- **Files**: `BoardImageGenerator.swift`, `MessagesViewController.swift:125-141` (createDynamicBoardImage)

### 12. Board Layout Stability Overhaul ✅ SUBSTANTIALLY DONE (ADR-0040 fixed-height single slot)
- **Impact**: Medium-High — board resizes when bottom status area switches between states (e.g. "Your turn" → Undo/Send buttons). Currently mitigated with a hidden ZStack sizing reference, but the root cause is the board using `.aspectRatio(1, contentMode: .fit)` inside a flexible VStack, making it responsive to any height change in sibling views.
- **Effort**: Medium
- **Implementation**: Decouple board size from status area height. Options: (a) lock board to a fixed computed size on first layout via GeometryReader + @State, (b) move status controls to an overlay/sheet so they don't participate in the VStack, (c) switch to a fixed-height status bar with scrollable content for longer states.
- **Files**: `PenteGameView.swift` (entire layout structure)

### 13. Stone Placement Animation ✅ DONE (2026-07-16, ADR-0033)
- **Impact**: Medium — polish/feel; covers placement, undo, opponent arrival, and replay-on-open.
- **Effort**: Medium
- **Decision**: ADR-0033. Hybrid — Canvas keeps rendering all committed stones; one SwiftUI `Circle` overlay handles the single animating stone (~150ms scale-in/out, ease-out). No fly-from-bowl, no dust particles.
- **Files**: `PenteGameView.swift:158-327` (PenteBoardView Canvas) — add overlay sibling.

### 14. Coordinate Labels — REJECTED v1.4 (2026-05-03)
- **Status**: Tried in v1.4 with Go convention (A–T skipping I, rows 19→1, ADR-0036). Looked crowded/ugly on a 19×19 phone board on device review; reverted. Not retrying without a visual mockup first.
- **Original impact assessment**: Low — standard on Pente/Go boards, helps discuss moves

---

## v1.4 — Gomoku Walkthrough Items (added 2026-04-28)

These derive from the GamePigeon Gomoku end-to-end walkthrough. Each is small but ships in the v1.4 batch.

### 18. Tap-Outside-Board to Cancel Pending Stone ✅ DONE (2026-07-16, ADR-0030)
- **Decision**: ADR-0030. Removes the explicit Undo control; tap anywhere outside the board bounds clears `pendingMove` and runs the scale-out animation.
- **Files**: `PenteGameView.swift` (gesture region + state clear).
- **Coordination**: Pinch-to-zoom (item 4a) treats "outside the board" as logical bounds, not viewport bounds.

### 19. Bottom Status Area: Single Slot ✅ DONE (2026-07-16, ADR-0031 + ADR-0040: turn indicator kept, per user)
- **Decision**: ADR-0031. Collapses bottom area to one slot — low-opacity hint text "Place a stone on an empty tile." or the Send button (gold on winning move). Removes the multi-control layout that motivated ADR-0018's hidden sizing reference.
- **Files**: `PenteGameView.swift` bottom-cluster ZStack; new xcstrings entry (en + zh-Hans).
- **Open question**: do we keep an explicit "Your turn" indicator anywhere, or does the green ring on opponent's last move suffice?

### 20. Win/Loss Overlay with "Play Again" ✅ DONE (2026-07-16, ADR-0032)
- **Decision**: ADR-0032. Translucent full-board overlay on game-end with "YOU WON!" / "YOU LOST!" + centered "Play Again" pill. Tap-outside-pill dismisses to reveal final board. "Play Again" wires to the rematch flow (item 9).
- **Files**: `PenteGameView.swift` (overlay), `Localizable.xcstrings` (3 new keys).
- **Capture-win**: same overlay; gold ring (item 6 / ADR-0019) does not apply to capture-wins.

### 21. Sidelined: "Sent ✓ / Waiting…" Overlay Sequence
- **Status**: Sidelined for v1.4 per user direction (2026-04-28). One-tap send (item 5) makes the in-app feedback minimal: blue ring on the just-sent stone clears, and the user sees the iMessage bubble appear. No explicit Sent/Waiting overlays needed.
- **Reconsider** if user feedback indicates the send moment isn't legible enough.

---

## v2.0 — Major Expansion

### 15. Standalone App Mode (Remove iMessage Dependency)
- **Impact**: Very High — most Chinese users use WeChat, not iMessage. iMessage-only is a massive friction point.
- **Effort**: High
- **Implementation**: PenteCore is already a separate Swift Package. Build a standalone app target with online multiplayer via GameKit (Game Center) or invite links. Keep iMessage extension as an additional mode.
- **Rationale**: 1,800 Chinese downloads despite iMessage-only suggests huge latent demand. Removing the iMessage requirement could 5-10x the addressable market.

### 16. AI Opponent (Single Player)
- **Impact**: High for retention — users can't play if no friend responds
- **Effort**: High
- **Implementation**: Alpha-beta pruning on `GameBoard` from PenteCore. Add `.ai` player type. Could offer difficulty levels. Consider "puzzle mode" (solve capture scenarios).
- **Files**: Would need new AI engine in PenteCore, model changes in `PenteGameModel.swift:32-40`

### 17. WeChat Mini Program
- **Impact**: Potentially massive — 1.3B WeChat users, board games are popular
- **Effort**: Very High (separate JavaScript/TypeScript codebase, WeChat SDK)
- **Implementation**: Separate project. Game logic would need to be reimplemented in JS. WeChat has built-in multiplayer infrastructure for mini games.
- **Research needed**: No existing Pente game found on WeChat. Gomoku (五子棋) is common but Pente's capture mechanic is unique. Could be a differentiator.

---

## Research TODOs
- [ ] Investigate Jan 15 and Mar 16 download spikes — check Chinese social media (Xiaohongshu, Bilibili, WeChat) for mentions
- [ ] Research WeChat Mini Program development requirements and costs
- [ ] Analyze Pente Live (main competitor) for feature gaps we can exploit
- [ ] Check App Store search analytics for Chinese keyword opportunities
