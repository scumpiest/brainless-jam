extends CharacterBody3D

class_name Unit

enum UnitClass { MELEE, RANGED, MINER }

@export var unit_data: UnitData
@export var speed: float = 5.0
@export var stop_distance: float = 0.5

@onready var _sprite: AnimatedSprite3D = $AnimatedSprite3D
@onready var _interaction_area: Area3D = $InteractionArea
@onready var _timer: Timer = $Timer

var resource: Area3D
var is_mining: bool = false

# Stats
var max_hp: float
var current_hp: float
var attack_range: float
var attack_speed: float
var attack_damage: float
#var upgrade_slots: Array[UpgradeData] = []

# Steering
var _steering_behaviours: Array[SteeringBehaviour] = []
var _commander: Commander

var _gravity: float = 9.8

var _move_target: Vector3
var _has_move_target: bool = false


func _ready() -> void:
	add_to_group("units")
	_apply_sprite_frames()


func _apply_sprite_frames() -> void:
	if unit_data == null or unit_data.animation_sprite_frames == null:
		return
	_sprite.sprite_frames = unit_data.animation_sprite_frames
	_sprite.play("idle")


func select() -> void:
	# TODO: add selection outline
	_sprite.modulate = Color.BLUE


func deselect() -> void:
	# TODO: remove selection outline
	_sprite.modulate = Color.WHITE


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta

	var direction := Vector3.ZERO
	if is_mining == true:
		_sprite.play("mine")
		return
	if _has_move_target:
		var to_target := _move_target - global_position
		to_target.y = 0.0
		
		var dirAdjustment: Vector2 = Vector2() 
		for behaviour: SteeringBehaviour in _steering_behaviours:
			dirAdjustment += behaviour.calc_direction(self) # TODO: get nodes from commander
		
		to_target += Vector3(dirAdjustment.x, 0, dirAdjustment.y)
		
		if to_target.length() <= stop_distance:
			_has_move_target = false
			velocity.x = move_toward(velocity.x, 0.0, speed)
			velocity.z = move_toward(velocity.z, 0.0, speed)
			_sprite.play("idle")
		else:
			direction = to_target.normalized()

	if direction:
		_sprite.play("run")
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		if direction.x != 0.0:
			_sprite.flip_h = direction.x < 0.0
	else:
		_sprite.play("idle")
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)

	move_and_slide()

func move_to(target: Vector3) -> void:
	_move_target = target
	_move_target.y = global_position.y # keep the same height
	_has_move_target = true


func commander_registered(commander: Commander) -> void:
	_commander = commander
	_steering_behaviours.clear()
	if _commander:
		_steering_behaviours.push_back(_commander.get_behaviour(SteeringBehaviour.BehaviourType.Separation))
		_steering_behaviours.push_back(_commander.get_behaviour(SteeringBehaviour.BehaviourType.Avoidance))


func mining():
	print("mined")
	if resource != null:
		resource.mine()

func _on_interaction_area_area_entered(area: Area3D) -> void:
	if area is ResourceVein:
		_timer.start()
		is_mining = true
		resource = area
		_sprite.play("mine")


func _on_interaction_area_area_exited(area: Area3D) -> void:
	is_mining = false


func _on_timer_timeout() -> void:
	mining()
	_timer.start()
