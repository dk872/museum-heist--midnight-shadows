extends CanvasLayer
## Win/lose overlay. Hidden during play; shows itself on game_won / game_lost.

const COLOR_TEXT := Color(0.863, 0.902, 0.949)
const COLOR_RED := Color(0.898, 0.282, 0.302)

const LOSE_REASONS := {
	"detected": "The guards spotted you and raised the alarm.",
	"caught": "A guard grabbed you red-handed.",
	"debug": "Debug lose key.",
}

@onready var level_name_label: Label = $Root/Panel/VBox/Header/HeaderRow/LevelName
@onready var title_label: Label = $Root/Panel/VBox/TitleBlock/Title
@onready var subtitle_label: Label = $Root/Panel/VBox/TitleBlock/Subtitle
@onready var time_value: Label = $Root/Panel/VBox/StatsRow/TimeBox/TimeVBox/TimeValue
@onready var detection_value: Label = $Root/Panel/VBox/StatsRow/DetectionBox/DetectionVBox/DetectionValue
@onready var coins_value: Label = $Root/Panel/VBox/StatsRow/CoinsBox/CoinsVBox/CoinsValue
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
	title_label.text = "HEIST COMPLETE"
	title_label.add_theme_color_override("font_color", COLOR_TEXT)
	subtitle_label.text = "You escaped with the Eye of the Pharaoh."
	next_button.visible = SceneManager.has_next_level()
	_show()


func _on_game_lost(reason: String) -> void:
	title_label.text = "HEIST FAILED"
	title_label.add_theme_color_override("font_color", COLOR_RED)
	subtitle_label.text = LOSE_REASONS.get(reason, "The heist went wrong.")
	next_button.visible = false
	_show()


func _show() -> void:
	level_name_label.text = SceneManager.level_name()
	time_value.text = _format_time(GameManager.level_time)
	detection_value.text = "%d%%" % roundi(GameManager.max_suspicion)
	coins_value.text = _coins_used()
	visible = true
	if next_button.visible:
		next_button.grab_focus()
	else:
		restart_button.grab_focus()


# TODO: replace with a GameManager stat once Dmytro exposes a coins signal.
func _coins_used() -> String:
	var player := get_tree().current_scene.get_node_or_null("Player")
	if player == null:
		return "–"
	return str(3 - int(player.coins))


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
