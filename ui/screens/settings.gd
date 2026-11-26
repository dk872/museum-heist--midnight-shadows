extends CanvasLayer
## Settings overlay: three volume sliders and the fullscreen toggle, on a card that
## matches the pause card. Changes apply live and are saved by UserSettings.
## Open it by instancing as a child; it emits `closed` and frees itself.

signal closed

const DIM_ALPHA := 0.7
const SLIDE_OFFSET := 20.0
const ENTRANCE_TIME := 0.2
const CAPTION := &"StatCaptionLabel"
const CAPTION_FOCUSED := &"StatCaptionFocusLabel"

## An opener that already dims the screen (the pause menu) sets this to false
## before add_child, so the background is not dimmed twice.
var show_dim := true

@onready var dim: ColorRect = $Root/Dim
@onready var slide: Control = $Root/Slide
@onready var shadow: Panel = $Root/Slide/Shadow
@onready var card: PanelContainer = $Root/Slide/Card
## UserSettings volume key -> row (children: Caption, Slider, Value).
@onready var rows: Dictionary = {
	"master": $Root/Slide/Card/VBox/Body/BodyVBox/MasterRow,
	"music": $Root/Slide/Card/VBox/Body/BodyVBox/MusicRow,
	"sfx": $Root/Slide/Card/VBox/Body/BodyVBox/EffectsRow,
}
@onready var fullscreen_toggle: Button = $Root/Slide/Card/VBox/Body/BodyVBox/FullscreenRow/Toggle
@onready var back_button: Button = $Root/Slide/Card/VBox/Body/BodyVBox/BackButton
## Played on the SFX bus so the player hears the new Effects level.
@onready var preview: AudioStreamPlayer = $Preview

var _closing := false


func _ready() -> void:
	dim.visible = show_dim
	for key: String in rows:
		var slider := _slider(key)
		slider.set_value_no_signal(roundf(UserSettings.get_volume(key) * 100.0))
		_show_percent(key, slider.value)
		slider.value_changed.connect(_on_volume_changed.bind(key))
		# A slider has no focus frame of its own: its caption lights up instead.
		slider.focus_entered.connect(_set_caption_focused.bind(key, true))
		slider.focus_exited.connect(_set_caption_focused.bind(key, false))
	_slider("sfx").drag_ended.connect(_on_effects_drag_ended)

	# The real window mode, not the saved value: a browser can leave fullscreen by itself.
	fullscreen_toggle.set_pressed_no_signal(UserSettings.window_is_fullscreen())
	_update_toggle_text()
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	back_button.pressed.connect(_close)

	# The drop shadow is a separate panel so the card's clip_contents does not cut it off.
	card.item_rect_changed.connect(_sync_shadow)
	_sync_shadow()
	_play_entrance()
	_slider("master").grab_focus()


## _input, not _unhandled_input, and marked handled: Esc must not reach the pause
## menu underneath, which would resume the game.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()


func _on_volume_changed(value: float, key: String) -> void:
	UserSettings.set_volume(key, value / 100.0)
	_show_percent(key, value)
	# Keyboard and wheel steps preview at once; a mouse drag previews on release.
	if key == "sfx" and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		preview.play()


func _on_effects_drag_ended(value_changed: bool) -> void:
	if value_changed:
		preview.play()


func _on_fullscreen_toggled(on: bool) -> void:
	UserSettings.set_fullscreen(on)
	_update_toggle_text()


func _update_toggle_text() -> void:
	fullscreen_toggle.text = "ON" if fullscreen_toggle.button_pressed else "OFF"


func _show_percent(key: String, value: float) -> void:
	(rows[key].get_node("Value") as Label).text = "%d%%" % roundi(value)


func _set_caption_focused(key: String, focused: bool) -> void:
	(rows[key].get_node("Caption") as Label).theme_type_variation = \
		CAPTION_FOCUSED if focused else CAPTION


func _slider(key: String) -> HSlider:
	return rows[key].get_node("Slider") as HSlider


## Same entrance as the pause card. TWEEN_PAUSE_PROCESS: the tree may be paused.
func _play_entrance() -> void:
	dim.color.a = 0.0
	slide.modulate.a = 0.0
	slide.position.y = SLIDE_OFFSET
	var tween := create_tween().set_parallel(true)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(dim, "color:a", DIM_ALPHA, ENTRANCE_TIME)
	tween.tween_property(slide, "modulate:a", 1.0, ENTRANCE_TIME) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(slide, "position:y", 0.0, ENTRANCE_TIME) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _sync_shadow() -> void:
	shadow.position = card.position
	shadow.size = card.size


func _close() -> void:
	if _closing:
		return
	_closing = true
	closed.emit()
	queue_free()
