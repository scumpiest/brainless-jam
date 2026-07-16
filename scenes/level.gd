extends Node3D

class_name Level

@export_file("*.b64") var map_data_path: String
@export var cell_size: int
@export var top_left_offset: Vector2i

@onready var _wall_scene: PackedScene = load("res://scenes/wall/wall.tscn")
@onready var _resource_scene: PackedScene = load("res://scenes/resource.tscn")
@onready var _enemy_unit_scene: PackedScene = load("res://scenes/enemies/enemy.tscn")
@onready var _enemy_spawner_scene: PackedScene = load("res://scenes/enemies/enemy_spawner.tscn")
@onready var _organ_scene: PackedScene = load("res://scenes/enemies/organ.tscn")
@export var _floor: StaticBody3D
@export var _camera: Camera3D

@export var _player_unit_spawn_spiral_scale: float = 0.1
@export var _player_unit_spawn_radius_scale: float = 0.1
@export var _num_player_miner: int = 2
@export var _num_player_ranged: int = 2
@export var _num_player_melee: int = 2

var _player_units: Array[Unit] = []

var _map_data: Array = []
var _grid: AStarGrid2D = AStarGrid2D.new()
var _size: Vector2i

var _enemy_spawners: Array = []
var _organ: Node3D = null


func convert_path_id_to_pos(id: Vector2i) -> Vector2:
	return Vector2(id.x * cell_size - top_left_offset.x, id.y * cell_size - top_left_offset.y)


func convert_pos_to_path_id(pos: Vector2) -> Vector2i:
	pos = Vector2(pos.x + top_left_offset.x, pos.y + top_left_offset.y) / cell_size
	if pos.x < 0 || pos.y < 0:
		return Vector2i(0, 0)
	return Vector2i(roundi(pos.x), roundi(pos.y))


func _spawn_player_units() -> void:
	var player_unit: PackedScene = load("res://scenes/units/unit.tscn")
	
	var miner_unit: Unit = player_unit.instantiate()
	miner_unit.unit_data = load("res://resources/unit_data/Miner.tres")
	miner_unit.speed = 5.0
	miner_unit.stop_distance = .5
	
	var ranged_unit: Unit = player_unit.instantiate()
	ranged_unit.unit_data = load("res://resources/unit_data/Ranged.tres")
	ranged_unit.speed = 5.0
	ranged_unit.stop_distance = .5
	
	var melee_unit: Unit = player_unit.instantiate()
	melee_unit.unit_data = load("res://resources/unit_data/Melee.tres")
	melee_unit.speed = 5.0
	melee_unit.stop_distance = .5
	
	for i: int in _num_player_miner:
		_player_units.push_back(miner_unit.duplicate())
	for i: int in _num_player_ranged:
		_player_units.push_back(ranged_unit.duplicate())
	for i: int in _num_player_melee:
		_player_units.push_back(melee_unit.duplicate())


func _setup_pathfinding() -> void:
	assert(_size && _size.x > 0 && _size.y > 0)

	_grid.region = Rect2i(0, 0, _size.x, _size.y)
	_grid.cell_size = Vector2(1, 1)
	_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_grid.cell_shape = AStarGrid2D.CELL_SHAPE_SQUARE

	_grid.update()


func _get_unit_offset(n: int) -> Vector2:
	var theta: float = n * _player_unit_spawn_spiral_scale
	var i: float = n * _player_unit_spawn_radius_scale
	return Vector2(i * cos(theta), i * sin(theta))


func _spawn_entity(scene: PackedScene, pos: Vector2i) -> void:
	var instance: Node3D = scene.instantiate()
	instance.position.x = pos.x
	instance.position.y = 1
	instance.position.z = pos.y
	add_child(instance)


