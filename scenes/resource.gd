extends Area3D
class_name ResourceVein

@export var health: int

@onready var health_bar: ProgressBar = $SubViewport/ProgressBar
var max_health: float
var damage: float = 10

func _ready() -> void:
	max_health = health_bar.max_value
	health_bar.value = max_health


func _process(delta: float) -> void:
	if health_bar.value <= 0:
		self.queue_free()

func mine():
	#var current_health = health
	#health = current_health - 10
	var current_health_bar = health_bar.value
	health_bar.value = current_health_bar - damage
