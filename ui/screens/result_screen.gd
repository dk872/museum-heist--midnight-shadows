extends CanvasLayer
## Win/lose overlay. Hidden during play; shows itself on game_won / game_lost.

const LOSE_REASONS := {
	"detected": "The guards spotted you and raised the alarm.",
	"caught": "A guard grabbed you red-handed.",
	"debug": "Debug lose key.",
}

@onready var title_label: Label = $Root/Panel/VBox/Title
@onready var subtitle_label: Label = $Root/Panel/VBox/Subtitle
@onready var stats_label: Label = $Root/Panel/VBox/Stats
@onready var next_button: Button = $Root/Panel/VBox/Buttons/NextButton
@onready var restart_button: Button = $Root/Panel/VBox/Buttons/RestartButton
@onready var menu_button: Button = $Root/Panel/VBox/Buttons/MenuButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	GameManager.game_won.connect(_on_game_won)
	GameManager.game_lost.connect(_on_game_lost)
	next_button.pressed.connect(_on_next_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)


func _on_game_won() -> void:
	title_label.text = "Heist complete!"
	title_label.add_theme_color_override("font_color", Color(1, 0.84, 0.3))
	subtitle_label.text = "You escaped with the Eye of the Pharaoh."
	next_button.visible = SceneManager.has_next_level()
	_show()


func _on_game_lost(reason: String) -> void:
	title_label.text = "Caught!"
	title_label.add_theme_color_override("font_color", Color(0.95, 0.25, 0.25))
	subtitle_label.text = LOSE_REASONS.get(reason, "The heist went wrong.")
	next_button.visible = false
	_show()


func _show() -> void:
	stats_label.text = "Time %s  ·  Max detection %d%%" % [
		_format_time(GameManager.level_time),
		roundi(GameManager.max_suspicion),
	]
	visible = true
	if next_button.visible:
		next_button.grab_focus()
	else:
		restart_button.grab_focus()


func _on_next_pressed() -> void:
	visible = false
	SceneManager.next_level()


func _on_restart_pressed() -> void:
	visible = false
	SceneManager.restart_level()


func _on_menu_pressed() -> void:
	visible = false
	SceneManager.go_to_menu()


func _format_time(seconds: float) -> String:
	var total := int(seconds)
	return "%02d:%02d" % [floori(total / 60.0), total % 60]

