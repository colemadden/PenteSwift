# Pente Feature Roadmap

## Market Context
- **2,183 total downloads** (633 in 2025, 1,550 in 2026 YTD)
- **82% from China** (~1,800 downloads)
- Download spikes: Jan 15, Mar 16 — possibly mini-viral on Chinese social media
- 2 reviews: 5-star (USA, wants zoom), 1-star (China, player assignment bug — fixed in v1.1)
- Competitors: Pente Live (iOS/Android/web), Board Game Arena (web), pente.org (web). No Pente on WeChat.

---

## v1.3 — Priority Release (High Impact, Achievable Scope)

### 1. Pinch-to-Zoom + Pan Board
- **Impact**: Critical — only user-requested feature, 19x19 grid causes mis-taps on small screens
- **China relevance**: High — many users on smaller/lower-end devices
- **Effort**: Medium
- **Implementation**: Wrap `PenteBoardView` Canvas in `MagnificationGesture` + `DragGesture`, clamp min/max scale, adjust tap hit-testing for transforms. Auto-center on last opponent move when opening a game.
- **Files**: `PenteGameView.swift:158-327` (PenteBoardView)
- **Bonus**: Add haptic "snap" feedback when finger is over a valid intersection

### 2. Chinese (Simplified) Localization — In-app ✅ DONE (pending native review + ASC listing)
- **Impact**: Critical — 82% of users read a foreign-language UI
- **China relevance**: Highest possible
- **Status**: In-app strings implemented via `Localizable.xcstrings` (22 keys in the extension, 2 in the host app). Full test coverage (258/258 passing). Awaiting native-speaker review (`zh-hans-review.txt` at repo root) and on-device verification before release.
- **Remaining work**: (a) native-speaker review pass on translations, (b) on-device sanity check in Simplified Chinese, (c) **App Store Connect listing localization (separate agent session below)**.
- **Bonus TODO**: First-launch rules overlay explaining captures/five-in-a-row (Pente is less known than Gomoku in China)

#### 2a. ASC Listing Localization for zh-Hans (Separate Agent Session — Do AFTER TestFlight verification)

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

### 3. Sound Effects + Haptics
- **Impact**: High — game feels like a prototype without audio feedback
- **China relevance**: High — casual players expect tactile feedback (standard in Tencent games)
- **Effort**: Low (~20 lines of code)
- **Implementation**:
  - Stone placement: click/clack sound + `UIImpactFeedbackGenerator(.medium)`
  - Capture: satisfying removal sound + `UINotificationFeedbackGenerator(.success)`
  - Win: fanfare/celebration sound
  - Bundle 3-4 small audio files, use `AVAudioPlayer` or `AudioServicesPlaySystemSound`
- **Files**: `PenteGameModel.swift:85-117` (confirmMove), `PenteGameView.swift` (UI triggers)

### 4. Last Move Indicator ✅ DONE (shipped 2026-04-07)
- **Impact**: High — on a 19x19 board, finding the opponent's last move is frustrating
- **Effort**: Very low (~10 lines in Canvas renderer)
- **Implementation**: Draw a colored dot/ring on the most recently placed stone. Use `moveHistory.last` which already exists.
- **Files**: `PenteGameView.swift:247-310` (Canvas stone drawing section)

---

## v1.4 — Engagement & Retention

### 5. Rematch Flow
- **Impact**: Medium-High — currently "New Game" resets locally without notifying opponent
- **Effort**: Medium
- **Implementation**: Replace "New Game" with "Rematch" button that creates and sends a new `MSMessage` with fresh game state. Add "rematch pending" UI state. Opponent sees a rematch invitation they can accept.
- **Files**: `PenteGameView.swift:131-145` (win state UI), `MessagesViewController.swift:144-181` (message creation)
- **Codex note**: Rival board-game extensions don't offer structured rematch UX — differentiator

### 6. Move History Viewer
- **Impact**: Medium — strategy players (especially in China/Go culture) expect move review
- **Effort**: Medium
- **Implementation**: `moveHistory` array already persisted in model and encoded into URLs. Build a slider/stepper UI to replay moves on a miniature board. Could also export GIF via `BoardImageGenerator`.
- **Files**: `PenteGameModel.swift:7` (moveHistory), `BoardImageGenerator.swift`

### 7. Improved Message Thumbnail
- **Impact**: Medium — the thumbnail is the "ad" for continuing the game
- **Effort**: Low
- **Implementation**: Show last move highlighted, move count, player indicator more prominently. Currently 300x300 static board image.
- **Files**: `BoardImageGenerator.swift`, `MessagesViewController.swift:125-141` (createDynamicBoardImage)

### 8. Board Layout Stability Overhaul
- **Impact**: Medium-High — board resizes when bottom status area switches between states (e.g. "Your turn" → Undo/Send buttons). Currently mitigated with a hidden ZStack sizing reference, but the root cause is the board using `.aspectRatio(1, contentMode: .fit)` inside a flexible VStack, making it responsive to any height change in sibling views.
- **Effort**: Medium
- **Implementation**: Decouple board size from status area height. Options: (a) lock board to a fixed computed size on first layout via GeometryReader + @State, (b) move status controls to an overlay/sheet so they don't participate in the VStack, (c) switch to a fixed-height status bar with scrollable content for longer states.
- **Files**: `PenteGameView.swift` (entire layout structure)

### 9. Stone Placement Animation
- **Impact**: Medium — polish/feel
- **Effort**: Medium (Canvas doesn't animate natively)
- **Implementation**: Either switch to individual SwiftUI views per stone, or use timer-based Canvas redraw for a scale-in animation.
- **Files**: `PenteGameView.swift:158-327` (PenteBoardView Canvas)

### 10. Coordinate Labels
- **Impact**: Low — standard on Pente/Go boards, helps discuss moves
- **Effort**: Very low
- **Implementation**: Add A-S column labels, 1-19 row labels on board edges in Canvas renderer.
- **Files**: `PenteGameView.swift:184-207` (grid line drawing section)

---

## v2.0 — Major Expansion

### 11. Standalone App Mode (Remove iMessage Dependency)
- **Impact**: Very High — most Chinese users use WeChat, not iMessage. iMessage-only is a massive friction point.
- **Effort**: High
- **Implementation**: PenteCore is already a separate Swift Package. Build a standalone app target with online multiplayer via GameKit (Game Center) or invite links. Keep iMessage extension as an additional mode.
- **Rationale**: 1,800 Chinese downloads despite iMessage-only suggests huge latent demand. Removing the iMessage requirement could 5-10x the addressable market.

### 12. AI Opponent (Single Player)
- **Impact**: High for retention — users can't play if no friend responds
- **Effort**: High
- **Implementation**: Alpha-beta pruning on `GameBoard` from PenteCore. Add `.ai` player type. Could offer difficulty levels. Consider "puzzle mode" (solve capture scenarios).
- **Files**: Would need new AI engine in PenteCore, model changes in `PenteGameModel.swift:32-40`

### 13. WeChat Mini Program
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
