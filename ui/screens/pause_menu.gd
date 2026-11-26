extends CanvasLayer
## Esc overlay, laid out as a status card: objective, time, detection, coins, buttons.
## Visibility follows GameManager.state so any pause source shows it.

const COLOR_AMBER := Color(0.961, 0.651, 0.137)
const DIM_ALPHA := 0.7
const SLIDE_OFFSET := 20.0
const ENTRANCE_TIME := 0.2
const SETTINGS_SCENE := preload("res://ui/screens/settings.tscn")

@onready var dim: ColorRect = $Root/Dim
@onready var slide: Control = $Root/Slide
@onready var shadow: Panel = $Root/Slide/Shadow
@onready var card: PanelContainer = $Root/Slide/Card
@onready var level_name_label: Label = $Root/Slide/Card/VBox/Header/HeaderRow/LevelName
@onready var marker: Panel = $Root/Slide/Card/VBox/Body/BodyVBox/ObjectiveBlock/ObjectiveRow/Marker
@onready var marker_icon: TextureRect = $Root/Slide/Card/VBox/Body/BodyVBox/ObjectiveBlock/ObjectiveRow/MarkerIcon
@onready var objective_label: Label = $Root/Slide/Card/VBox/Body/BodyVBox/ObjectiveBlock/ObjectiveRow/Objective
@onready var time_value: Label = $Root/Slide/Card/VBox/Body/BodyVBox/StatsRow/TimeBox/TimeVBox/TimeValue
@onready var detection_value: Label = $Root/Slide/Card/VBox/Body/BodyVBox/StatsRow/DetectionBox/DetectionVBox/DetectionValue
@onready var coins_row: HBoxContainer = $Root/Slide/Card/VBox/Body/BodyVBox/StatsRow/CoinsBox/CoinsVBox/CoinsRow
@onready var coin_dots: Array[Panel] = [
	$Root/Slide/Card/VBox/Body/BodyVBox/StatsRow/CoinsBox/CoinsVBox/CoinsRow/CoinDot1 as Panel,
	$Root/Slide/Card/VBox/Body/BodyVBox/StatsRow/CoinsBox/CoinsVBox/CoinsRow/CoinDot2 as Panel,
	$Root/Slide/Card/VBox/Body/BodyVBox/StatsRow/CoinsBox/CoinsVBox/CoinsRow/CoinDot3 as Panel,
]
@onready var resume_button: Button = $Root/Slide/Card/VBox/Body/BodyVBox/Buttons/ResumeButton
@onready var restart_button: Button = $Root/Slide/Card/VBox/Body/BodyVBox/Buttons/RestartButton
@onready var settings_button: Button = $Root/Slide/Card/VBox/Body/BodyVBox/Buttons/SettingsButton
@onready var menu_button: Button = $Root/Slide/Card/VBox/Body/BodyVBox/Buttons/MenuButton

var _entrance: Tween


func _ready() -> void:
	visible = false
	detection_value.add_theme_color_override("font_color", COLOR_AMBER)
	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	GameManager.state_changed.connect(_on_state_changed)
	# The drop shadow is a separate panel so the card's clip_contents does not cut it off.
	card.item_rect_changed.connect(_sync_shadow)
	_sync_shadow()


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
	if state == GameManager.State.PAUSED:
		_fill_values()
		_play_entrance()
	else:
		_hide()


## Values are read once when the menu opens: nothing changes while the tree is paused.
func _fill_values() -> void:
	level_name_label.text = SceneManager.level_name()
	var objective := GameManager.current_objective
	objective_label.text = objective
	var is_panel := objective == GameManager.OBJECTIVES["panel"]
	marker.visible = is_panel
	marker_icon.visible = not is_panel
	time_value.text = _format_time(GameManager.level_time)
	detection_value.text = "%d%%" % roundi(GameManager.suspicion)
	# TODO: replace with a GameManager stat once Dmytro exposes a coins signal.
	var player := get_tree().current_scene.get_node_or_null("Player")
	coins_row.visible = player != null
	if player != null:
		UiDots.apply(coin_dots, int(player.coins))


## Dim (rgba(8,10,14,.7) in the mock) and card fade in, the card slides up 20 px. TWEEN_PAUSE_PROCESS: the tree is paused here.
func _play_entrance() -> void:
	if _entrance:
		_entrance.kill()
	dim.color.a = 0.0
	slide.modulate.a = 0.0
	slide.position.y = SLIDE_OFFSET
	slide.visible = true
	visible = true
	resume_button.grab_focus()
	_entrance = create_tween().set_parallel(true)
	_entrance.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_entrance.tween_property(dim, "color:a", DIM_ALPHA, ENTRANCE_TIME)
	_entrance.tween_property(slide, "modulate:a", 1.0, ENTRANCE_TIME) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_entrance.tween_property(slide, "position:y", 0.0, ENTRANCE_TIME) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _sync_shadow() -> void:
	shadow.position = card.position
	shadow.size = card.size


func _hide() -> void:
	if _entrance:
		_entrance.kill()
	visible = false


func _on_resume_pressed() -> void:
	GameManager.set_paused(false)


func _on_restart_pressed() -> void:
	SceneManager.restart_level()


## Settings replaces the card while it is open; the game stays paused and this
## menu's dim stays up, so the settings screen is told not to add its own.
func _on_settings_pressed() -> void:
	slide.visible = false
	var settings := SETTINGS_SCENE.instantiate()
	settings.show_dim = false
	settings.closed.connect(_on_settings_closed)
	add_child(settings)


func _on_settings_closed() -> void:
	slide.visible = true
	settings_button.grab_focus()


func _on_menu_pressed() -> void:
	SceneManager.go_to_menu()


func _format_time(seconds: float) -> String:
	var total := int(seconds)
	return "%02d:%02d" % [floori(total / 60.0), total % 60]
