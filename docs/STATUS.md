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
- Reusable guard scene, patrol route, Patrol / Investigate / Alarm state machine.
- 60-degree RayCast2D vision; physics obstacles clip both detection and the yellow cone.
- Distance-dependent suspicion, decay, highest-guard aggregation, defeat at 100%.
- HUD detection bar, run reset signal, AI reset and player terminal-state gating.
- One guard and a blocking column in the test world.
- Integration test scene for occlusion, detection, result HUD, reset, pause and objectives.

**How to use**
- See `docs/AI_GUIDE_UK.md` for setup and verification.
- Instance `scenes/characters/guard.tscn`; set patrol_points as offsets from spawn.
- Physics layers: 1 world, 2 player, 3 guards. Vision mask: world + player.

**Known issues**
- Godot was unavailable during implementation: runtime tests have not been executed.
- Routes require clear straight segments. No navigation around obstacles.
- Investigation watches the last seen position, then returns to patrol after suspicion drains.
- Debug 0 resets AI and game flags, not all level objects/player position; reload for a fresh run.

---

## Levels & design — Katya

**Done**

**How to use**

**Known issues**
