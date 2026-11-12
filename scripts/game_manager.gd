extends Node
## Global game state. Read the vars, listen to the signals, change state via the functions.

enum State { MENU, PLAYING, PAUSED, WON, LOST }

signal noise_emitted(position: Vector2, radius: float, kind: String)
signal run_reset
signal state_changed(new_state: State)
signal panel_disabled
signal artifact_taken
signal objective_changed(text: String)
signal message(text: String)
signal suspicion_changed(value: float)
signal game_won
signal game_lost(reason: String)

const OBJECTIVES := {
	"panel": "Find the security panel",
	"case": "Open the display case (hold E)",
	"exit": "Escape through the emergency exit",
}

# Debug builds only. Keys: 1 panel, 2 artifact, 3 win, 4 lose, 0 restart level.
var log_signals: bool = true
var debug_keys: bool = true

var state: State = State.PLAYING
var has_artifact: bool = false: set = _set_has_artifact  # setter emits artifact_taken
var panel_is_disabled: bool = false
var level_time: float = 0.0
var suspicion: float = 0.0
var max_suspicion: float = 0.0
var current_objective: String = ""


func _ready() -> void:
	if OS.is_debug_build() and log_signals:
		_connect_debug_log()
	reset()


func _process(delta: float) -> void:
	if state == State.PLAYING:
		level_time += delta


# Each guard owns its suspicion. The HUD displays the highest value, so a
# second guard cannot erase detection accumulated by the first.
func _physics_process(_delta: float) -> void:
	if state != State.PLAYING:
		return
	var value := 0.0
	for guard in get_tree().get_nodes_in_group("guards"):
		value = maxf(value, guard.suspicion)
	if not is_equal_approx(value, suspicion):
		suspicion = value
		max_suspicion = maxf(max_suspicion, suspicion)
		suspicion_changed.emit(suspicion)
	if suspicion >= 100.0:
		lose("detected")


func on_panel_disabled() -> void:
	if panel_is_disabled or state != State.PLAYING:
		return
	panel_is_disabled = true
	panel_disabled.emit()
	_set_objective("case")


func on_artifact_taken() -> void:
	has_artifact = true


func show_message(text: String) -> void:
	if state != State.PLAYING:
		return
	message.emit(text)


func win() -> void:
	if state != State.PLAYING:
		return
	_set_state(State.WON)
	game_won.emit()


func lose(reason: String) -> void:
	if state != State.PLAYING:
		return
	_set_state(State.LOST)
	game_lost.emit(reason)


## Always pause through this, not get_tree().paused, so state stays in sync.
func set_paused(paused: bool) -> void:
	if paused and state == State.PLAYING:
		get_tree().paused = true
		_set_state(State.PAUSED)
	elif not paused and state == State.PAUSED:
		get_tree().paused = false
		_set_state(State.PLAYING)


func reset() -> void:
	get_tree().paused = false
	has_artifact = false
	panel_is_disabled = false
	level_time = 0.0
	suspicion = 0.0
	max_suspicion = 0.0
	_set_state(State.PLAYING)
	suspicion_changed.emit(suspicion)
	_set_objective("panel")
	run_reset.emit()


func _set_has_artifact(value: bool) -> void:
	if value == has_artifact or (value and state != State.PLAYING):
		return
	has_artifact = value
	if value:
		artifact_taken.emit()
		_set_objective("exit")


func _set_state(new_state: State) -> void:
	if new_state == state:
		return
	state = new_state
	state_changed.emit(state)


func _set_objective(key: String) -> void:
	current_objective = OBJECTIVES[key]
	objective_changed.emit(current_objective)


func _unhandled_input(event: InputEvent) -> void:
	if not (OS.is_debug_build() and debug_keys):
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.physical_keycode:
		KEY_1: on_panel_disabled()
		KEY_2: on_artifact_taken()
		KEY_3: win()
		KEY_4: lose("debug")
		KEY_0: SceneManager.restart_level()


func _connect_debug_log() -> void:
	for sig in get_script().get_script_signal_list():
		var sig_name: String = sig.name
		if sig_name == "noise_emitted":
			continue
		if sig.args.is_empty():
			connect(sig_name, func(): print("[GameManager] ", sig_name))
		elif sig_name == "state_changed":
			connect(sig_name, func(s): print("[GameManager] state -> ", State.keys()[s]))
		else:
			connect(sig_name, func(arg): print("[GameManager] ", sig_name, ": ", arg))

func emit_noise(position: Vector2, radius: float, kind: String) -> void:
	if state != State.PLAYING:
		return
	noise_emitted.emit(position, radius, kind)
	var ring := Node2D.new()
	ring.set_script(preload("res://scripts/noise_ring.gd"))
	ring.radius = radius
	ring.coin = kind == "coin"
	get_tree().current_scene.add_child(ring)
	ring.global_position = position
