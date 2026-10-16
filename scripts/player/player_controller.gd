extends CharacterBody2D

@export var normal_speed: float = 200.0
@export var sneak_speed: float = 100.0

# Get a reference to our interaction area
@onready var interaction_area = $InteractionArea

func _physics_process(_delta: float) -> void:
	look_at(get_global_mouse_position())

	var current_speed = normal_speed
	if Input.is_action_pressed("sneak"):
		current_speed = sneak_speed

	var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_direction * current_speed
	move_and_slide()

# Using _unhandled_input for single presses (so it doesn't trigger 60 times a second)
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_try_interact(true) # Button pressed
	elif event.is_action_released("interact"):
		_try_interact(false) # Button released

func _try_interact(is_pressed: bool) -> void:
	var overlapping_areas = interaction_area.get_overlapping_areas()
	for area in overlapping_areas:
		if area.is_in_group("interactable"):
			# If pressed and the interact method exists
			if is_pressed and area.has_method("interact"):
				area.interact()
			# If released and the cancel_interact method exists
			elif not is_pressed and area.has_method("cancel_interact"):
				area.cancel_interact()
			break
