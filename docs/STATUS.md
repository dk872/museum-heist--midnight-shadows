# Status

What's done, how to use it, what's broken. One section per area.
**Rule:** when you merge a PR, update your section in the same PR.

---

## Player & interaction — Dmytro

**Done**

**How to use**

**Known issues**

---

## Game state & UI — Veronika

**Done**
- `GameManager` (autoload, `scripts/game_manager.gd`): game state, signals, win/lose, objectives.
- HUD (`ui/hud/hud.tscn`): current objective (top left), short messages (bottom centre). Instanced in `test_world`. The temporary centre result text is gone.
- `SceneManager` (autoload, `systems/scene_manager.gd`): owns the level list and scene changes — `start_level(id)`, `restart_level()`, `next_level()`/`has_next_level()` (via `LEVEL_ORDER`), `go_to_menu()`.
- Result screen (`ui/screens/result_screen.tscn`): full-screen overlay on win/lose with title, reason, Time / Max detection stats, a working **Restart** button and a **Next level** button (shown on a win only when a next level exists — hidden for now with one level) and a **Main menu** button. Instanced in `test_world` next to the HUD.
- Main menu (`ui/screens/main_menu.tscn`): title + Play + controls hint; now the project's main scene, so F5 starts in the menu. Play starts the first level in `LEVEL_ORDER`. No Quit button — the game targets Web only. Running a level scene directly with F6 still works (GameManager boots into PLAYING).
- `GameManager.enter_menu()`: menu scenes call it in `_ready()`; un-pauses and sets `MENU` so `level_time` stops counting.
- Shared UI theme (`ui/theme/main_theme.tres`, registered as the project theme in `project.godot`): "noir tech" palette (night `#0E1218`, steel panels `#2A3545`, edge `#5B7090`, text `#DCE6F2`, muted `#8A9BB3`, amber `#F5A623`, red `#E5484D`), Barlow for body text, Chakra Petch for titles/captions/buttons (both OFL-licensed, `ui/theme/fonts/`). Applied to menu, HUD, result and pause screens.
- Restyled HUD: OBJECTIVE caption + red marker, DETECTION steel panel with live percentage, TIME and COINS (dots) top right, messages bottom centre with an amber bar. Coin counts are read from the Player node each frame — temporary until Dmytro exposes a coins signal.
- Result screen as a "run report" card (640 px, `ReportCard` theme variation): RUN REPORT header with the level name, a 3 px accent line (amber on a win, red on a loss), centred title ("HEIST COMPLETE" / "COMPROMISED"), dashed separator (1 px `ColorRect` + shader), three stat boxes with sub-lines, faint emblem watermark (`assets/ui/emblem_watermark.svg`, 300 px, clipped by the card) and a scalloped "ticket" bottom edge (`assets/ui/card_bottom.svg` strip under the card; the card style has no bottom border, the strip draws the outline along the curve). Win: TIME / BEST, MAX DETECTION / BEST, COINS USED / OF 3, plus an amber **CLEAN** stamp over the title's right end when max detection stayed under 40 %. Loss: SURVIVED / BEST RUN, PROGRESS (n/3 + steps done), COINS USED; RETRY instead of RESTART, no NEXT. Entrance: dim fade, card fade + 20 px slide, title pop, stamp slam (tweens run with `TWEEN_PAUSE_PROCESS`).
- Best times: `systems/records.gd` (`Records`, static, not an autoload) keeps per-level best time and best max detection in `user://best.cfg` (section = level id, keys `time` / `detection`). The result screen saves on a win and shows a **NEW BEST** tag on the TIME box when the time beats the stored one.
- Main menu art: `assets/ui/menu_background.svg` as a keep-aspect-covered `TextureRect`, a CPU-particle rain layer, a shader vignette, the emblem (`assets/ui/emblem.svg`, 92 px) above the title, and an amber `Polygon2D` beam at the façade window that `main_menu.gd` sweeps −12°…14° over 7 s (ping-pong). Title block sits in the top 400 px, buttons at y 470 so they don't cover the lit window.
- Hold-E progress: a small bar above the display case (`HoldBar` in `display_case.tscn`, script `ui/hold_bar.gd`) that listens to the case's `hold_progress(ratio)` / `hold_cancelled` signals (`scripts/display_case.gd`, Dmytro's file, signals added as agreed in TECH_NOTES). Shown only while holding; hides on cancel, completion and any state change. Reusable: drop the same node under any interactable that emits those signals.
- Objective icon: red hollow circle for the panel objective, amber `emblem_icon.svg` for the case and exit objectives.
- Display case shows `emblem_flat.svg` (~48 px) with a radial amber glow sprite behind it.
- Pause menu (`ui/screens/pause_menu.tscn`): Esc (`ui_cancel`) pauses and shows a 440 px status card built to the mock (`PauseCard` style: gradient body, full 1 px border, 4 px corners, straight bottom, soft shadow) — steel gradient header "PAUSED" + level name with a 1 px line under it, OBJECTIVE row with the HUD's icon rule (red circle for the panel, amber emblem otherwise), TIME / DETECTION / COINS boxes (`StatBoxSmall`, values read once when the card opens), separator, stacked RESUME / RESTART / MAIN MENU (RESUME focused), emblem watermark bottom-right and an `ESC` RESUME key-cap hint at the bottom of the screen. Entrance: dim 0 → 0.7, card fade + slide, 0.2 s (`TWEEN_PAUSE_PROCESS`). Esc again resumes. `process_mode` ALWAYS so it works while the tree is paused; visibility follows `state_changed`, so any pause source shows it. Esc does nothing on the result screen or in the menu. Instanced in `test_world`.
- `ui/ui_dots.gd` (`UiDots`, static): the coin-dot styleboxes (amber dot / hollow ring) and `apply(dots, count)`, used by the HUD and the pause card.

