class_name InventoryManager
extends Node


# =========================================================
# INVENTORY
# =========================================================

# 5 SLOT CỐ ĐỊNH CỦA PLAYER
const BASE_SLOTS: int = 5


# =========================================================
# BACKPACK
# =========================================================

# Số slot backpack đang cộng thêm
var backpack_slots: int = 0


# =========================================================
# SLOT DATA
#
# {
# "item": ItemData,
# "amount": int
# }
# =========================================================

var slots: Array = []


# =========================================================
# READY
# =========================================================

func _ready() -> void:

	# =====================================================
	# TẠO INVENTORY MẶC ĐỊNH
	# =====================================================

	rebuild_inventory()


	print(
		"InventoryManager READY - Base Slots: ",
		BASE_SLOTS
	)

	print(
		"Backpack Slots: ",
		backpack_slots
	)

	print(
		"Total Slots: ",
		get_slot_count()
	)


# =========================================================
# LẤY TỔNG SỐ SLOT
# =========================================================

func get_slot_count() -> int:

	return BASE_SLOTS + backpack_slots


# =========================================================
# TẠO / RESIZE INVENTORY
# =========================================================

func rebuild_inventory() -> void:

	var old_slots: Array = slots.duplicate()

	var new_slot_count: int = get_slot_count()

	slots.clear()


	# =====================================================
	# TẠO SLOT MỚI
	# =====================================================

	for i in range(new_slot_count):

		var slot_data := {
			"item": null,
			"amount": 0
		}


		# =================================================
		# GIỮ ITEM CŨ NẾU SLOT CŨ TỒN TẠI
		# =================================================

		if i < old_slots.size():

			slot_data["item"] = old_slots[i]["item"]
			slot_data["amount"] = old_slots[i]["amount"]


		slots.append(slot_data)


# =========================================================
# TRANG BỊ BACKPACK
# =========================================================

func equip_backpack(extra_slots: int) -> bool:

	if extra_slots < 0:
		print("ERROR: Backpack không thể có slot âm")
		return false


	var new_total_slots: int = BASE_SLOTS + extra_slots


	# =====================================================
	# KIỂM TRA ITEM NẰM NGOÀI VÙNG SLOT MỚI
	# =====================================================

	for i in range(new_total_slots, slots.size()):

		if slots[i]["item"] != null:

			print(
				"KHÔNG THỂ ĐỔI BACKPACK - SLOT ",
				i,
				" ĐANG CÓ: ",
				slots[i]["item"].item_data.item_name
			)

			return false


	# =====================================================
	# ĐỔI SỐ SLOT
	# =====================================================

	backpack_slots = extra_slots

	rebuild_inventory()


	print("BACKPACK UPDATED")
	print("Backpack Slots: ", backpack_slots)
	print("Total Inventory Slots: ", get_slot_count())

	return true


# =========================================================
# THÁO BACKPACK
# =========================================================

func remove_backpack() -> bool:

	return equip_backpack(0)


# =========================================================
# TÌM SLOT TRỐNG
# =========================================================

func find_empty_slot() -> int:

	for i in range(slots.size()):

		if slots[i]["item"] == null:

			return i


	return -1


# =========================================================
# TÌM ITEM ĐÃ CÓ
# =========================================================

func find_item(item: ItemInstance) -> int:

	if item == null:
		return -1

	for i in range(slots.size()):

		if slots[i]["item"] == null:
			continue

		var stored_item: ItemInstance = slots[i]["item"]

		if stored_item.unique_id == item.unique_id:
			return i

	return -1

# =========================================================
# THÊM ITEM
# =========================================================

