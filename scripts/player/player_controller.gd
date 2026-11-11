extends CharacterBody2D

@export var normal_speed: float = 200.0
@export var sneak_speed: float = 100.0

var coins: int = 3
var _footstep_time: float = 0.0
var _coin_cooldown: float = 0.0

func _ready() -> void:
	GameManager.run_reset.connect(func(): coins = 3)

# Get a reference to our interaction area
@onready var interaction_area = $InteractionArea

func _physics_process(delta: float) -> void:
	if GameManager.state != GameManager.State.PLAYING:
		velocity = Vector2.ZERO
		return
	look_at(get_global_mouse_position())

	var current_speed = normal_speed
	if Input.is_action_pressed("sneak"):
		current_speed = sneak_speed

	var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_direction * current_speed
	var previous_position := global_position
	move_and_slide()
	_coin_cooldown = maxf(0.0, _coin_cooldown - delta)
	if global_position.distance_to(previous_position) > 0.1:
		_footstep_time -= delta
		if _footstep_time <= 0.0:
			_footstep_time = 0.45
			GameManager.emit_noise(global_position, 35.0 if Input.is_action_pressed("sneak") else 150.0, "footstep")
	else:
		_footstep_time = 0.0

# Using _unhandled_input for single presses (so it doesn't trigger 60 times a second)
func _unhandled_input(event: InputEvent) -> void:
	if GameManager.state != GameManager.State.PLAYING:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_Q:
		throw_coin()
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

func throw_coin() -> void:
	if GameManager.state != GameManager.State.PLAYING or _coin_cooldown > 0.0:
		return
	if coins <= 0:
		GameManager.show_message("No coins left")
		return
	var target := global_position + (get_global_mouse_position() - global_position).limit_length(260.0)
	var query := PhysicsRayQueryParameters2D.create(global_position, target, 1)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		target = hit.position + hit.normal * 28.0
	coins -= 1
	_coin_cooldown = 0.6
	GameManager.emit_noise(target, 240.0, "coin")
	GameManager.show_message("Coins left: %d" % coins)
