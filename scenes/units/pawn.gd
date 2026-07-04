extends CharacterBody3D

class_name Pawn

@export var speed: float = 5.0
@export var stop_distance: float = 0.5

@onready var _sprite: AnimatedSprite3D = $AnimatedSprite3D
@onready var _interaction_area: Area3D = $InteractionArea

var _gravity: float = 9.8

var _move_target: Vector3
var _has_move_target: bool = false


func _ready() -> void:
	add_to_group("units")


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

	if _has_move_target:
		var to_target := _move_target - global_position
		to_target.y = 0.0
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