func add_item(
	item: ItemInstance,
	amount: int = 1
) -> bool:

	if item == null:
		print("ERROR: add_item() nhận ItemInstance null")
		return false

	if item.item_data == null:
		print("ERROR: ItemInstance không có ItemData")
		return false

	if amount <= 0:
		return false

	var empty_slot: int = find_empty_slot()

	if empty_slot == -1:
		print("Inventory FULL")
		return false

	slots[empty_slot]["item"] = item
	slots[empty_slot]["amount"] = amount

	print(
		"Inventory ADD: ",
		item.item_data.item_name,
		" x",
		amount,
		" | Slot: ",
		empty_slot,
		" | UID: ",
		item.unique_id
	)

	return true
	
# =========================================================
# XÓA ITEM
# =========================================================

func remove_item(
	item: ItemInstance,
	amount: int = 1
) -> bool:

	if item == null:
		return false

	if amount <= 0:
		return false

	var slot_index: int = find_item(item)

	if slot_index == -1:
		print(
			"Inventory REMOVE FAILED: không tìm thấy ",
			item.item_data.item_name
		)
		return false

	var current_amount: int = slots[slot_index]["amount"]

	if current_amount < amount:
		print(
			"Inventory REMOVE FAILED: không đủ ",
			item.item_data.item_name
		)
		return false

	slots[slot_index]["amount"] -= amount

	if slots[slot_index]["amount"] <= 0:
		slots[slot_index]["item"] = null
		slots[slot_index]["amount"] = 0

	print(
		"Inventory REMOVE: ",
		item.item_data.item_name,
		" x",
		amount
	)

	return true
	
# =========================================================
# LẤY ITEM TRONG SLOT
# =========================================================

func get_item(slot_index: int) -> ItemInstance:

	if slot_index < 0:
		return null

	if slot_index >= slots.size():
		return null

	return slots[slot_index]["item"]


# =========================================================
# LẤY SỐ LƯỢNG
# =========================================================

func get_amount(slot_index: int) -> int:

	if slot_index < 0:

		return 0


	if slot_index >= slots.size():

		return 0


	return slots[slot_index]["amount"]


# =========================================================
# KIỂM TRA INVENTORY ĐẦY
# =========================================================

func is_full() -> bool:

	return find_empty_slot() == -1


# =========================================================
# XÓA TOÀN BỘ INVENTORY
# =========================================================

func clear_inventory() -> void:

	for i in range(slots.size()):

		slots[i]["item"] = null
		slots[i]["amount"] = 0


	print(
		"Inventory CLEARED"
	)


# =========================================================
# DEBUG INVENTORY
# =========================================================

func debug_inventory() -> void:

	print(
		"========== INVENTORY =========="
	)


	print(
		"Base Slots: ",
		BASE_SLOTS
	)


	print(
		"Backpack Slots: ",
		backpack_slots
	)


	print(
		"Total Slots: ",
		get_slot_count()
	)


	for i in range(slots.size()):

		var item: ItemInstance = (
			slots[i]["item"]
		)

		var amount: int = (
			slots[i]["amount"]
		)


		if item != null:

			print(
				"Slot ",
				i,
				": ",
				item.item_data.item_name,
				" x",
				amount
			)

		else:

			print(
				"Slot ",
				i,
				": EMPTY"
			)


	print(
		"==============================="
	)

# =========================================================
# ĐỔI ITEM GIỮA 2 SLOT
# =========================================================

# =========================================================
# DI CHUYỂN / ĐỔI ITEM GIỮA 2 SLOT
# =========================================================

func move_item(
	from_index: int,
	to_index: int
) -> bool:

	if from_index < 0 or from_index >= slots.size():
		return false

	if to_index < 0 or to_index >= slots.size():
		return false

	if from_index == to_index:
		return false

	var temp_item: ItemInstance = slots[from_index]["item"]
	var temp_amount: int = slots[from_index]["amount"]

	slots[from_index]["item"] = slots[to_index]["item"]
	slots[from_index]["amount"] = slots[to_index]["amount"]

	slots[to_index]["item"] = temp_item
	slots[to_index]["amount"] = temp_amount

	print(
		"Inventory MOVE: Slot ",
		from_index,
		" <-> Slot ",
		to_index
	)

	return true

