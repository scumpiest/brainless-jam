class_name UpgradeEffectData
extends Resource

enum EffectType {
	STUN_ON_HIT,
	CLEAVE,
	REGEN_SHIELD,
	EXPLODE_ON_DEATH,
}

@export var effect_type: EffectType
@export var value: float = 0.0
@export var secondary_value: float = 0.0
