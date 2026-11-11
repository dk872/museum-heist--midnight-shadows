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
- HUD (`ui/hud/hud.tscn`): current objective (top left), short messages (bottom centre) and a temporary result text ("Heist complete!" / "Caught!") in the centre. Instanced in `test_world`.

**How to use**
- Player caught → `GameManager.lose("detected")`. Reached the goal → `GameManager.win()`. Only the first call per run counts.
- Show a short notice on screen → `GameManager.show_message("text")`.
- React to the game → connect to signals: `state_changed`, `panel_disabled`, `artifact_taken`, `objective_changed`, `message`, `suspicion_changed`, `game_won`, `game_lost(reason)`.
- Read state → `GameManager.state` (`MENU / PLAYING / PAUSED / WON / LOST`), `has_artifact`, `panel_is_disabled`, `level_time`, `suspicion`.
- Pause → `GameManager.set_paused(true/false)`, not `get_tree().paused`.
- New level → add an instance of `ui/hud/hud.tscn`.
- Debug builds: keys **1** panel, **2** artifact, **3** win, **4** lose, **0** reset. Prints every signal to Output.

**Known issues / next**
- No real Game Over / Victory screens yet. The HUD shows a temporary result text; there's no restart button. Player and guards now stop after a result.
- Detection meter and AI suspicion integration added by Maria; runtime verification pending.
- Next: end screens + restart, detection meter, pause, main menu, audio.

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
- Debug 0 resets flags/AI/coins, not the entire level; F8/F5 gives a fresh run.

---

## Levels & design — Katya

**Done**

**How to use**

**Known issues**
