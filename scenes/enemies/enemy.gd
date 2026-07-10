class_name Enemy
extends CharacterBody3D

signal died

@export var max_hp: float = 30.0
@export var attack_damage: float = 8.0
@export var attack_range: float = 1.2
@export var attack_speed: float = 1.0
@export var move_speed: float = 3.0
@export var detection_radius: float = 8.0
@export var level: Level

@onready var _sprite: Sprite3D = $Sprite3D

enum State { IDLE, CHASE, ATTACK, DEAD }

const PATH_UPDATE_INTERVAL: float = 0.5

var _state: State = State.IDLE
var _current_hp: float
var _attack_cooldown: float = 0.0
var _path_timer: float = 0.0
var _path: Array[Vector2i] = []
var _path_index: int = -1
var _target: Node3D = null
var _gravity: float = 9.8
@onready var _hp_label: Label3D = $HpLabel


func _ready() -> void:
	add_to_group("enemies")
	_current_hp = max_hp
	_update_hp_label()


func _update_hp_label() -> void:
	if max_hp <= 0.0:
		return
	_hp_label.text = "%d/%d" % [int(_current_hp), int(max_hp)]
	var ratio: float = _current_hp / max_hp
	_hp_label.modulate = Color(1.0 - ratio, ratio, 0.0)


func _physics_process(delta: float) -> void:
	if _state == State.DEAD:
		return

	if not is_on_floor():
		velocity.y -= _gravity * delta

	match _state:
		State.IDLE:
			_tick_idle()
			velocity.x = move_toward(velocity.x, 0.0, move_speed)
			velocity.z = move_toward(velocity.z, 0.0, move_speed)
		State.CHASE:
			_tick_chase(delta)
		State.ATTACK:
			_tick_attack_state(delta)

	move_and_slide()


func _tick_idle() -> void:
	var nearest: Node3D = _find_nearest_unit()
	if nearest != null:
		_target = nearest
		_transition_to(State.CHASE)


func _find_nearest_unit() -> Node3D:
	var best_dist: float = detection_radius
	var nearest: Node3D = null
	for node: Node in get_tree().get_nodes_in_group("units"):
		var unit := node as Node3D
		if unit == null:
			continue
		var d: float = global_position.distance_to(unit.global_position)
		if d < best_dist:
			best_dist = d
			nearest = unit
	return nearest


func _transition_to(new_state: State) -> void:
	_state = new_state
	if new_state == State.IDLE:
		_path.clear()
		_path_index = -1
		_target = null


func _tick_chase(delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		_target = _find_nearest_unit()
		if _target == null:
			_transition_to(State.IDLE)
			return

	var dist: float = global_position.distance_to(_target.global_position)
	if dist <= attack_range:
		_transition_to(State.ATTACK)
		return

	_path_timer += delta
	if _path_timer >= PATH_UPDATE_INTERVAL or _path_index == -1:
		_path_timer = 0.0
		_recalculate_path()

	_follow_path()


func _recalculate_path() -> void:
	if level == null or _target == null:
		_path.clear()
		_path_index = -1
		return
	var self_pos := Vector2(global_position.x, global_position.z)
	var target_pos := Vector2(_target.global_position.x, _target.global_position.z)
	var from: Vector2i = level.convert_pos_to_path_id(self_pos)
	var to: Vector2i = level.convert_pos_to_path_id(target_pos)
	_path = level.get_route(from, to)
	_path_index = 0 if _path.size() > 0 else -1


func _follow_path() -> void:
	if _path_index < 0 or _path_index >= _path.size():
		_move_toward_target()
		return

	if level == null:
		_move_toward_target()
		return

	var next_cell: Vector2i = _path[_path_index]
	var next_pos_2d: Vector2 = level.convert_path_id_to_pos(next_cell)
	var next_pos := Vector3(next_pos_2d.x, global_position.y, next_pos_2d.y)
	var to_next: Vector3 = next_pos - global_position
	to_next.y = 0.0

	if to_next.length() < 0.25:
		_path_index += 1
		return

	var dir: Vector3 = to_next.normalized()
	velocity.x = dir.x * move_speed
	velocity.z = dir.z * move_speed
	if _sprite and dir.x != 0.0:
		_sprite.flip_h = dir.x < 0.0


func _move_toward_target() -> void:
	if _target == null:
		return
	var to_target: Vector3 = _target.global_position - global_position
	to_target.y = 0.0
	if to_target.length() < 0.1:
		return
	var dir: Vector3 = to_target.normalized()
	velocity.x = dir.x * move_speed
	velocity.z = dir.z * move_speed
	if _sprite and dir.x != 0.0:
		_sprite.flip_h = dir.x < 0.0


func _tick_attack_state(delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		_target = _find_nearest_unit()
		if _target == null:
			_transition_to(State.IDLE)
			return

	var dist: float = global_position.distance_to(_target.global_position)
	if dist > attack_range * 1.5:
		_transition_to(State.CHASE)
		return

	velocity.x = move_toward(velocity.x, 0.0, move_speed)
	velocity.z = move_toward(velocity.z, 0.0, move_speed)

	if _attack_cooldown > 0.0:
		_attack_cooldown -= delta
		return

	_attack_cooldown = 1.0 / attack_speed
	if _target.has_method("take_damage"):
		_target.call("take_damage", attack_damage)


func take_damage(amount: float) -> void:
	if _state == State.DEAD:
		return
	_current_hp -= amount
	_update_hp_label()
	if _current_hp <= 0.0:
		_die()


func _die() -> void:
	_state = State.DEAD
	died.emit()
	queue_free()
