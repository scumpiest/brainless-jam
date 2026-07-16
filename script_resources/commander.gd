extends Node3D

class_name Commander

var speed: float = 5.0
var level: Level
var pathfinding_grid: AStarGrid2D

var _troops: Array[Unit] = []
var _troopsClose: bool = false

var _path: Array[Vector2i]
var _pathIndex: int = -1
var _nextPathTarget: Vector2

var _targetEntity # Needs to be a base class for resources, units (player and enemy), bases
var _pathUpdateFreq: float = .25
var _pathUpdateTimer: float = 0 

var _maxTroopDistance: float = 1.0
var _steeringBehaviours: Dictionary = {}


func _ready() -> void:
	_steeringBehaviours[SteeringBehaviour.BehaviourType.Separation] = Separation.new()
	_steeringBehaviours[SteeringBehaviour.BehaviourType.Avoidance] = Avoidance.new()


func get_behaviour(type: SteeringBehaviour.BehaviourType) -> SteeringBehaviour:
	return _steeringBehaviours[type]


func has_troop(troop: Unit) -> bool:
	return _troops.has(troop)


func register(troop: Unit) -> void:
	if has_troop(troop):
		return
	
	_troops.push_back(troop)
	for type: SteeringBehaviour.BehaviourType in _steeringBehaviours:
		get_behaviour(type).units.push_back(troop)
	troop.commander_registered(self)

	
func unregister(troop: Unit) -> void:
	for type: SteeringBehaviour.BehaviourType in _steeringBehaviours:
		get_behaviour(type).units.erase(troop)
	_troops.erase(troop)
	if _troops.is_empty():
		queue_free()


func _update_next_target_path() -> void:
	var convertedPos: Vector2 = level.convert_path_id_to_pos(_path[_pathIndex])
	_nextPathTarget = Vector2(convertedPos.x, convertedPos.y)
	print("Next target %.3f, %.3f" % [convertedPos.x, convertedPos.y])


func set_target(target: Vector2) -> void:
	assert(level)
	assert(pathfinding_grid)
	
	var pos: Vector2i = level.convert_pos_to_path_id(Vector2(position.x, position.z))
	var tar: Vector2i = level.convert_pos_to_path_id(target) 

	print("Traveling from %d, %d to %d, %d" % [pos.x, pos.y, tar.x, tar.y])
	_path = pathfinding_grid.get_id_path(pos, tar)
	print("Found path of length %d" % [_path.size()])
	if _path.size() > 0:
		_pathIndex = 0
		_update_next_target_path()


func set_target_entity(target: Node3D) -> void:
	_targetEntity = target
	if _targetEntity:
		set_target(Vector2(_targetEntity.position.x, _targetEntity.position.z))
		if _path:
			_path.pop_back() # don't walk onto the entity


func _process(delta: float) -> void:
	if _targetEntity:
		_pathUpdateTimer += delta
		if _pathUpdateTimer > _pathUpdateFreq:
			_pathUpdateTimer = 0
			set_target_entity(_targetEntity)

	if _pathIndex != -1:
		position.x = move_toward(position.x, _nextPathTarget.x, delta * speed)
		position.y = 1
		position.z = move_toward(position.z, _nextPathTarget.y, delta * speed)
		
		if _troopsClose && (Vector2(position.x, position.z) - _nextPathTarget).length_squared() < (.25 * .25):
			_pathIndex += 1
			if _path && _path.size() > _pathIndex:
				assert(level)
				_update_next_target_path()
			else:
				_pathIndex = -1

	_update_troops()


func _update_troops() -> void:
	_troopsClose = true
	for troop: Unit in _troops:
		troop._move_target = position
		troop._has_move_target = true
		if (troop.position - position).length_squared() > _maxTroopDistance:
			_troopsClose = false
