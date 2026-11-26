extends ProgressBar
## Progress bar shown above an interactable while the player holds E.
## Listens to the owner's (the interactable scene root's) hold_progress /
## hold_cancelled signals.
## Lives under its own CanvasLayer (follow_viewport_enabled) inside the scene, so it
## still shows when the interactable node itself is hidden. Children of a CanvasLayer
## use canvas coordinates, so the bar places itself from the owner's collision box.

const GAP := 12.0   # between the bar and the top edge of the collision box


func _ready() -> void:
	visible = false
	value = 0.0
	owner.hold_progress.connect(_on_hold_progress)
	owner.hold_cancelled.connect(_hide)
	GameManager.state_changed.connect(func(_s): _hide())
	# Deferred: the level sets the instance's position before we read it.
	_place_above_box.call_deferred()


## Centred above the top edge of owner's CollisionShape2D (a RectangleShape2D).
func _place_above_box() -> void:
	var box := owner.get_node("CollisionShape2D") as CollisionShape2D
	var half_height := (box.shape as RectangleShape2D).size.y / 2.0
	var origin: Vector2 = owner.global_position + box.position
	position = Vector2(origin.x - size.x / 2.0, origin.y - half_height - GAP - size.y)


func _on_hold_progress(ratio: float) -> void:
	value = ratio
	visible = ratio < 1.0


func _hide() -> void:
	visible = false
	value = 0.0