# =========================================================
# XÓA ITEM THEO SLOT
# =========================================================

func remove_item_from_slot(
	slot_index: int,
	amount: int = 1
) -> bool:

	if slot_index < 0 or slot_index >= slots.size():
		return false

	if amount <= 0:
		return false

	var item: ItemInstance = slots[slot_index]["item"]

	if item == null:
		return false

	var current_amount: int = slots[slot_index]["amount"]

	if current_amount < amount:
		return false

	slots[slot_index]["amount"] -= amount

	if slots[slot_index]["amount"] <= 0:
		slots[slot_index]["item"] = null
		slots[slot_index]["amount"] = 0

	print(
		"Inventory REMOVE SLOT: ",
		item.item_data.item_name,
		" x",
		amount,
		" | Slot: ",
		slot_index
	)

	return true

# =========================================================
# GÁN TRỰC TIẾP ITEM VÀO SLOT
# =========================================================

func set_slot(
	slot_index: int,
	item: ItemInstance,
	amount: int
) -> bool:

	if slot_index < 0 or slot_index >= slots.size():
		return false

	if item == null or amount <= 0:

		slots[slot_index]["item"] = null
		slots[slot_index]["amount"] = 0

	else:

		slots[slot_index]["item"] = item
		slots[slot_index]["amount"] = amount

	return true
	
# =========================================================
# USE ITEM
# =========================================================

func use_item(slot_index: int) -> bool:

	# =====================================================
	# KIỂM TRA SLOT
	# =====================================================

	if slot_index < 0 or slot_index >= slots.size():

		print(
			"USE ITEM FAILED: Slot không hợp lệ: ",
			slot_index
		)

		return false


	var item: ItemInstance = slots[slot_index]["item"]
	var amount: int = slots[slot_index]["amount"]

	if item == null or amount <= 0:

		print("USE ITEM FAILED: Slot trống")

		return false


	# =====================================================
	# KIỂM TRA ITEM INSTANCE
	# =====================================================

	if item.item_data == null:

		print(
			"USE ITEM FAILED: ItemInstance không có ItemData"
		)

		return false


	var item_data: ItemData = item.item_data


	# =====================================================
	# DEBUG
	# =====================================================

	print(
		"USE ITEM: ",
		item_data.item_name,
		" | Type: ",
		ItemData.ItemType.keys()[item_data.item_type],
		" | Equipment: ",
		ItemData.EquipmentType.keys()[item_data.equipment_type],
		" | UID: ",
		item.unique_id
	)


	# =====================================================
	# WEAPON
	# =====================================================

	if item_data.item_type == ItemData.ItemType.WEAPON:

		var success: bool = Equipmentmanager.use_item(item)

		if not success:

			return false


		# Chỉ xóa khỏi inventory nếu equip thành công
		return remove_item_from_slot(slot_index, 1)


	# =====================================================
	# EQUIPMENT
	# =====================================================

	if item_data.equipment_type != ItemData.EquipmentType.NONE:

		var success: bool = Equipmentmanager.use_item(item)

		if not success:

			return false


		# Chỉ xóa khỏi inventory nếu equip thành công
		return remove_item_from_slot(slot_index, 1)


	# =====================================================
	# CÁC LOẠI ITEM KHÁC
	# =====================================================

	match item_data.item_type:

		ItemData.ItemType.CONSUMABLE:

			print(
				"CONSUMABLE CHƯA IMPLEMENT: ",
				item_data.item_name
			)

			return false


		ItemData.ItemType.TOOL:

			print(
				"TOOL CHƯA IMPLEMENT: ",
				item_data.item_name
			)

			return false


		ItemData.ItemType.MATERIAL:

			print(
				"MATERIAL KHÔNG THỂ USE: ",
				item_data.item_name
			)

			return false


		ItemData.ItemType.BACKPACK:

			print(
				"BACKPACK CHƯA IMPLEMENT: ",
				item_data.item_name
			)

			return false


		_:

			return false
	
