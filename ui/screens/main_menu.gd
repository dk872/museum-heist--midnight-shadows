extends Control
## Title screen. Play starts the first level in SceneManager.LEVEL_ORDER.

const BEAM_MIN_DEG := -12.0
const BEAM_MAX_DEG := 14.0
const BEAM_SWEEP_TIME := 7.0
const SETTINGS_SCENE := preload("res://ui/screens/settings.tscn")
const CREDITS_SCENE := preload("res://ui/screens/credits.tscn")

@onready var play_button: Button = $Buttons/PlayButton
@onready var settings_button: Button = $Buttons/SettingsButton
@onready var credits_button: Button = $Buttons/CreditsButton
@onready var beam: Polygon2D = $Beam
@onready var hint: Control = $Hint


func _ready() -> void:
	GameManager.enter_menu()
	play_button.pressed.connect(_on_play_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	play_button.grab_focus()
	_start_beam_sweep()


func _on_play_pressed() -> void:
	SceneManager.start_level(SceneManager.LEVEL_ORDER[0])


## The screen frees itself on close; focus comes back to the button that opened it.
func _on_settings_pressed() -> void:
	_open_overlay(SETTINGS_SCENE, settings_button)


func _on_credits_pressed() -> void:
	_open_overlay(CREDITS_SCENE, credits_button)


## The menu's own key hints are hidden while an overlay is open, so they don't
## collide with the overlay's ESC BACK hint at the bottom of the screen.
func _open_overlay(scene: PackedScene, opener: Button) -> void:
	var overlay := scene.instantiate()
	hint.visible = false
	overlay.closed.connect(_on_overlay_closed.bind(opener))
	add_child(overlay)


func _on_overlay_closed(opener: Button) -> void:
	hint.visible = true
	opener.grab_focus()


func _start_beam_sweep() -> void:
	beam.rotation = deg_to_rad(BEAM_MIN_DEG)
	var tween := create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(beam, "rotation", deg_to_rad(BEAM_MAX_DEG), BEAM_SWEEP_TIME)
	tween.tween_property(beam, "rotation", deg_to_rad(BEAM_MIN_DEG), BEAM_SWEEP_TIME)
