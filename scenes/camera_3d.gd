extends Camera3D

@export var target: Node3D
@export var offset: Vector3 = Vector3(0, 10, 6) # Adjust position relative to player
@export var pitch_degrees: float = -50.0


func _physics_process(_delta: float) -> void:
	if target:
		global_position = global_position.lerp(target.global_position + offset, 0.1)
		rotation_degrees.x = pitch_degrees # fixed camera angle
