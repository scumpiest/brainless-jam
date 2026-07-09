extends Node

signal resources_changed(new_amount: int)
signal organ_destroyed
signal all_units_dead

var resources: int = 0:
	set(v):
		resources = v
		resources_changed.emit(resources)


func add_resources(amount: int) -> void:
	resources += amount


func check_defeat() -> void:
	if get_tree().get_nodes_in_group("units").is_empty():
		all_units_dead.emit()
