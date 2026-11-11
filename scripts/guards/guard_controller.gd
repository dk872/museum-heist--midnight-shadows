extends CharacterBody2D
## Routes are offsets from the spawn position; use unobstructed segments.
enum State { PATROL, INVESTIGATE, ALARM }

@export var patrol_points := PackedVector2Array([Vector2.ZERO, Vector2(260, 0)])
@export var patrol_speed: float = 65.0
@export var vision_range: float = 280.0
@export_range(1, 179) var vision_angle: float = 60.0
@export var detection_near: float = 65.0
@export var detection_far: float = 22.0
@export var suspicion_decay: float = 25.0
@export var investigate_duration: float = 2.0

var state: State = State.PATROL
var suspicion: float = 0.0
var _origin: Vector2
var _initial_rotation: float
var _waypoint: int = 0
var _search_time: float = 0.0
var _last_seen: Vector2
var _player: Node2D
@onready var sight: RayCast2D = $Sight
@onready var cone: Polygon2D = $VisionCone

func _ready() -> void:
	add_to_group("guards")
	_origin = global_position
	_initial_rotation = rotation
	_player = get_tree().get_first_node_in_group("player") as Node2D
	GameManager.run_reset.connect(reset_guard)

func reset_guard() -> void:
	global_position = _origin
	rotation = _initial_rotation
	_waypoint = 0
	suspicion = 0.0
	_search_time = 0.0
	state = State.PATROL
	velocity = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if GameManager.state != GameManager.State.PLAYING:
		velocity = Vector2.ZERO
		return
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
	var visible_player := can_see_player()
	if visible_player:
		_last_seen = _player.global_position
		_search_time = investigate_duration
		state = State.INVESTIGATE
		var proximity := clampf(global_position.distance_to(_last_seen) / vision_range, 0.0, 1.0)
		suspicion = minf(100.0, suspicion + lerpf(detection_near, detection_far, proximity) * delta)
	else:
		suspicion = maxf(0.0, suspicion - suspicion_decay * delta)
	if suspicion >= 100.0:
		state = State.ALARM
	velocity = Vector2.ZERO
	match state:
		State.PATROL:
			_patrol()
		State.INVESTIGATE:
			# Inspect the last known direction without walking through cover.
			if global_position.distance_to(_last_seen) > 1.0:
				look_at(_last_seen)
			if not visible_player:
				_search_time -= delta
				if _search_time <= 0.0 and suspicion <= 0.0:
					state = State.PATROL
	move_and_slide()
	_update_cone()

func _patrol() -> void:
	if patrol_points.is_empty():
		return
	var target := _origin + patrol_points[_waypoint]
	if global_position.distance_to(target) < 6.0:
		_waypoint = (_waypoint + 1) % patrol_points.size()
		target = _origin + patrol_points[_waypoint]
	var direction := global_position.direction_to(target)
	if direction.length_squared() > 0.0:
		rotation = direction.angle()
		velocity = direction * patrol_speed

func can_see_player() -> bool:
	if not is_instance_valid(_player) or vision_range <= 0.0:
		return false
	var offset := _player.global_position - global_position
	if offset.length() > vision_range:
		return false
	if offset.length_squared() > 0.01 and absf(Vector2.RIGHT.rotated(global_rotation).angle_to(offset)) > deg_to_rad(vision_angle * 0.5):
		return false
	sight.target_position = sight.to_local(_player.global_position)
	sight.force_raycast_update()
	return sight.is_colliding() and sight.get_collider() == _player

func _update_cone() -> void:
	var vertices := PackedVector2Array([Vector2.ZERO])
	for index in range(33):
		var angle := deg_to_rad(-vision_angle * 0.5 + vision_angle * index / 32.0)
		sight.target_position = Vector2.from_angle(angle) * vision_range
		sight.force_raycast_update()
		vertices.append(to_local(sight.get_collision_point()) if sight.is_colliding() else sight.target_position)
	cone.polygon = vertices
	cone.color = Color(1.0, 0.25, 0.1, 0.3) if suspicion > 0.0 else Color(1.0, 0.85, 0.2, 0.22)
