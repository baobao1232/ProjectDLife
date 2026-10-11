extends Resource
class_name ItemStat

enum StatType {
	DAMAGE,
	CRIT_CHANCE,
	CRIT_DAMAGE,

	RANGE,
	FIRE_RATE,
	BULLET_SPEED,
	MAGAZINE_SIZE,
	RELOAD_TIME,

	ATTACK_SPEED,
	ATTACK_RANGE,

	HP,
	MAX_HP,
	ARMOR,
	SPEED,

	BACKPACK_SLOTS
}

@export var type: StatType = StatType.DAMAGE

@export var min_value: float = 0.0
@export var max_value: float = 0.0

@export var value: float = 0.0
