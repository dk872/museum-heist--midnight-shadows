extends Node2D
## Level bounds are editable; rebuild after changing static collision geometry.
@export var bounds := Rect2(-640, -480, 1600, 1280)
@export var cell_size: int = 24
var grid := AStarGrid2D.new()
var ready_for_paths := false

func _ready() -> void:
	add_to_group("stealth_navigation")
	await get_tree().physics_frame
	await get_tree().physics_frame
	rebuild()

func rebuild() -> void:
	grid.region = Rect2i(Vector2i(bounds.position / cell_size), Vector2i(bounds.size / cell_size))
	grid.cell_size = Vector2.ONE * cell_size
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	var shape := CircleShape2D.new()
	shape.radius = 23.0
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.collision_mask = 1
	for x in range(grid.region.position.x, grid.region.end.x):
		for y in range(grid.region.position.y, grid.region.end.y):
			var cell := Vector2i(x, y)
			query.transform = Transform2D(0, Vector2(cell) * cell_size)
			grid.set_point_solid(cell, not get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty())
	ready_for_paths = true

func path_between(start: Vector2, target: Vector2) -> PackedVector2Array:
	if not ready_for_paths:
		return PackedVector2Array()
	var a := Vector2i((start / cell_size).round())
	var b := Vector2i((target / cell_size).round())
	if not grid.is_in_boundsv(a) or not grid.is_in_boundsv(b):
		return PackedVector2Array()
	a = _nearest_free(a)
	b = _nearest_free(b)
	if grid.is_point_solid(a) or grid.is_point_solid(b):
		return PackedVector2Array()
	return grid.get_point_path(a, b)

func _nearest_free(cell: Vector2i) -> Vector2i:
	if not grid.is_point_solid(cell):
		return cell
	for radius in range(1, 4):
		for x in range(-radius, radius + 1):
			for y in range(-radius, radius + 1):
				var candidate := cell + Vector2i(x, y)
				if grid.is_in_boundsv(candidate) and not grid.is_point_solid(candidate):
					return candidate
	return cell
