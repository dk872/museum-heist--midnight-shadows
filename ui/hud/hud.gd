extends CanvasLayer

@export var message_duration: float = 2.0
@export var message_fade: float = 0.4

@onready var objective_label: Label = $Root/Objective
@onready var message_label: Label = $Root/Message
@onready var detection_bar: ProgressBar = $Root/Detection

var _message_tween: Tween


func _ready() -> void:
	GameManager.suspicion_changed.connect(_on_suspicion_changed)
	_on_suspicion_changed(GameManager.suspicion)
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


# The ResultScreen overlay shows the result; the HUD only hides its own labels.
func _on_state_changed(state: GameManager.State) -> void:
	match state:
		GameManager.State.WON, GameManager.State.LOST:
			objective_label.visible = false
			message_label.modulate.a = 0.0
		GameManager.State.PLAYING:
			objective_label.visible = true

func _on_suspicion_changed(value: float) -> void:
	detection_bar.value = value
	detection_bar.modulate = Color(1, 0.85, 0.2).lerp(Color(1, 0.2, 0.15), value / 100.0)
