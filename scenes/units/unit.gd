extends CharacterBody3D

class_name Unit

signal died
signal health_changed(current_hp: float, max_hp_val: float)

@export var unit_data: UnitData
@export var speed: float = 5.0
@export var stop_distance: float = 0.5
@export var projectile_scene: PackedScene

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
var is_miner: bool

# Upgrade effects indexed by EffectType for O(1) lookup
var _active_effects: Dictionary = {}

# Steering
var _steering_behaviours: Array[SteeringBehaviour] = []
var _commander: Commander
var _selection_manager: SelectionManager

var _gravity: float = 9.8

var _move_target: Vector3
var _has_move_target: bool = false

# Combat state
var _attack_cooldown: float = 0.0
var _stun_timer: float = 0.0
var _time_since_damage: float = INF

@onready var _hp_label: Label3D = $HpLabel


func _ready() -> void:
	add_to_group("units")
	_apply_unit_data()
	_apply_sprite_frames()
	_apply_upgrades()
	_update_hp_label()


func _apply_unit_data() -> void:
	if unit_data == null:
		return
	max_hp = unit_data.max_hp
	current_hp = unit_data.max_hp
	attack_range = unit_data.attack_range
	attack_speed = unit_data.attack_speed
	attack_damage = unit_data.attack_damage
	is_miner = unit_data.is_miner


func _apply_sprite_frames() -> void:
	if unit_data == null or unit_data.animation_sprite_frames == null:
		return
	_sprite.sprite_frames = unit_data.animation_sprite_frames
	_sprite.play("idle")


func _apply_upgrades() -> void:
	if unit_data == null:
		return
	for upgrade: UpgradeData in unit_data.upgrade_slots:
		for effect: UpgradeEffectData in upgrade.upgrade_effects:
			_active_effects[effect.effect_type] = effect


func _update_hp_label() -> void:
	if max_hp <= 0.0:
		return
	_hp_label.text = "%d/%d" % [int(current_hp), int(max_hp)]
	var ratio: float = current_hp / max_hp
	_hp_label.modulate = Color(1.0 - ratio, ratio, 0.0)


func select(selection_manager: SelectionManager) -> void:
	_sprite.modulate = Color.BLUE
	_selection_manager = selection_manager


func deselect() -> void:
	_sprite.modulate = Color.WHITE
	_selection_manager = null


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta

	_tick_stun(delta)
	_tick_regen(delta)
	_tick_attack(delta)

	if _stun_timer > 0.0:
		move_and_slide()
		return

	var direction := Vector3.ZERO
	if is_mining == true:
		_sprite.play("mine")
		return
	if _has_move_target:
		var to_target := _move_target - global_position
		to_target.y = 0.0

		var dir_adjustment: Vector2 = Vector2()
		for behaviour: SteeringBehaviour in _steering_behaviours:
			dir_adjustment += behaviour.calc_direction(self)

		to_target += Vector3(dir_adjustment.x, 0, dir_adjustment.y)

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


func attack(target: Unit) -> void:
	target.take_damage(attack_damage)

	var stun_fx: UpgradeEffectData = _active_effects.get(UpgradeEffectData.EffectType.STUN_ON_HIT)
	if stun_fx and randf() < stun_fx.value:
		target.apply_stun(stun_fx.secondary_value)

	var cleave_fx: UpgradeEffectData = _active_effects.get(UpgradeEffectData.EffectType.CLEAVE)
	if cleave_fx:
		_do_cleave(target, cleave_fx)


func take_damage(amount: float) -> void:
	_time_since_damage = 0.0
	current_hp -= amount
	health_changed.emit(current_hp, max_hp)
	_update_hp_label()
	if current_hp <= 0.0:
		_die()


func apply_stun(duration: float) -> void:
	_stun_timer = maxf(_stun_timer, duration)


func _tick_stun(delta: float) -> void:
	if _stun_timer > 0.0:
		_stun_timer -= delta


func _tick_regen(delta: float) -> void:
	var regen_fx: UpgradeEffectData = _active_effects.get(UpgradeEffectData.EffectType.REGEN_SHIELD)
	if regen_fx == null:
		return
	_time_since_damage += delta
	if _time_since_damage >= regen_fx.secondary_value:
		var prev_hp: float = current_hp
		current_hp = minf(current_hp + regen_fx.value * delta, max_hp)
		if current_hp != prev_hp:
			health_changed.emit(current_hp, max_hp)
			_update_hp_label()


func _tick_attack(delta: float) -> void:
	if attack_range <= 0.0 or attack_speed <= 0.0:
		return
	if _attack_cooldown > 0.0:
		_attack_cooldown -= delta
		return

	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var target := node as Node3D
		if target == null:
			continue
		if global_position.distance_to(target.global_position) <= attack_range:
			var unit_target := target as Unit
			if unit_target:
				attack(unit_target)
			else:
				target.call("take_damage", attack_damage)
			_attack_cooldown = 1.0 / attack_speed
			return

func _do_cleave(primary_target: Unit, fx: UpgradeEffectData) -> void:
	var arc_half_rad: float = deg_to_rad(fx.secondary_value * 0.5)
	var forward: Vector3 = (primary_target.global_position - global_position).normalized()
	forward.y = 0.0

	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var target := node as Node3D
		if target == null or target == primary_target:
			continue
		var to_enemy: Vector3 = (target.global_position - global_position)
		to_enemy.y = 0.0
		if to_enemy.length() > attack_range:
			continue
		if forward.angle_to(to_enemy.normalized()) <= arc_half_rad:
			target.call("take_damage", attack_damage * fx.value)


func _die() -> void:
	var explode_fx: UpgradeEffectData = _active_effects.get(UpgradeEffectData.EffectType.EXPLODE_ON_DEATH)
	if explode_fx:
		_explode(explode_fx.value, explode_fx.secondary_value)
	remove_from_group("units")
	
	clear_commander()
	
	if _selection_manager:
		_selection_manager.deselect(self)
	
	died.emit()
	queue_free()
	GameState.check_defeat()


func _explode(damage: float, radius: float) -> void:
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var target := node as Node3D
		if target == null:
			continue
		if global_position.distance_to(target.global_position) <= radius:
			target.call("take_damage", damage)


func move_to(target: Vector3) -> void:
	_move_target = target
	_move_target.y = global_position.y
	_has_move_target = true


func clear_commander() -> void:
	if _commander:
		_commander.unregister(self)
		
	_steering_behaviours.clear()
	_commander = null


func commander_registered(commander: Commander) -> void:
	clear_commander()

	_commander = commander
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
