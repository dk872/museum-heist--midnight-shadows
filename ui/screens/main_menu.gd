extends Control
## Title screen. Play starts the first level in SceneManager.LEVEL_ORDER.

const BEAM_MIN_DEG := -12.0
const BEAM_MAX_DEG := 14.0
const BEAM_SWEEP_TIME := 7.0

@onready var play_button: Button = $Buttons/PlayButton
@onready var beam: Polygon2D = $Beam


func _ready() -> void:
	GameManager.enter_menu()
	play_button.pressed.connect(_on_play_pressed)
	play_button.grab_focus()
	_start_beam_sweep()


func _on_play_pressed() -> void:
	SceneManager.start_level(SceneManager.LEVEL_ORDER[0])


func _start_beam_sweep() -> void:
	beam.rotation = deg_to_rad(BEAM_MIN_DEG)
	var tween := create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(beam, "rotation", deg_to_rad(BEAM_MAX_DEG), BEAM_SWEEP_TIME)
	tween.tween_property(beam, "rotation", deg_to_rad(BEAM_MIN_DEG), BEAM_SWEEP_TIME)