func _load_map() -> void:
	assert(map_data_path)
	assert(cell_size)
	
	assert(FileAccess.file_exists(map_data_path))
	var map_file: FileAccess = FileAccess.open(map_data_path, FileAccess.READ)
	assert(map_file)
	
	var data: String = map_file.get_as_text()
	
	#var data: String = "AQAAAAIAAAACAAAAAgAAAAIAAAACAAAAAgAAAAIAAAACAAAAAgAAAAIAAAACAAAAAgAAAAIAAAACAAAAAgAAAAIAAAACAAAAAgAAAAIAAAACAAAAAgAAAAIAAAACAAAAAgAAAAIAAAACAAAAAgAAAAUAAAAWAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGgAAABYAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAaAAAAFgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABoAAAAWAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABLAAAATAAAAEwAAABMAAAATAAAAEwAAABMAAAATAAAAEwAAABMAAAATQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABoAAAAWAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAPAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGgAAABYAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA8AAAAAAAAAGIAAABMAAAATAAAAEwAAABMAAAATAAAAGMAAAAAAAAAPAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABoAAAAWAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGgAAABYAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAPAAAAAAAAABiAAAATAAAAEwAAABMAAAATAAAAEwAAABjAAAAAAAAADwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAaAAAAFgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAPAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABoAAAAWAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAE4AAABMAAAATAAAAEwAAABMAAAATAAAAEwAAABMAAAATAAAAEwAAABQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGgAAABYAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAaAAAAFgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABoAAAAWAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGgAAABYAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAaAAAAFgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABoAAAAWAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGgAAABYAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAaAAAAFgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABoAAABVAAAAVgAAAFYAAABWAAAAVgAAAFYAAABWAAAAVgAAAFYAAABWAAAAVgAAAFYAAABWAAAAVgAAAFYAAABWAAAAVgAAAFYAAABWAAAAVgAAAFYAAABWAAAAVgAAAFYAAABWAAAAVgAAAFYAAABWAAAAVgAAAFYAAABWAAAAWQAAAA=="
	var unpacked_data: PackedInt32Array = Marshalls.base64_to_raw(data).to_int32_array()

	var w: int = 100
	var h: int = 100

	_size = Vector2i(w, h)
	_setup_pathfinding()

	_floor.get_child(0).mesh.size = Vector3(_size.x * cell_size, 1, _size.y * cell_size)
	_floor.get_child(1).shape.size = _floor.get_child(0).mesh.size
	_floor.position = Vector3(((_size.x * cell_size) / 2.0), 0, ((_size.y * cell_size) / 2.0))

	for x: int in w:
		_map_data.push_back([])
		for y: int in h:
			_map_data[x].push_back(0)

	var empty: int = 0
	var wall: int = 35
	var floor_block: int = 45
	var organ: int = 54
	var player_spawn: int = 72
	var enemy_unit: int = 120
	var resource: int = 116
	var enemy_spawner: int = 118
	

	# { 35: 467, 45: 1739, 120: 21, 54: 1, 118: 9, 116: 22, 72: 1 }

	for y: int in h:
		for x: int in w:
			_map_data[x][y] = unpacked_data.get(y * w + x)
			var pos: Vector2 = convert_path_id_to_pos(Vector2i(x, y))
			if _map_data[x][y] == empty:
				_grid.set_point_solid(Vector2i(x, y), true)
			elif _map_data[x][y] == wall:
				_spawn_entity(_wall_scene, pos)
				_grid.set_point_solid(Vector2i(x, y), true)
			elif _map_data[x][y] == enemy_unit:
				_spawn_entity(_enemy_unit_scene, pos)
			elif _map_data[x][y] == resource:
				_spawn_entity(_resource_scene, pos)
			elif _map_data[x][y] == enemy_spawner:
				_spawn_entity(_enemy_spawner_scene, pos)
			elif _map_data[x][y] == organ:
				_spawn_entity(_organ_scene, pos)
			elif _map_data[x][y] == player_spawn:
				var cell_pos: Vector3 = Vector3(pos.x, 1, pos.y)
				_camera.position += Vector3(cell_pos.x, _camera.position.y, cell_pos.z)
				for i: int in _player_units.size():
					var unit_offset: Vector2 = _get_unit_offset(i)
					_player_units[i].position.x = cell_pos.x + unit_offset.x
					_player_units[i].position.y = cell_pos.y
					_player_units[i].position.z = cell_pos.z + unit_offset.y
					add_child(_player_units[i])
				_player_units.clear()
					
				


func _ready() -> void:
	_spawn_player_units()
	_load_map()
	_connect_enemy_spawners()


func _connect_enemy_spawners() -> void:
	for node: Node in get_tree().get_nodes_in_group("enemy_spawners"):
		if not node.has_signal("spawner_destroyed"):
			continue
		node.connect("spawner_destroyed", _on_enemy_spawner_destroyed.bind(node))
		_enemy_spawners.append(node)

	var organ_nodes: Array[Node] = get_tree().get_nodes_in_group("organ")
	if not organ_nodes.is_empty():
		_organ = organ_nodes[0] as Node3D


func _on_enemy_spawner_destroyed(spawner: Node) -> void:
	_enemy_spawners.erase(spawner)
	if _enemy_spawners.is_empty() and _organ != null and is_instance_valid(_organ):
		if _organ.has_method("remove_shield"):
			_organ.call("remove_shield")


func get_route(start: Vector2i, dest: Vector2i) -> Array[Vector2i]:
	return _grid.get_id_path(start, dest, false)
