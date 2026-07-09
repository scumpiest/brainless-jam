class_name Organ
extends StaticBody3D

@export var max_hp: float = 300.0

var _current_hp: float
var _shielded: bool = true
var _hp_label: Label3D

@onready var _shield_mesh: MeshInstance3D = $ShieldMesh


func _ready() -> void:
	add_to_group("organ")
	add_to_group("enemies")
	_current_hp = max_hp
	_create_hp_label()


func _create_hp_label() -> void:
	_hp_label = Label3D.new()
	_hp_label.position = Vector3(0.0, 2.5, 0.0)
	_hp_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_hp_label.font_size = 16
	add_child(_hp_label)
	_update_hp_label()


func _update_hp_label() -> void:
	if _hp_label == null:
		return
	if _shielded:
		_hp_label.text = "ORGAN [SHIELDED]"
		_hp_label.modulate = Color.CYAN
	else:
		_hp_label.text = "ORGAN %d/%d" % [int(_current_hp), int(max_hp)]
		var ratio: float = _current_hp / max_hp if max_hp > 0.0 else 0.0
		_hp_label.modulate = Color(1.0 - ratio, ratio, 0.0)


func remove_shield() -> void:
	_shielded = false
	if _shield_mesh:
		_shield_mesh.visible = false
	_update_hp_label()


func take_damage(amount: float) -> void:
	if _shielded:
		return
	_current_hp -= amount
	_update_hp_label()
	if _current_hp <= 0.0:
		_die()


func _die() -> void:
	GameState.organ_destroyed.emit()
	queue_free()
