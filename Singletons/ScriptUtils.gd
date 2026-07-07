extends Node


func move_toward(pos: Vector3, target: Vector3, dist: float) -> Vector3:
	var delta: Vector3 = target - pos
	if delta.x < dist:
		pos.x = target.x
		delta.x = 0
	if delta.z < dist:
		pos.z = target.z
		delta.z = 0
	
	
	
	return target
