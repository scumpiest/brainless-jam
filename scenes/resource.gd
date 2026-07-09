extends Area3D

@export var health: int

func _process(delta: float) -> void:
	if health < 0:
		self.queue_free()

func mine():
	var current_health = health
	health = current_health - 10
	print("-10 hp")
