extends CharacterBody2D
## Route offsets are relative to spawn. World navigation handles static obstacles.
enum State { PATROL, INVESTIGATE, ALARM }
enum Role { PATROLLER, SENTRY }
@export var role: Role = Role.PATROLLER
@export var predictable_scans: bool = true
var _nav: Node
var _path := PackedVector2Array()
var _path_target := Vector2.INF
var _path_timer: float = 0.0
var _search_step: int = 0
var _search_center: Vector2
var _interest_priority: int = 0
var _notice: Label
var _notice_time: float = 0.0
var _last_visible: bool = false

@export var patrol_points := PackedVector2Array([Vector2.ZERO, Vector2(260, 0)])
@export var patrol_speed: float = 80.0
@export var investigate_speed: float = 60.0
@export var approach_distance: float = 55.0
@export var vision_range: float = 280.0
@export_range(1, 179) var vision_angle: float = 60.0
@export var detection_near: float = 65.0
@export var detection_far: float = 22.0
@export var suspicion_decay: float = 25.0
@export var investigate_duration: float = 2.0
@export_range(0.5, 10.0) var scan_duration: float = 4.0

var _scan_delay: float = 0.0
var _scanning: bool = false
var _scan_elapsed: float = 0.0
var _scan_heading: float = 0.0
var _blocked_time: float = 0.0

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
	_schedule_scan()
	GameManager.noise_emitted.connect(_hear_noise)
	GameManager.panel_disabled.connect(_check_panel)
	_notice = Label.new()
	_notice.top_level = true
	_notice.add_theme_color_override("font_color", Color(1, 0.85, 0.25))
	_notice.add_theme_color_override("font_outline_color", Color.BLACK)
	_notice.add_theme_constant_override("outline_size", 5)
	add_child(_notice)

func reset_guard() -> void:
	global_position = _origin
	rotation = _initial_rotation
	_waypoint = 0
	suspicion = 0.0
	_search_time = 0.0
	state = State.PATROL
	velocity = Vector2.ZERO
	_blocked_time = 0.0
	_scanning = false
	_scan_elapsed = 0.0
	_schedule_scan()
	_path.clear()
	_path_target = Vector2.INF
	_interest_priority = 0
	_search_step = 0
	_last_visible = false
	if is_instance_valid(_notice):
		_notice.text = ""

func _physics_process(delta: float) -> void:
	if GameManager.state != GameManager.State.PLAYING:
		velocity = Vector2.ZERO
		return
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
	_path_timer -= delta
	_notice_time -= delta
	var visible_player := can_see_player()
	_last_visible = visible_player
	if visible_player:
		if _scanning:
			_scanning = false
			_schedule_scan()
		_blocked_time = 0.0
		_interest_priority = 3
		_search_step = 0
		_last_seen = _player.global_position
		_search_center = _last_seen
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
			_patrol_with_scan(delta)
		State.INVESTIGATE:
			# Memory is updated only by actual line of sight, never through cover.
			var distance := global_position.distance_to(_last_seen)
			var stop_distance := approach_distance if visible_player else 6.0
			if distance > 1.0:
				look_at(_last_seen)
			if role == Role.SENTRY and _interest_priority < 3:
				_search_time -= delta
				if _search_time <= 0.0:
					_finish_search()
			elif distance > stop_distance and _blocked_time < 2.0:
				_move_toward(_last_seen, investigate_speed, delta, stop_distance)
			elif not visible_player:
				# Search time starts on arrival, not when the player disappears.
				_search_time -= delta
				rotation += delta * 0.7
				if _search_time <= 0.0 and suspicion <= 0.0:
					_next_search_point()
	var previous_position := global_position
	var intended_speed := velocity.length()
	move_and_slide()
	if state == State.INVESTIGATE and not visible_player and intended_speed > 0.0:
		if global_position.distance_to(previous_position) < intended_speed * delta * 0.1:
			_blocked_time += delta
		else:
			_blocked_time = 0.0
	_update_cone()
	_notice.global_position = global_position + Vector2(-35, -55)
	if visible_player:
		_notice.text = "! Spotted"
	elif _notice_time <= 0.0:
		_notice.text = "? Searching" if state == State.INVESTIGATE else ("Looking..." if _scanning else ("Sentry" if role == Role.SENTRY else ""))

func _schedule_scan() -> void:
	_scan_delay = 7.0 if predictable_scans else randf_range(5.0, 10.0)

