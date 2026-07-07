extends SteeringBehaviour
class_name Separation

func get_type() -> BehaviourType:
	return BehaviourType.Separation

func calc_direction(unit: Node3D) -> Vector2:
	var dir: Vector3 = Vector3()
	
	for node: Node3D in units:
		if node != unit:
			var delta: Vector3 = node.position - unit.position
			var s: float = 0.1 / (delta.length_squared()+.1)
			dir -= delta * s
	
	return Vector2(dir.x, dir.z)
