@tool
extends Resource
class_name ItemData



# =========================================================
# ITEM TYPE
# =========================================================

enum ItemType {
	WEAPON,
	TOOL,
	CONSUMABLE,
	MATERIAL,
	BACKPACK
}


# =========================================================
# EQUIPMENT TYPE
# =========================================================

enum EquipmentType {
	NONE,
	HELMET,
	ARMOR,
	PANTS,
	BOOTS,
	WEAPON,
	BACKPACK,
	RING,
	NECKLACE
}


# =========================================================
# WEAPON TYPE
# =========================================================

enum WeaponType {
	RANGED,
	MELEE
}

# =========================================================
# CONSUMABLE ACTION
# =========================================================

enum ConsumableAction {
	EAT,
	DRINK,
	USE
}

# =========================================================
# RARITY
# =========================================================

enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY
}

# =========================================================
# CONSUMABLE
# =========================================================

@export_category("Consumable")

@export var consumable_action: ConsumableAction = ConsumableAction.EAT

# =========================================================
# BASIC INFO
# =========================================================

@export_category("Basic Info")

@export var id: String = ""
@export var item_name: String = ""

@export var icon: Texture2D
@export var world_sprite: Texture2D

@export var item_type: ItemType = ItemType.MATERIAL
@export var equipment_type: EquipmentType = EquipmentType.NONE

@export var rarity: Rarity = Rarity.COMMON

# =========================================================
# ITEM INFO
# =========================================================

@export_category("Item Info")

@export_multiline var description: String = ""


# =========================================================
# ITEM OPTIONS / CƯỜNG HÓA
# =========================================================

@export_category("Item Options")

@export var options: Array[ItemOption] = []


# =========================================================
# BACKPACK
# =========================================================

@export_category("Backpack")

@export var is_backpack: bool = false


# =========================================================
# ITEM POSITION
# =========================================================

@export_category("Item Position")

@export var grip_position: Vector2 = Vector2.ZERO
@export var muzzle_position: Vector2 = Vector2.ZERO
@export var size: Vector2 = Vector2.ONE

# =========================================================
# WEAPON
# =========================================================

@export_category("Weapon")

@export var weapon_type: WeaponType = WeaponType.RANGED:
	set(value):
		weapon_type = value
		_ensure_required_weapon_stats()


# =========================================================
# STATS
# =========================================================
# Tooltip sẽ tự động lấy các biến nằm trong category này.
#
# Không hard-code stat theo ItemType trong ItemTooltip.
# =========================================================

# =========================================================
# STATS
# =========================================================

@export_category("Stats")

@export var stats: Array[ItemStat] = []

func _ensure_required_weapon_stats() -> void:

	if item_type != ItemType.WEAPON:
		return

	var required_stats: Array[ItemStat.StatType] = []

	match weapon_type:

		WeaponType.RANGED:
			required_stats = [
				ItemStat.StatType.DAMAGE,
				ItemStat.StatType.CRIT_CHANCE,
				ItemStat.StatType.CRIT_DAMAGE,
				ItemStat.StatType.RANGE,
				ItemStat.StatType.FIRE_RATE,
				ItemStat.StatType.BULLET_SPEED,
				ItemStat.StatType.MAGAZINE_SIZE,
				ItemStat.StatType.RELOAD_TIME
			]

		WeaponType.MELEE:
			required_stats = [
				ItemStat.StatType.DAMAGE,
				ItemStat.StatType.CRIT_CHANCE,
				ItemStat.StatType.CRIT_DAMAGE,
				ItemStat.StatType.ATTACK_SPEED,
				ItemStat.StatType.ATTACK_RANGE
			]

	for stat_type in required_stats:

		var exists := false

		for stat in stats:
			if stat != null and stat.type == stat_type:
				exists = true
				break

		if exists:
			continue

		var new_stat := ItemStat.new()
		new_stat.type = stat_type
		new_stat.min_value = 0.0
		new_stat.max_value = 0.0

		stats.append(new_stat)

	notify_property_list_changed()
