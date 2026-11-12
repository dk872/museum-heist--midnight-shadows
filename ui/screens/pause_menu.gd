extends CanvasLayer
## Esc overlay. Visibility follows GameManager.state so any pause source shows it.

@onready var resume_button: Button = $Root/Panel/Margin/VBox/ResumeButton
@onready var restart_button: Button = $Root/Panel/Margin/VBox/RestartButton
@onready var menu_button: Button = $Root/Panel/Margin/VBox/MenuButton


func _ready() -> void:
	visible = false
	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	GameManager.state_changed.connect(_on_state_changed)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if GameManager.state == GameManager.State.PLAYING:
		GameManager.set_paused(true)
		get_viewport().set_input_as_handled()
	elif GameManager.state == GameManager.State.PAUSED:
		GameManager.set_paused(false)
		get_viewport().set_input_as_handled()


func _on_state_changed(state: GameManager.State) -> void:
	visible = state == GameManager.State.PAUSED
	if visible:
		resume_button.grab_focus()


func _on_resume_pressed() -> void:
	GameManager.set_paused(false)


func _on_restart_pressed() -> void:
	SceneManager.restart_level()


func _on_menu_pressed() -> void:
	SceneManager.go_to_menu()
