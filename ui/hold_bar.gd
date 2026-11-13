extends ProgressBar
## Progress bar shown above an interactable while the player holds E.
## Listens to the parent's hold_progress / hold_cancelled signals.

func _ready() -> void:
	visible = false
	value = 0.0
	var owner_node := get_parent()
	owner_node.hold_progress.connect(_on_hold_progress)
	owner_node.hold_cancelled.connect(_hide)
	GameManager.state_changed.connect(func(_s): _hide())


func _on_hold_progress(ratio: float) -> void:
	value = ratio
	visible = ratio < 1.0


func _hide() -> void:
	visible = false
	value = 0.0
