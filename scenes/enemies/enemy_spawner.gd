class_name EnemySpawner
extends StaticBody3D

signal spawner_destroyed

# Offset the spawn interval to avoid spawning enemies at the same time
# Should be randomized
const SPAWN_INTERVAL_OFFSET: float = 0.5

@export var enemy_scene: PackedScene
@export var spawn_interval: float = 4.0
@export var max_active_enemies: int = 5
@export var max_hp: float = 80.0
@export var level: Level

var _current_hp: float
var _spawn_timer: float = 0.0
var _active_enemies: Array[Enemy] = []

@onready var _hp_label: Label3D = $HpLabel


func _ready() -> void:
	add_to_group("enemy_spawners")
	add_to_group("enemies")
	_current_hp = max_hp
	_update_hp_label()
	_spawn_timer = spawn_interval * SPAWN_INTERVAL_OFFSET


func _update_hp_label() -> void:
	if max_hp <= 0.0:
		return
	_hp_label.text = "%d/%d" % [int(_current_hp), int(max_hp)]
	var ratio: float = _current_hp / max_hp
	_hp_label.modulate = Color(1.0 - ratio, ratio, 0.0)


func _process(delta: float) -> void:
	_spawn_timer += delta
	if _spawn_timer >= spawn_interval:
		_spawn_timer = 0.0
		_try_spawn()


func _try_spawn() -> void:
	if _active_enemies.size() >= max_active_enemies:
		return
	if enemy_scene == null:
		return
	var enemy: Enemy = enemy_scene.instantiate()
	if enemy == null:
		return
	get_parent().add_child(enemy)
	enemy.global_position = global_position
	if enemy.has_method("set") and "level" in enemy:
		enemy.set("level", level)
	_active_enemies.append(enemy)


func take_damage(amount: float) -> void:
	_current_hp -= amount
	_update_hp_label()
	if _current_hp <= 0.0:
		_die()


func _die() -> void:
	spawner_destroyed.emit()
	queue_free()
