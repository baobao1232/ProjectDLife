extends Resource
class_name ItemInstance

@export var item_data: ItemData

@export var rolled_stats: Array[ItemStat] = []
@export var rolled_options: Array[ItemOption] = []

@export var rarity: ItemData.Rarity = ItemData.Rarity.COMMON

@export var durability: float = 100.0

@export var unique_id: String = ""
