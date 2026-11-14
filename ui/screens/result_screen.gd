extends CanvasLayer
## Win/lose overlay, laid out as a "run report" card. Hidden during play; shows itself on
## game_won / game_lost with an entrance animation. Best times live in Records (user://best.cfg).

const COLOR_TEXT := Color(0.863, 0.902, 0.949)
const COLOR_AMBER := Color(0.961, 0.651, 0.137)
const COLOR_RED := Color(0.898, 0.282, 0.302)

const CLEAN_MAX_DETECTION := 40.0   # below this a win gets the CLEAN stamp
# Dim behind the card, from the mock: rgba(8,10,14,.74) on a win, rgba(14,6,8,.78) on a loss.
const DIM_WIN := Color(0.031, 0.039, 0.055, 0.74)
const DIM_LOSS := Color(0.055, 0.024, 0.031, 0.78)
const SLIDE_OFFSET := 20.0
const NO_TIME := "--:--"

const LOSE_REASONS := {
	"detected": "The guards spotted you and raised the alarm.",
	"caught": "A guard grabbed you red-handed.",
	"debug": "Debug lose key.",
}

@onready var dim: ColorRect = $Root/Dim
@onready var slide: Control = $Root/Slide
@onready var shadow: Panel = $Root/Slide/Shadow
@onready var card: VBoxContainer = $Root/Slide/Card
@onready var level_name_label: Label = $Root/Slide/Card/Panel/VBox/Header/HeaderRow/LevelName
@onready var accent: ColorRect = $Root/Slide/Card/Panel/VBox/Accent
@onready var title_label: Label = $Root/Slide/Card/Panel/VBox/Body/BodyVBox/Title
@onready var stamp: PanelContainer = $Root/Slide/Card/Panel/VBox/Body/BodyVBox/Title/Stamp
@onready var subtitle_label: Label = $Root/Slide/Card/Panel/VBox/Body/BodyVBox/Subtitle
@onready var time_caption: Label = $Root/Slide/Card/Panel/VBox/Body/BodyVBox/StatsRow/TimeBox/TimeVBox/TimeCaption
@onready var time_value: Label = $Root/Slide/Card/Panel/VBox/Body/BodyVBox/StatsRow/TimeBox/TimeVBox/TimeValue
@onready var time_sub: Label = $Root/Slide/Card/Panel/VBox/Body/BodyVBox/StatsRow/TimeBox/TimeVBox/TimeSub
@onready var new_best_tag: Label = $Root/Slide/Card/Panel/VBox/Body/BodyVBox/StatsRow/TimeBox/TagAnchor/NewBest
@onready var detection_caption: Label = $Root/Slide/Card/Panel/VBox/Body/BodyVBox/StatsRow/DetectionBox/DetectionVBox/DetectionCaption
@onready var detection_value: Label = $Root/Slide/Card/Panel/VBox/Body/BodyVBox/StatsRow/DetectionBox/DetectionVBox/DetectionValue
@onready var detection_sub: Label = $Root/Slide/Card/Panel/VBox/Body/BodyVBox/StatsRow/DetectionBox/DetectionVBox/DetectionSub
@onready var coins_value: Label = $Root/Slide/Card/Panel/VBox/Body/BodyVBox/StatsRow/CoinsBox/CoinsVBox/CoinsValue
@onready var coins_sub: Label = $Root/Slide/Card/Panel/VBox/Body/BodyVBox/StatsRow/CoinsBox/CoinsVBox/CoinsSub
@onready var next_button: Button = $Root/Slide/Card/Panel/VBox/Body/BodyVBox/ButtonsWrap/Buttons/NextButton
@onready var restart_button: Button = $Root/Slide/Card/Panel/VBox/Body/BodyVBox/ButtonsWrap/Buttons/RestartButton
@onready var menu_button: Button = $Root/Slide/Card/Panel/VBox/Body/BodyVBox/ButtonsWrap/Buttons/MenuButton

