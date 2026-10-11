extends RefCounted
class_name ItemFactory


static func create_item(item_data: ItemData) -> ItemInstance:

	if item_data == null:
		push_error("ItemFactory: item_data == null")
		return null

	var instance := ItemInstance.new()

	instance.item_data = item_data
	instance.rarity = _roll_rarity()
	instance.unique_id = _generate_unique_id()

	# =====================================================
	# ROLL STATS
	# =====================================================

	for stat in item_data.stats:

		if stat == null:
			continue

		var rolled_stat := ItemStat.new()

		rolled_stat.type = stat.type
		rolled_stat.value = randf_range(
			stat.min_value,
			stat.max_value
		)

		instance.rolled_stats.append(rolled_stat)

	return instance

static func _generate_unique_id() -> String:

	return "%s_%s_%s" % [
		Time.get_ticks_usec(),
		randi(),
		randi()
	]

static func _roll_rarity() -> ItemData.Rarity:

	var roll := randf()

	if roll < 0.50:
		return ItemData.Rarity.COMMON

	if roll < 0.80:
		return ItemData.Rarity.UNCOMMON

	if roll < 0.95:
		return ItemData.Rarity.RARE

	if roll < 0.99:
		return ItemData.Rarity.EPIC

	return ItemData.Rarity.LEGENDARY
