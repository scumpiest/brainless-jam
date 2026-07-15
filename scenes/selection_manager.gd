extends Node3D

class_name SelectionManager

@export var ground_y: float = 0.5

var is_dragging: bool = false
var start_position: Vector3 = Vector3(0, ground_y, 0)
var end_position: Vector3 = Vector3(0, ground_y, 0)

var selected_units: Array[Unit] = []

var _camera: Camera3D
@onready var _box_visual: MeshInstance3D = $BoxVisual


@export var _level: Level
var _tmpCommander: Commander = Commander.new()


func _ready() -> void:
	_camera = get_viewport().get_camera_3d()
	_box_visual.visible = false
	assert(_level)
	_tmpCommander.level = _level
	_tmpCommander.pathfinding_grid = _level._grid
	add_child(_tmpCommander)


func _input(event: InputEvent) -> void:
	# right click to move units to the clicked position
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var ground_hits := _mouse_to_ground(event.position)
			if ground_hits.is_empty():
				return
			_issue_move_command(ground_hits[0])
			return

	# left click to select units in a box
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				var ground_hits := _mouse_to_ground(get_viewport().get_mouse_position())
				if ground_hits.is_empty():
					return
				is_dragging = true
				start_position = ground_hits[0]
				end_position = ground_hits[0]
				deselect_all()
				_update_box_visual()
			else:
				is_dragging = false
				select_units_in_box()
				_update_box_visual()
	if event is InputEventMouseMotion and is_dragging:
		var ground_hits := _mouse_to_ground(get_viewport().get_mouse_position())
		if not ground_hits.is_empty():
			end_position = ground_hits[0]
			_update_box_visual()
			_refresh_selection_in_box()


func _mouse_to_ground(mouse_pos: Vector2) -> Array:
	if _camera == null:
		return []
	var origin := _camera.project_ray_origin(mouse_pos)
	var normal := _camera.project_ray_normal(mouse_pos)
	var plane := Plane(Vector3.UP, ground_y)
	var hit = plane.intersects_ray(origin, normal)
	if hit == null:
		return []
	return [hit]


func _get_xz_rect() -> Rect2:
	# flatten the rect to the ground plane
	return Rect2(
		Vector2(minf(start_position.x, end_position.x), minf(start_position.z, end_position.z)),
		Vector2(absf(end_position.x - start_position.x), absf(end_position.z - start_position.z)),
	)


func _update_box_visual() -> void:
	_box_visual.visible = is_dragging
	if not is_dragging:
		return
	var rect := _get_xz_rect()
	_box_visual.global_position = Vector3(rect.get_center().x, ground_y + 0.01, rect.get_center().y)
	_box_visual.scale = Vector3(maxf(rect.size.x, 0.1), 1.0, maxf(rect.size.y, 0.1))


func select_units_in_box() -> void:
	var select_rect := _get_xz_rect()
	var all_units := get_tree().get_nodes_in_group("units")

	for unit in all_units:
		var xz := Vector2(unit.global_position.x, unit.global_position.z)
		if select_rect.has_point(xz):
			selected_units.append(unit)
			if unit.has_method("select"):
				unit.select(self)


func deselect(unit: Unit) -> void:
	selected_units.erase(unit)


func deselect_all() -> void:
	for unit in selected_units:
		if unit.has_method("deselect"):
			unit.deselect()
	selected_units.clear()


func _refresh_selection_in_box() -> void:
	deselect_all()
	select_units_in_box()


# TODO: move all selected units to the target position in a formation
func _issue_move_command(target_pos: Vector3) -> void:
	_tmpCommander.clear_troops()

	var center := Vector3.ZERO
	for unit in selected_units:
		center += unit.global_position
		_tmpCommander.register(unit)

	center /= selected_units.size()
	_tmpCommander.position = center
	_tmpCommander.set_target(Vector2(target_pos.x, target_pos.z))
	
#	for unit in selected_units:
#		var offset := unit.global_position - center
#		offset.y = 0.0
#		unit.move_to(target_pos + offset)
