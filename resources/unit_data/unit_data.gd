extends Resource

class_name UnitData

enum UnitClass { MELEE, RANGED, MINER }

@export var unit_class: UnitClass
@export var unit_name: String
@export var unit_icon: Texture2D
@export var max_hp: float
@export var attack_range: float
@export var attack_speed: float
@export var attack_damage: float
@export var animation_sprite_frames: SpriteFrames
@export var is_miner: bool = false
@export var upgrade_slots: Array[UpgradeData]
