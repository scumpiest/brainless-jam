extends CharacterBody3D

class_name Pawn

@export var speed: float = 5.0

@onready var _sprite: AnimatedSprite3D = $AnimatedSprite3D
@onready var _interaction_area: Area3D = $InteractionArea

var _gravity: float = 9.8


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

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := Vector3(input_dir.x, 0.0, input_dir.y)

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
