extends Control
## Title screen. Play starts the first level in SceneManager.LEVEL_ORDER.

@onready var play_button: Button = $Center/VBox/PlayButton


func _ready() -> void:
	GameManager.enter_menu()
	play_button.pressed.connect(_on_play_pressed)
	play_button.grab_focus()


func _on_play_pressed() -> void:
	SceneManager.start_level(SceneManager.LEVEL_ORDER[0])