func _patrol_with_scan(delta: float) -> void:
	if not _scanning:
		_scan_delay -= delta
		if _scan_delay > 0.0:
			_patrol()
			return
		_scanning = true
		_scan_elapsed = 0.0
		_scan_heading = rotation
	velocity = Vector2.ZERO
	_scan_elapsed += delta
	var progress := clampf(_scan_elapsed / scan_duration, 0.0, 1.0)
	# Forward -> left 90 degrees -> right 90 degrees -> forward.
	# Constant angular speed, no instant turn at the beginning or end.
	var offset: float
	if progress < 0.25:
		offset = lerpf(0.0, -PI / 2.0, progress * 4.0)
	elif progress < 0.75:
		offset = lerpf(-PI / 2.0, PI / 2.0, (progress - 0.25) * 2.0)
	else:
		offset = lerpf(PI / 2.0, 0.0, (progress - 0.75) * 4.0)
	rotation = _scan_heading + offset
	if progress >= 1.0:
		_scanning = false
		_schedule_scan()

func _patrol() -> void:
	if role == Role.SENTRY:
		if global_position.distance_to(_origin) > 6.0:
			_move_toward(_origin, patrol_speed, get_physics_process_delta_time())
		else:
			rotation = rotate_toward(rotation, _initial_rotation, 0.04)
		return
	if patrol_points.is_empty():
		return
	var target := _origin + patrol_points[_waypoint]
	if global_position.distance_to(target) < 6.0:
		_waypoint = (_waypoint + 1) % patrol_points.size()
		target = _origin + patrol_points[_waypoint]
	_move_toward(target, patrol_speed, get_physics_process_delta_time())

func _move_toward(target: Vector2, speed: float, delta: float, tolerance: float = 6.0) -> void:
	if global_position.distance_to(target) <= tolerance:
		return
	if not is_instance_valid(_nav):
		_nav = get_tree().get_first_node_in_group("stealth_navigation")
	if not is_instance_valid(_nav) or not _nav.ready_for_paths:
		return
	if _path_timer <= 0.0 or _path_target.distance_to(target) > 24.0:
		_path = _nav.path_between(global_position, target)
		_path_target = target
		_path_timer = 0.5
		if _path.size() > 1:
			_path.remove_at(0)
	while not _path.is_empty() and global_position.distance_to(_path[0]) < 6.0:
		_path.remove_at(0)
	var destination := target
	if not _path.is_empty():
		destination = _path[0]
	elif global_position.distance_to(target) > 24.0:
		_blocked_time += delta
		return
	var direction := global_position.direction_to(destination)
	rotation = direction.angle()
	velocity = direction * minf(speed, global_position.distance_to(destination) / maxf(delta, 0.001))

func _hear_noise(position: Vector2, radius: float, kind: String) -> void:
	if GameManager.state != GameManager.State.PLAYING or global_position.distance_to(position) > radius:
		return
	var query := PhysicsRayQueryParameters2D.create(global_position, position, 1)
	if not get_world_2d().direct_space_state.intersect_ray(query).is_empty() and global_position.distance_to(position) > radius * 0.5:
		return
	_set_interest(position, 2 if kind == "coin" else 1, "? Coin!" if kind == "coin" else "? Footsteps")

func _check_panel() -> void:
	if role != Role.PATROLLER:
		return
	var panel := get_tree().current_scene.find_child("Security Panel", true, false) as Node2D
	if panel:
		_set_interest(panel.global_position, 2, "? Power off!")

func _set_interest(position: Vector2, priority: int, text: String) -> void:
	if _last_visible or priority < _interest_priority:
		return
	state = State.INVESTIGATE
	_interest_priority = priority
	_last_seen = position
	_search_center = position
	_search_step = 0
	_search_time = investigate_duration
	_blocked_time = 0.0
	_scanning = false
	_path_timer = 0.0
	_notice.text = text
	_notice_time = 1.5

func _next_search_point() -> void:
	_search_step += 1
	if _search_step > 3:
		_finish_search()
		return
	_last_seen = _search_center + Vector2.from_angle(_search_step * TAU / 3.0) * 72.0
	_search_time = investigate_duration
	_blocked_time = 0.0
	_path_timer = 0.0

func _finish_search() -> void:
	state = State.PATROL
	_interest_priority = 0
	_blocked_time = 0.0
	_path_timer = 0.0
	_schedule_scan()

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
