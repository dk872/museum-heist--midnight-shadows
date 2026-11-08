extends CanvasLayer

@export var message_duration: float = 2.0
@export var message_fade: float = 0.4

@onready var objective_label: Label = $Root/Objective
@onready var message_label: Label = $Root/Message
@onready var result_label: Label = $Root/Result

var _message_tween: Tween


func _ready() -> void:
	GameManager.objective_changed.connect(_on_objective_changed)
	GameManager.message.connect(_on_message)
	GameManager.state_changed.connect(_on_state_changed)
	objective_label.text = GameManager.current_objective
	message_label.modulate.a = 0.0


func _on_objective_changed(text: String) -> void:
	objective_label.text = text


func _on_message(text: String) -> void:
	message_label.text = text
	message_label.modulate.a = 1.0
	if _message_tween:
		_message_tween.kill()
	_message_tween = create_tween()
	_message_tween.tween_interval(message_duration)
	_message_tween.tween_property(message_label, "modulate:a", 0.0, message_fade)


# Temporary until the Game Over / Victory screens exist.
func _on_state_changed(state: GameManager.State) -> void:
	match state:
		GameManager.State.WON:
			_show_result("Heist complete!", Color(1, 0.84, 0.3))
		GameManager.State.LOST:
			_show_result("Caught!", Color(0.95, 0.25, 0.25))
		GameManager.State.PLAYING:
			result_label.visible = false
			objective_label.visible = true


func _show_result(text: String, color: Color) -> void:
	objective_label.visible = false
	message_label.modulate.a = 0.0
	result_label.text = text
	result_label.add_theme_color_override("font_color", color)
	result_label.visible = true
