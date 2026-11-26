extends CanvasLayer
## Credits overlay: team, fonts, art, audio and the Godot licence, in a scrolling
## card that matches the settings card. Keep in sync with docs/CREDITS.md.
## Open it by instancing as a child; it emits `closed` and frees itself.

signal closed

const DIM_ALPHA := 0.7
const SLIDE_OFFSET := 20.0
const ENTRANCE_TIME := 0.2
const SCROLL_STEP := 40

@onready var dim: ColorRect = $Root/Dim
@onready var slide: Control = $Root/Slide
@onready var shadow: Panel = $Root/Slide/Shadow
@onready var card: PanelContainer = $Root/Slide/Card
@onready var scroll: ScrollContainer = $Root/Slide/Card/VBox/Body/BodyVBox/Scroll
@onready var godot_license: Label = $Root/Slide/Card/VBox/Body/BodyVBox/Scroll/Inset/Content/Engine/License
@onready var back_button: Button = $Root/Slide/Card/VBox/Body/BodyVBox/BackButton

var _closing := false


func _ready() -> void:
	# Godot's MIT licence asks for this notice in every shipped game.
	godot_license.text = Engine.get_license_text()
	back_button.pressed.connect(_close)
	# The drop shadow is a separate panel so the card's clip_contents does not cut it off.
	card.item_rect_changed.connect(_sync_shadow)
	_sync_shadow()
	_play_entrance()
	back_button.grab_focus()


## _input, so Up/Down scroll instead of moving focus, and Esc is consumed before
## anything underneath sees it.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close()
	elif event.is_action_pressed("ui_up", true):
		get_viewport().set_input_as_handled()
		scroll.scroll_vertical -= SCROLL_STEP
	elif event.is_action_pressed("ui_down", true):
		get_viewport().set_input_as_handled()
		scroll.scroll_vertical += SCROLL_STEP


## Same entrance as the settings card.
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
