extends Node2D
## TC-01 autotest: player controller, walls, interaction, coins, case / panel / exit.
## Run: godot --headless --path . res://tests/player_integration.tscn
## Builds its own small world (no guards, no level map), so map changes do not break it.
## Exit code 0 = all checks passed, 1 = at least one failed (see the errors in Output).

const WALL_POS := Vector2(400, 0)
const WALL_SIZE := Vector2(40, 400)
const PANEL_POS := Vector2(0, 1000)
const CASE_POS := Vector2(1000, 1000)
const EXIT_POS := Vector2(-1000, 1000)
const START_POS := Vector2(0, 0)

var failures: int = 0
var checks: int = 0
var _panel_signals: int = 0

var player
var panel
var case
var exit_zone


func check(condition: bool, label: String) -> void:
	checks += 1
	if condition:
		print("PASS: ", label)
	else:
		push_error(label)
		failures += 1


func _ready() -> void:
	GameManager.debug_keys = false
	GameManager.reset()
	_build_world()
	GameManager.panel_disabled.connect(func(): _panel_signals += 1)
	await _settle()

	await _test_speed()
	await _test_wall()
	# From here on the player is moved by hand only: no input, no look_at.
	player.set_physics_process(false)
	player.rotation = 0.0
	player.velocity = Vector2.ZERO
	_test_case_and_panel()
	await _test_interaction_range()
	await _test_walk_away_cancels()
	_test_coins()
	_test_exit()

	print("Player integration: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)


func _build_world() -> void:
	player = load("res://scenes/characters/player.tscn").instantiate()
	player.name = "Player"   # exit_zone.gd checks the body name
	player.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING   # as in test_world.tscn
	add_child(player)
	player.global_position = START_POS

	panel = load("res://scenes/security_panel.tscn").instantiate()
	add_child(panel)
	panel.global_position = PANEL_POS

	case = load("res://scenes/display_case.tscn").instantiate()
	add_child(case)
	case.global_position = CASE_POS

	exit_zone = load("res://scenes/exit_zone.tscn").instantiate()
	add_child(exit_zone)
	exit_zone.global_position = EXIT_POS

	var wall := StaticBody2D.new()
	wall.name = "Wall"
	wall.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = WALL_SIZE
	shape.shape = rect
	wall.add_child(shape)
	add_child(wall)
	wall.global_position = WALL_POS


## Two physics frames: overlaps and positions are up to date after a reposition.
func _settle() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame


func _release_all() -> void:
	for action in ["move_left", "move_right", "move_up", "move_down", "sneak"]:
		Input.action_release(action)


# 1. Speed: walk 200, sneak 100, diagonal normalised to 200.
func _test_speed() -> void:
	player.global_position = START_POS
	Input.action_press("move_right")
	await _settle()
	check(is_equal_approx(player.velocity.length(), player.normal_speed) and is_equal_approx(player.normal_speed, 200.0), "Walking speed is 200 px/s")
	Input.action_press("sneak")
	await _settle()
	check(is_equal_approx(player.velocity.length(), 100.0), "Sneaking (Shift) halves the speed to 100 px/s")
	Input.action_release("sneak")
	Input.action_press("move_down")
	await _settle()
	check(is_equal_approx(player.velocity.length(), 200.0), "Diagonal movement is normalised to 200 px/s")
	_release_all()
	await _settle()
	check(player.velocity == Vector2.ZERO, "Player stops when no movement key is held")


# 2. Wall: holding right into a wall never puts the player inside it.
func _test_wall() -> void:
	var wall_left := WALL_POS.x - WALL_SIZE.x / 2.0
	var radius: float = (player.get_node("CollisionShape2D").shape as CircleShape2D).radius
	player.global_position = Vector2(wall_left - radius - 80.0, 0)
	await _settle()
	var start_x: float = player.global_position.x
	Input.action_press("move_right")
	for frame in range(60):
		await get_tree().physics_frame
	_release_all()
	await _settle()
	check(player.global_position.x > start_x + 40.0, "Player actually walked toward the wall")
	check(player.global_position.x + radius <= wall_left + 1.0, "Wall stops the player at its left edge")


# 3–6. Case locked before the panel, panel once, hold cancelled, hold completed.
func _test_case_and_panel() -> void:
	GameManager.reset()
	case.interact()
	check(not case.is_hacking, "Case is locked while the panel is active")

	_panel_signals = 0
	panel.interact()
	check(GameManager.panel_is_disabled, "Panel interaction disables the panel")
	check(GameManager.current_objective == GameManager.OBJECTIVES["case"], "Objective changes to the display case")
	panel.interact()
	check(_panel_signals == 1 and GameManager.panel_is_disabled, "Second panel interaction changes nothing")

	case.interact()
	check(case.is_hacking, "Case hack starts after the panel is disabled")
	case._process(1.0)
	case.cancel_interact()
	check(not case.is_hacking and case.hack_time == 0.0 and not GameManager.has_artifact, "Releasing early cancels the hack and resets progress")

	case.interact()
	case._process(2.1)
	check(GameManager.has_artifact and not case.is_hacking, "Holding 2 s takes the artifact")
	check(GameManager.current_objective == GameManager.OBJECTIVES["exit"], "Objective changes to the exit")


# 7. Interaction by range: only an overlapping interactable reacts.
func _test_interaction_range() -> void:
	GameManager.reset()
	player.global_position = START_POS
	await _settle()
	player._try_interact(true)
	check(not GameManager.panel_is_disabled, "Interaction far from the panel has no effect")

	# Put the centre of the InteractionArea box (51 px ahead, rotation 0) on the panel's box.
	var reach: Vector2 = player.get_node("InteractionArea/CollisionShape2D").position
	var panel_box: Vector2 = panel.get_node("CollisionShape2D").position
	player.global_position = panel.global_position + panel_box - reach
	await _settle()
	player._try_interact(true)
	check(GameManager.panel_is_disabled, "Interaction in range reaches the panel")
	player.global_position = START_POS
	await _settle()


# TC-01-D1 regression: walking away from the case while holding E cancels the hack.
func _test_walk_away_cancels() -> void:
	GameManager.reset()
	GameManager.on_panel_disabled()
	var reach: Vector2 = player.get_node("InteractionArea/CollisionShape2D").position
	var case_box: Vector2 = case.get_node("CollisionShape2D").position
	player.global_position = case.global_position + case_box - reach
	await _settle()
	player._try_interact(true)
	check(case.is_hacking, "Hold E in range starts the case hack")
	player.global_position = START_POS
	await _settle()
	check(not case.is_hacking and not GameManager.has_artifact, "Walking away while holding E cancels the hack (TC-01-D1)")


# 8–9. Three coins, never negative, refilled by reset.
func _test_coins() -> void:
	GameManager.reset()
	check(player.coins == 3, "Player starts with 3 coins")
	var lowest: int = player.coins
	for i in range(4):
		player._coin_cooldown = 0.0
		player.throw_coin()
		lowest = mini(lowest, player.coins)
	check(player.coins == 0 and lowest >= 0, "Fourth throw does nothing; coins never go negative")
	GameManager.reset()
	check(player.coins == 3, "Reset refills coins to 3 (run_reset)")


# 10. Exit: locked without the artifact, win with it.
func _test_exit() -> void:
	GameManager.reset()
	exit_zone._on_body_entered(player)
	check(GameManager.state == GameManager.State.PLAYING, "Exit without the artifact does not win")
	GameManager.has_artifact = true
	exit_zone._on_body_entered(player)
	check(GameManager.state == GameManager.State.WON, "Exit with the artifact wins")