# =========================================================
# DROP ITEM
# =========================================================

func drop_item(slot_index: int, amount: int = 1) -> bool:
	# =====================================================
	# KIỂM TRA SLOT
	# =====================================================

	if slot_index < 0 or slot_index >= slots.size():
		print("ERROR: Slot index invalid: ", slot_index)
		return false

	var item: ItemInstance = slots[slot_index]["item"]

	if item == null:
		print("ERROR: Slot is empty")
		return false

	if item.item_data == null:
		print("ERROR: ItemInstance không có ItemData")
		return false

	var item_data: ItemData = item.item_data

	var current_amount: int = slots[slot_index]["amount"]
	var drop_amount: int = min(amount, current_amount)

	if drop_amount <= 0:
		print("ERROR: Drop amount <= 0")
		return false

	# =====================================================
	# LẤY VỊ TRÍ PLAYER
	# =====================================================

	var player = get_tree().get_first_node_in_group("player")

	if player == null:
		print("ERROR: Không tìm thấy player")
		return false

	# =====================================================
	# TẠO WORLD ITEM
	# =====================================================

	var world_item_scene = load("res://Scene/WorldItem.tscn")

	if world_item_scene == null:
		print("ERROR: Không load được world_item.tscn")
		return false

	var world_item = world_item_scene.instantiate()

	# GIỮ NGUYÊN INSTANCE → KHÔNG REROLL STATS/RARITY
	world_item.item_instance = item

	# =====================================================
	# DROP NGAY CHÂN PLAYER
	# =====================================================

	var drop_position = player.global_position

	drop_position += Vector2(
		randf_range(-2, 2),
		randf_range(-2, 2)
	)

	world_item.global_position = drop_position

	print("📍 Player: ", player.global_position)
	print("📍 Drop: ", drop_position)

	# =====================================================
	# THÊM VÀO SCENE
	# =====================================================

	get_tree().current_scene.add_child(world_item)

	# =====================================================
	# XÓA KHỎI INVENTORY
	# =====================================================

	slots[slot_index]["amount"] -= drop_amount

	if slots[slot_index]["amount"] <= 0:
		slots[slot_index]["item"] = null
		slots[slot_index]["amount"] = 0

	print(
		"🗑️ DROPPED: ",
		item_data.item_name,
		" x",
		drop_amount,
		" | UID: ",
		item.unique_id,
		" | Rarity: ",
		item.rarity
	)

	return true

# Drop toàn bộ stack
func drop_all(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= slots.size():
		return false
	
	var amount = slots[slot_index]["amount"]
	if amount <= 0:
		return false
	
	return drop_item(slot_index, amount)

# Drop một nửa stack
func drop_half(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= slots.size():
		return false
	
	var amount = slots[slot_index]["amount"]
	if amount <= 1:
		return drop_item(slot_index, 1)
	
	var half_amount = floor(amount / 2)
	return drop_item(slot_index, half_amount)

# =========================================================
# RARITY COLOR
# =========================================================

func get_rarity_color(item: ItemInstance) -> Color:

	if item == null:
		return Color(1, 1, 1, 0)

	if item.item_data == null:
		return Color.WHITE

	var rarity := item.rarity

	print(
		"RARITY CHECK: ",
		item.item_data.item_name,
		" | rarity = ",
		rarity,
		" | name = ",
		ItemData.Rarity.keys()[rarity]
	)

	match rarity:

		ItemData.Rarity.UNCOMMON:
			return Color("#55C85A")

		ItemData.Rarity.RARE:
			return Color("#4D8DFF")

		ItemData.Rarity.EPIC:
			return Color("#A855F7")

		ItemData.Rarity.LEGENDARY:
			return Color("#FFAA32")

		_:
			return Color.WHITE
