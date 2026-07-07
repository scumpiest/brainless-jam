@abstract

extends RefCounted
class_name SteeringBehaviour

enum BehaviourType { Separation, Avoidance, Cohesion, Seek, Pursue, Wander } # Probably wont implement most of these but here for future use

var units: Array[Node3D] = []

@abstract func get_type() -> BehaviourType

@abstract func calc_direction(unit: Node3D) -> Vector2
