extends CanvasLayer

const AMBER := Color(0.961, 0.651, 0.137)
const EDGE := Color(0.357, 0.439, 0.565)

@export var message_duration: float = 2.0
@export var message_fade: float = 0.4

@onready var objective_label: Label = $Root/TopLeft/ObjectiveRow/Objective
@onready var marker: Panel = $Root/TopLeft/ObjectiveRow/Marker
@onready var marker_icon: TextureRect = $Root/TopLeft/ObjectiveRow/MarkerIcon
@onready var top_left: VBoxContainer = $Root/TopLeft
@onready var top_right: VBoxContainer = $Root/TopRight
@onready var message_panel: Panel = $Root/MessagePanel
@onready var message_label: Label = $Root/MessagePanel/Message
@onready var detection_bar: ProgressBar = $Root/TopLeft/DetectionRow/Detection
@onready var detection_percent: Label = $Root/TopLeft/DetectionRow/DetectionPercent
@onready var time_value: Label = $Root/TopRight/TimeRow/TimeValue
@onready var coins_row: HBoxContainer = $Root/TopRight/CoinsRow
@onready var coin_dots: Array[Panel] = [
	$Root/TopRight/CoinsRow/CoinDot1 as Panel,
	$Root/TopRight/CoinsRow/CoinDot2 as Panel,
	$Root/TopRight/CoinsRow/CoinDot3 as Panel,
]

var _message_tween: Tween
var _dot_full: StyleBoxFlat
var _dot_empty: StyleBoxFlat


func _ready() -> void:
	_make_dot_styles()
	GameManager.suspicion_changed.connect(_on_suspicion_changed)
	_on_suspicion_changed(GameManager.suspicion)
	GameManager.objective_changed.connect(_on_objective_changed)
	GameManager.message.connect(_on_message)
	GameManager.state_changed.connect(_on_state_changed)
	_on_objective_changed(GameManager.current_objective)
	message_panel.modulate.a = 0.0


func _process(_delta: float) -> void:
	if GameManager.state != GameManager.State.PLAYING:
		return
	time_value.text = _format_time(GameManager.level_time)
	_update_coins()


func _on_objective_changed(text: String) -> void:
	objective_label.text = text
	var is_panel := text == GameManager.OBJECTIVES["panel"]
	marker.visible = is_panel
	marker_icon.visible = not is_panel


func _on_message(text: String) -> void:
	message_label.text = text
	message_panel.modulate.a = 1.0
	if _message_tween:
		_message_tween.kill()
	_message_tween = create_tween()
	_message_tween.tween_interval(message_duration)
	_message_tween.tween_property(message_panel, "modulate:a", 0.0, message_fade)


# The ResultScreen overlay shows the result; the HUD only hides its own blocks.
func _on_state_changed(state: GameManager.State) -> void:
	match state:
		GameManager.State.WON, GameManager.State.LOST:
			top_left.visible = false
			top_right.visible = false
			message_panel.modulate.a = 0.0
		GameManager.State.PLAYING:
			top_left.visible = true
			top_right.visible = true


func _on_suspicion_changed(value: float) -> void:
	detection_bar.value = value
	detection_bar.modulate = Color(1, 0.85, 0.2).lerp(Color(1, 0.2, 0.15), value / 100.0)
	detection_percent.text = "%d%%" % roundi(value)


# TODO: replace with a GameManager stat once Dmytro exposes a coins signal.
func _update_coins() -> void:
	var player := get_tree().current_scene.get_node_or_null("Player")
	coins_row.visible = player != null
	if player == null:
		return
	var coins := int(player.coins)
	for i in coin_dots.size():
		coin_dots[i].add_theme_stylebox_override("panel", _dot_full if i < coins else _dot_empty)



func _make_dot_styles() -> void:
	_dot_full = StyleBoxFlat.new()
	_dot_full.bg_color = AMBER
	_dot_full.set_corner_radius_all(6)
	_dot_empty = StyleBoxFlat.new()
	_dot_empty.draw_center = false
	_dot_empty.border_color = EDGE
	_dot_empty.set_border_width_all(2)
	_dot_empty.set_corner_radius_all(6)


func _format_time(seconds: float) -> String:
	var total := int(seconds)
	return "%02d:%02d" % [floori(total / 60.0), total % 60]
