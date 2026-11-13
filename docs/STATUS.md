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
- Restyled HUD: OBJECTIVE caption + red marker, DETECTION steel panel with live percentage, TIME and COINS (dots) top right, messages bottom centre with an amber bar. Result screen: RUN REPORT header with level name (`SceneManager.level_name()`), three stat boxes (time / max detection / coins used). Coin counts are read from the Player node each frame — temporary until Dmytro exposes a coins signal.
- Pause menu (`ui/screens/pause_menu.tscn`): Esc (`ui_cancel`) pauses with a dim overlay — Resume / Restart / Main menu, Resume focused; Esc again resumes. `process_mode` ALWAYS so it works while the tree is paused; visibility follows `state_changed`, so any pause source shows it. Esc does nothing on the result screen or in the menu. Instanced in `test_world`.

**How to use**
- Player caught → `GameManager.lose("detected")`. Reached the goal → `GameManager.win()`. Only the first call per run counts.
- Show a short notice on screen → `GameManager.show_message("text")`.
- React to the game → connect to signals: `state_changed`, `panel_disabled`, `artifact_taken`, `objective_changed`, `message`, `suspicion_changed`, `game_won`, `game_lost(reason)`.
- Read state → `GameManager.state` (`MENU / PLAYING / PAUSED / WON / LOST`), `has_artifact`, `panel_is_disabled`, `level_time`, `suspicion`.
- Pause → `GameManager.set_paused(true/false)`, not `get_tree().paused`.
- New level → add an instance of `ui/hud/hud.tscn`, `ui/screens/result_screen.tscn` and `ui/screens/pause_menu.tscn`, and add the level to `SceneManager.LEVELS` and `LEVEL_ORDER` (one line each).
- Change scenes / restart → always through `SceneManager` (`restart_level()` etc.), never hardcode scene paths.
- Styling UI → use `theme_type_variation` (`TitleLabel`, `HeadingLabel`, `CaptionLabel`, `MutedLabel`, `HintLabel`, `HudLabel`, `StatLabel`, `SteelPanel`), never per-node `theme_override_*` for fonts/colours.
- Debug builds: keys **1** panel, **2** artifact, **3** win, **4** lose, **0** restart level. Prints every signal to Output.

**Known issues**
- Debug keys (1/2/3/4/0) don't work while paused — GameManager uses the default process mode.
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
