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
	player.global_position = Vector2(0, 250)
	await get_tree().physics_frame
	await get_tree().physics_frame
	check(guard.can_see_player(), "Player directly ahead is visible")
	guard.rotation = PI / 2.0
	check(not guard.can_see_player(), "Player behind guard is hidden")
	guard.rotation = -PI / 2.0
	guard._physics_process(0.1)
	check(guard.state == guard.State.INVESTIGATE and guard.suspicion > 0.0, "Detection starts investigation")
	check(guard.velocity.length() > 0.0 and guard.velocity.length() <= guard.investigate_speed, "Guard approaches slowly")
	var remembered_position: Vector2 = guard._last_seen
	player.global_position = Vector2(0, 80)
	await get_tree().physics_frame
	await get_tree().physics_frame
	guard._physics_process(0.1)
	check(guard._last_seen == remembered_position, "Hidden player must not update remembered position")
	check(guard.velocity.length() > 0.0, "Guard continues toward last seen position after losing sight")
	check(guard._search_time == guard.investigate_duration, "Search countdown waits for arrival")
	guard.suspicion = 100.0
	GameManager._physics_process(0.0)
	check(GameManager.state == GameManager.State.LOST, "100 percent causes defeat")
	check(world.get_node("HUD/Root/Result").visible, "HUD displays defeat")
	GameManager.win()
	check(GameManager.state == GameManager.State.LOST, "Final result cannot be overwritten")
	GameManager.reset()
	check(guard.suspicion == 0.0 and guard.state == guard.State.PATROL, "Reset clears AI")
	check(world.get_node("HUD/Root/Detection").value == 0.0, "Reset clears HUD meter")
	guard._scan_delay = 0.0
	var heading: float = guard.rotation
	guard._patrol_with_scan(guard.scan_duration * 0.25)
	check(guard.velocity == Vector2.ZERO and guard._scanning, "Guard stops to scan")
	check(is_equal_approx(guard.rotation, heading - PI / 2.0), "Scan reaches left 90 degrees")
	guard._patrol_with_scan(guard.scan_duration * 0.5)
	check(is_equal_approx(guard.rotation, heading + PI / 2.0), "Scan reaches right 90 degrees")
	guard._patrol_with_scan(guard.scan_duration * 0.25)
	check(not guard._scanning and is_equal_approx(guard.rotation, heading), "Scan finishes facing original direction")
	check(guard._scan_delay >= 5.0 and guard._scan_delay <= 10.0, "Next scan scheduled in 5 to 10 seconds")
	var navigation = world.get_node("Navigation")
	var route: PackedVector2Array = navigation.path_between(Vector2(0, 320), Vector2(0, 40))
	check(route.size() > 2, "Route around column exists")
	var detour := false
	for point in route:
		if absf(point.x) >= 72.0:
			detour = true
	check(detour, "Route gives the column clearance")
	guard.reset_guard()
	guard.global_position = Vector2(0, 320)
	guard.vision_range = 0.0
	guard.investigate_speed = 240.0
	guard._set_interest(Vector2(0, 40), 3, "test")
	var reached := false
	for frame in range(240):
		await get_tree().physics_frame
		guard._physics_process(1.0 / 60.0)
		if guard.global_position.distance_to(Vector2(0, 40)) < 12.0:
			reached = true
			break
	check(reached, "Guard physically walks around column to remembered position")
	guard.vision_range = 280.0
	guard.investigate_speed = 60.0
	guard.reset_guard()
	GameManager.emit_noise(guard.global_position + Vector2(70, 0), 35.0, "footstep")
	check(guard.state == guard.State.PATROL, "Sneaking cannot be heard at 70 px")
	GameManager.emit_noise(guard.global_position + Vector2(70, 0), 150.0, "footstep")
	check(guard.state == guard.State.INVESTIGATE, "Walking can be heard at 70 px")
	GameManager.emit_noise(guard.global_position + Vector2(100, 0), 240.0, "coin")
	check(guard._interest_priority == 2, "Coin takes priority over footsteps")
	guard._next_search_point()
	check(guard._search_step == 1 and guard._last_seen != guard._search_center, "Search explores neighboring points")
	guard._next_search_point()
	guard._next_search_point()
	guard._next_search_point()
	check(guard.state == guard.State.PATROL, "Search eventually returns to patrol")
	var sentry = world.get_node("Sentry")
	sentry.set_physics_process(false)
	sentry.reset_guard()
	var post: Vector2 = sentry.global_position
	GameManager.emit_noise(post + Vector2(80, 0), 240.0, "coin")
	sentry._physics_process(0.1)
	check(sentry.global_position == post and sentry.state == sentry.State.INVESTIGATE, "Sentry investigates noise without abandoning post")
	player._coin_cooldown = 0.0
	player.throw_coin()
	check(player.coins == 2, "Throwing consumes one coin")
	player.throw_coin()
	check(player.coins == 2, "Cooldown prevents immediate repeated throws")
	GameManager.reset()
	check(player.coins == 3, "Reset restores coins")
	GameManager.set_paused(true)
	check(GameManager.state == GameManager.State.PAUSED, "Pause state")
	GameManager.set_paused(false)
	check(GameManager.state == GameManager.State.PLAYING, "Resume state")
	GameManager.on_panel_disabled()
	check(guard.state == guard.State.INVESTIGATE and guard._last_seen == world.get_node("Security Panel").global_position, "Patroller checks disabled panel")
	GameManager.on_artifact_taken()
	check(GameManager.has_artifact and GameManager.current_objective == GameManager.OBJECTIVES["exit"], "Objective progression")
	player.global_position = world.get_node("ExitZone").global_position
	await get_tree().physics_frame
	await get_tree().physics_frame
	check(GameManager.state == GameManager.State.WON, "Victory transition")
	check(world.get_node("HUD/Root/Result").text == "Heist complete!", "Victory HUD")
	print("AI integration failures: ", failures)
	get_tree().quit(1 if failures else 0)
