extends Camera3D

@export var speed: float = 10 


func _physics_process(_delta: float) -> void:
	var moveDir: Vector2 = Vector2(0, 0)

	moveDir.x = -1 if Input.is_action_pressed("move_left") else 0
	moveDir.x += 1 if Input.is_action_pressed("move_right") else 0
	moveDir.y = -1 if Input.is_action_pressed("move_forward") else 0
	moveDir.y += 1 if Input.is_action_pressed("move_back") else 0

	moveDir = moveDir.normalized() * speed * _delta

	position.x += moveDir.x
	position.z += moveDir.y

