extends Node2D
## Run: godot --headless --path . res://tests/ai_integration.tscn
var failures: int = 0

func check(condition: bool, label: String) -> void:
	if not condition:
		push_error(label)
		failures += 1

func _ready() -> void:
	GameManager.debug_keys = false
	GameManager.reset()
	var world = load("res://scenes/test_world.tscn").instantiate()
	add_child(world)
	var guard = world.get_node("Guard")
	var player = world.get_node("Player")
	guard.set_physics_process(false)
	player.set_physics_process(false)
	guard.global_position = Vector2(0, 320)
	guard.rotation = -PI / 2.0
	player.global_position = Vector2(0, 30)
	await get_tree().physics_frame
	await get_tree().physics_frame
	check(not guard.can_see_player(), "Outside detection range")
	player.global_position = Vector2(0, 80)
	await get_tree().physics_frame
	await get_tree().physics_frame
	check(not guard.can_see_player(), "Column must occlude the player")
	player.global_position = Vector2(0, 270)
	await get_tree().physics_frame
	await get_tree().physics_frame
	check(guard.can_see_player(), "Player directly ahead is visible")
	guard.rotation = PI / 2.0
	check(not guard.can_see_player(), "Player behind guard is hidden")
	guard.rotation = -PI / 2.0
	guard._physics_process(0.1)
	check(guard.state == guard.State.INVESTIGATE and guard.suspicion > 0.0, "Detection starts investigation")
	guard.suspicion = 100.0
	GameManager._physics_process(0.0)
	check(GameManager.state == GameManager.State.LOST, "100 percent causes defeat")
	check(world.get_node("HUD/Root/Result").visible, "HUD displays defeat")
	GameManager.win()
	check(GameManager.state == GameManager.State.LOST, "Final result cannot be overwritten")
	GameManager.reset()
	check(guard.suspicion == 0.0 and guard.state == guard.State.PATROL, "Reset clears AI")
	check(world.get_node("HUD/Root/Detection").value == 0.0, "Reset clears HUD meter")
	GameManager.set_paused(true)
	check(GameManager.state == GameManager.State.PAUSED, "Pause state")
	GameManager.set_paused(false)
	check(GameManager.state == GameManager.State.PLAYING, "Resume state")
	GameManager.on_panel_disabled()
	GameManager.on_artifact_taken()
	check(GameManager.has_artifact and GameManager.current_objective == GameManager.OBJECTIVES["exit"], "Objective progression")
	GameManager.win()
	check(GameManager.state == GameManager.State.WON, "Victory transition")
	check(world.get_node("HUD/Root/Result").text == "Heist complete!", "Victory HUD")
	print("AI integration failures: ", failures)
	get_tree().quit(1 if failures else 0)