**How to use**
- Player caught → `GameManager.lose("detected")`. Reached the goal → `GameManager.win()`. Only the first call per run counts.
- Show a short notice on screen → `GameManager.show_message("text")`.
- React to the game → connect to signals: `state_changed`, `panel_disabled`, `artifact_taken`, `objective_changed`, `message`, `suspicion_changed`, `game_won`, `game_lost(reason)`.
- Read state → `GameManager.state` (`MENU / PLAYING / PAUSED / WON / LOST`), `has_artifact`, `panel_is_disabled`, `level_time`, `suspicion`.
- Pause → `GameManager.set_paused(true/false)`, not `get_tree().paused`.
- New level → add an instance of `ui/hud/hud.tscn`, `ui/screens/result_screen.tscn` and `ui/screens/pause_menu.tscn`, and add the level to `SceneManager.LEVELS` and `LEVEL_ORDER` (one line each).
- Change scenes / restart → always through `SceneManager` (`restart_level()` etc.), never hardcode scene paths.
- `assets/ui/emblem.svg` must be imported with `svg/scale` = 2 (Import dock → Reimport) or it renders blurry at 92 px.
- Styling UI → use `theme_type_variation` (`TitleLabel`, `HeadingLabel`, `CaptionLabel`, `MutedLabel`, `HintLabel`, `HudLabel`, `StatLabel`, `SteelPanel`, `ReportCard`, `StampPanel`/`StampLabel`, `TagLabel`, `BodyLabel`, `PauseCard`, `StatBoxSmall`, `PauseButton`, `KeyCap`/`KeyLabel`), never per-node `theme_override_*` for fonts/colours.
- Best records → `Records.load_best(level_id)` / `Records.save_if_better(level_id, time, detection)`; only wins are saved. `Records.clear_all()` (debug key **9**) deletes `user://best.cfg`. On the Web build `user://` lives in the browser's IndexedDB, so records persist per browser profile.
- Debug builds: keys **1** panel, **2** artifact, **3** win, **4** lose, **0** restart level, **9** clear best records. Prints every signal to Output.

**Known issues**
- On the Web build, Esc also leaves browser fullscreen; a second key for pause may be needed later.

---

## Guards & AI — Maria

**Done**
- Patrol, vision, distance-based suspicion, last-seen pursuit and local search.
- Instant close-contact defeat at 50 px center distance, blocked by walls and independent of suspicion; tested with defeat HUD and terminal-state protection.
- Fresh audible footsteps redirect ongoing search, including sounds behind the guard; current visual contact still takes priority.
- Speeds: patrol 80, investigation 110, visible-player chase 185 px/s. Suspicion rates unchanged.
- Grid navigation with body clearance around static world collisions.
- Walking/sneaking noise, three Q-key coin distractions and visible sound rings.
- Patroller and sentry roles, panel investigation, status labels and periodic scans.
- HUD suspicion, terminal-state gating and reset integration.

**How to use**
- See `docs/STEALTH_MECHANICS.md`.
- F5 starts the demo; F6 on `tests/ai_integration.tscn` runs regression checks.

**Validation**
- Executed using Godot 4.7.2: integration test reports 0 failures, including rear footsteps during search, quiet footsteps out of range, visual priority and separate movement speeds.
- Physical traversal around the column is tested, along with hearing, distractions, search, sentry behavior, panel reaction, scanning, reset and results.
- Main scene ran headlessly for 600 frames without runtime errors.
- Visual balance and browser performance still require playtesting.

**Limitations**
- Navigation bounds are configured on the Navigation node. Rebuild after changing static geometry; moving obstacles are not replanned automatically.
- Sound uses a reduced radius behind walls, not acoustic pathfinding.

---

## Levels & design — Katya

**Done**

**How to use**

**Known issues**
