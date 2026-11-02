# App Store screenshots

Why it's done this way: ADR-0048. Finals live in `out/` (`en` = iPhone 6.9", 1320×2868;
`ipad_en` = iPad 13", 2064×2752). Raw simulator captures live in `raw/`.

## Re-frame (new captions, new language)

Edit the `SLIDES` lists in `compose.py` / `compose_ipad.py`, then from this folder:

```bash
python3 compose.py out/en && python3 compose_ipad.py out/ipad_en
```

Requires Pillow. Fonts are macOS system fonts (New York, SF Pro). For zh-Hans, swap the
headline font for PingFang SC (`/System/Library/Fonts/PingFang.ttc`) — New York has no CJK.

## Re-capture

1. `git apply marketing/screenshots/debug-hook.diff` — DEBUG+simulator-only hook that
   loads a position from `build/shot-state.txt` on activation and on every expand.
   **Revert it before committing** (`git checkout -- "Pente MessagesExtension/MessagesViewController.swift"`
   would also drop real edits, so prefer `git apply -R marketing/screenshots/debug-hook.diff`).
2. Build, install `Pente.app` (not the `.appex`) into an iOS 27.0 simulator that has
   Messages (iPhone 18 Pro Max for 6.9", iPad Pro 13-inch (M5) for 13"), then:
   ```bash
   xcrun simctl status_bar <udid> override --time 9:41 --dataNetwork wifi --wifiMode active --wifiBars 3 --cellularMode active --cellularBars 4 --batteryState discharging --batteryLevel 100
   xcrun simctl ui <udid> appearance light   # or dark
   ```
3. Write a position (below) to `build/shot-state.txt`, open Messages → a conversation →
   `+` → scroll → Pente. Expanding the sheet reloads the file, so later positions only
   need a collapse/expand. After a reinstall, terminate and relaunch Messages
   (it keeps a stale plugin handle).
4. `xcrun simctl io <udid> screenshot raw/<name>.png`.

`__ME__` is replaced with the local participant ID so the local player is Black.

| Raw | Position | Then |
|---|---|---|
| `A_light` / `A_dark` | A | — |
| `B_light` / `B_dark` | A | tap row 6, col 6 → captures (7,7),(8,8) preview |
| `C_light` | C | tap row 9, col 10 → gold five + gold Send |
| `D_light` | C | after C, tap Send → YOU WON! overlay |
| `E_transcript` | — | after D, send from the compose field, collapse the app |
| `rules_light` | A | first launch (fresh install) shows the rules card |

Board tap point (iPhone 18 Pro Max, expanded, points): `x = 25.8 + col·21.58`,
`y = 325.8 + row·21.58`. iPad card: `x = 245 + col·19.05`, `y = 851.8 + row·19.05`.

Position A (mid-game, 1–1 captures, White just captured, Black to move):

```
?moves=B9,9;W12,10;B9,12;W7,7;B12,8;W11,11;B11,10;W6,10;B11,8;W8,11;B8,10;W7,11;B7,12;W8,8;B11,13;W13,9;B10,10;W8,12;B10,7;W9,7;B9,11;W7,10;B6,9;W10,6;B10,8;W12,9;B10,11;W10,9;&current=Black&capB=1&capW=1&state=playing&blackID=__ME__&gid=7B1D3C2A-5E4F-4A6B-9C8D-1E2F3A4B5C6D
```

Position C (A + four moves, 2–2 captures, Black has X X _ X X on row 9):

```
?moves=B9,9;W12,10;B9,12;W7,7;B12,8;W11,11;B11,10;W6,10;B11,8;W8,11;B8,10;W7,11;B7,12;W8,8;B11,13;W13,9;B10,10;W8,12;B10,7;W9,7;B9,11;W7,10;B6,9;W10,6;B10,8;W12,9;B10,11;W10,9;B6,6;W9,13;B9,8;W10,12;&current=Black&capB=2&capW=2&state=playing&blackID=__ME__&gid=7B1D3C2A-5E4F-4A6B-9C8D-1E2F3A4B5C6D
```

## Upload

Display types: `APP_IPHONE_67` + `IMESSAGE_APP_IPHONE_67` (6.9" files), and
`APP_IPAD_PRO_3GEN_129` + `IMESSAGE_APP_IPAD_PRO_3GEN_129` (13" files). Screenshots
attach to an `appStoreVersionLocalization` of an editable version; live versions are locked.