var _entrance: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	GameManager.game_won.connect(_on_game_won)
	GameManager.game_lost.connect(_on_game_lost)
	next_button.pressed.connect(_on_next_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	# Scale and rotation tweens turn around the centre; keep the pivot there as layout changes.
	title_label.resized.connect(func() -> void: title_label.pivot_offset = title_label.size / 2.0)
	stamp.resized.connect(func() -> void: stamp.pivot_offset = stamp.size / 2.0)
	# The drop shadow is a separate panel so the card's clip_contents does not cut it off.
	card.item_rect_changed.connect(_sync_shadow)
	_sync_shadow()


func _on_game_won() -> void:
	var best: Dictionary = Records.save_if_better(
		SceneManager.current_level_id, GameManager.level_time, GameManager.max_suspicion)
	dim.color = DIM_WIN
	accent.color = COLOR_AMBER
	title_label.text = "HEIST COMPLETE"
	title_label.add_theme_color_override("font_color", COLOR_TEXT)
	subtitle_label.text = "You escaped with the Eye of the Pharaoh."

	time_caption.text = "TIME"
	time_value.text = _format_time(GameManager.level_time)
	time_sub.text = "BEST %s" % _format_time(best.time)
	new_best_tag.visible = best.new_time

	detection_caption.text = "MAX DETECTION"
	detection_value.text = "%d%%" % roundi(GameManager.max_suspicion)
	detection_value.add_theme_color_override("font_color", COLOR_AMBER)
	detection_sub.text = "BEST %d%%" % roundi(best.detection)

	restart_button.text = "RESTART"
	next_button.visible = SceneManager.has_next_level()
	_show(GameManager.max_suspicion < CLEAN_MAX_DETECTION)


func _on_game_lost(reason: String) -> void:
	var best: Dictionary = Records.load_best(SceneManager.current_level_id)
	dim.color = DIM_LOSS
	accent.color = COLOR_RED
	title_label.text = "COMPROMISED"
	title_label.add_theme_color_override("font_color", COLOR_RED)
	subtitle_label.text = LOSE_REASONS.get(reason, "The heist went wrong.")

	time_caption.text = "SURVIVED"
	time_value.text = _format_time(GameManager.level_time)
	time_sub.text = "BEST RUN %s" % (_format_time(best.time) if best.time >= 0.0 else NO_TIME)
	new_best_tag.visible = false

	var steps: PackedStringArray = []
	if GameManager.panel_is_disabled:
		steps.append("PANEL")
	if GameManager.has_artifact:
		steps.append("CASE")
	detection_caption.text = "PROGRESS"
	detection_value.text = "%d/3" % steps.size()
	detection_value.add_theme_color_override("font_color", COLOR_TEXT)
	detection_sub.text = " · ".join(steps) if not steps.is_empty() else "—"

	restart_button.text = "RETRY"
	next_button.visible = false
	_show(false)


func _show(with_stamp: bool) -> void:
	level_name_label.text = "%s · %s" % [SceneManager.level_name(), _timestamp()]
	coins_value.text = _coins_used()
	coins_sub.text = "OF 3"
	_play_entrance(with_stamp)


## Dim fades in, the card fades and slides up, the title pops, then the stamp (if any)
## slams in. Runs with TWEEN_PAUSE_PROCESS so it also plays while the tree is paused.
func _play_entrance(with_stamp: bool) -> void:
	if _entrance:
		_entrance.kill()
	var dim_alpha := dim.color.a   # set per outcome before _show()
	dim.color.a = 0.0
	slide.modulate.a = 0.0
	slide.position.y = SLIDE_OFFSET
	title_label.scale = Vector2(1.25, 1.25)
	stamp.visible = false
	stamp.scale = Vector2(1.6, 1.6)
	visible = true

	_entrance = create_tween().set_parallel(true)
	_entrance.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_entrance.tween_property(dim, "color:a", dim_alpha, 0.25)
	_entrance.tween_property(slide, "modulate:a", 1.0, 0.25) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_entrance.tween_property(slide, "position:y", 0.0, 0.25) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_entrance.tween_callback(_grab_focus).set_delay(0.25)
	_entrance.tween_property(title_label, "scale", Vector2.ONE, 0.2) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(0.1)
	if with_stamp:
		_entrance.tween_callback(stamp.show).set_delay(0.3)
		_entrance.tween_property(stamp, "scale", Vector2.ONE, 0.25) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(0.3)


func _sync_shadow() -> void:
	shadow.position = card.position
	shadow.size = card.size


func _grab_focus() -> void:
	if not visible:
		return
	if next_button.visible:
		next_button.grab_focus()
	else:
		restart_button.grab_focus()


func _hide() -> void:
	if _entrance:
		_entrance.kill()
	visible = false


# TODO: replace with a GameManager stat once Dmytro exposes a coins signal.
func _coins_used() -> String:
	var player := get_tree().current_scene.get_node_or_null("Player")
	if player == null:
		return "–"
	return str(3 - int(player.coins))


func _on_next_pressed() -> void:
	_hide()
	SceneManager.next_level()


func _on_restart_pressed() -> void:
	_hide()
	SceneManager.restart_level()


func _on_menu_pressed() -> void:
	_hide()
	SceneManager.go_to_menu()


const MONTHS := ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]


func _timestamp() -> String:
	var now := Time.get_datetime_dict_from_system()
	return "%02d %s %02d:%02d" % [now.day, MONTHS[now.month - 1], now.hour, now.minute]


func _format_time(seconds: float) -> String:
	var total := int(seconds)
	return "%02d:%02d" % [floori(total / 60.0), total % 60]
