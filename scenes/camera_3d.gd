extends Camera3D

@export var target: Node3D
@export var offset: Vector3 = Vector3(0, 5, 8) # Adjust position relative to player


func _physics_process(_delta: float) -> void:
	if target:
		global_position = global_position.lerp(target.global_position + offset, 0.1)
