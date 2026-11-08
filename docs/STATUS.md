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
- No real Game Over / Victory screens yet. The HUD shows a temporary result text; there's no restart button and the game doesn't freeze.
- Detection meter not implemented yet (`suspicion` stays 0).
- Next: end screens + restart, detection meter, pause, main menu, audio.

---

## Guards & AI — Maria

**Done**

**How to use**

**Known issues**

---

## Levels & design — Katya

**Done**

**How to use**

**Known issues**
