class_name EquipmentManager
extends Node


# =========================================================
# EQUIPMENT SLOTS
# =========================================================

var helmet: ItemInstance  = null
var armor: ItemInstance  = null
var pants: ItemInstance  = null
var boots: ItemInstance  = null

var weapon_left: ItemInstance  = null
var weapon_right: ItemInstance  = null

var backpack: ItemInstance  = null

var ring_1: ItemInstance  = null
var ring_2: ItemInstance  = null

var necklace: ItemInstance  = null

	
# =========================================================
# LẤY ITEM THEO LOẠI
# =========================================================

func get_equipment(type: ItemData.EquipmentType) -> ItemInstance:

	match type:

		ItemData.EquipmentType.HELMET:
			return helmet

		ItemData.EquipmentType.ARMOR:
			return armor

		ItemData.EquipmentType.PANTS:
			return pants

		ItemData.EquipmentType.BOOTS:
			return boots

		ItemData.EquipmentType.WEAPON:
			return weapon_left

		ItemData.EquipmentType.BACKPACK:
			return backpack

		ItemData.EquipmentType.RING:
			if ring_1 != null:
				return ring_1

			return ring_2

		ItemData.EquipmentType.NECKLACE:
			return necklace

	return null


# =========================================================
# TRANG BỊ
# =========================================================

func equip(item: ItemInstance) -> bool:

	if item == null:
		return false

	if item.item_data == null:
		return false

	var item_data: ItemData = item.item_data


	match item_data.equipment_type:

		# =================================================
		# HELMET
		# =================================================

		ItemData.EquipmentType.HELMET:

			helmet = item


		# =================================================
		# ARMOR
		# =================================================

		ItemData.EquipmentType.ARMOR:

			armor = item


		# =================================================
		# PANTS
		# =================================================

		ItemData.EquipmentType.PANTS:

			pants = item


		# =================================================
		# BOOTS
		# =================================================

		ItemData.EquipmentType.BOOTS:

			boots = item


		# =================================================
		# WEAPON
		# =================================================

		ItemData.EquipmentType.WEAPON:

			if weapon_left == null:

				weapon_left = item

				var player := _get_player()

				if player != null:
					player.set_left_hand_item(item)

				print(
					"EQUIP WEAPON: ",
					item_data.item_name,
					" -> WeaponLeft"
				)

				return true


			if weapon_right == null:

				weapon_right = item

				var player := _get_player()

				if player != null:
					player.set_right_hand_item(item)

				print(
					"EQUIP WEAPON: ",
					item_data.item_name,
					" -> WeaponRight"
				)

				return true


			print(
				"KHÔNG THỂ EQUIP WEAPON: CẢ HAI TAY ĐỀU ĐẦY"
			)

			return false


		# =================================================
		# BACKPACK
		# =================================================

		ItemData.EquipmentType.BACKPACK:

			if not item_data.is_backpack:

				print(
					"ERROR: ",
					item_data.item_name,
					" không phải Backpack"
				)

				return false


			if backpack != null:

				print(
					"ĐANG CÓ BACKPACK: ",
					backpack.item_data.item_name
				)

				return false


			if not Inventorymanager.equip_backpack(
				item_data.backpack_slots
			):

				return false


			backpack = item


		# =================================================
		# RING
		# =================================================

		ItemData.EquipmentType.RING:

			if ring_1 == null:

				ring_1 = item

			elif ring_2 == null:

				ring_2 = item

			else:

				print("CẢ HAI SLOT NHẪN ĐỀU ĐẦY")
				return false


		# =================================================
		# NECKLACE
		# =================================================

		ItemData.EquipmentType.NECKLACE:

			necklace = item


		# =================================================
		# NONE
		# =================================================

		_:

			print(
				"ITEM KHÔNG PHẢI EQUIPMENT: ",
				item_data.item_name
			)

			return false


	print(
		"EQUIP: ",
		item_data.item_name
	)

	return true

func get_equipment_from_slot(slot_name: String) -> ItemInstance:

	match slot_name:

		"HelmetSlot":
			return helmet

		"ArmorSlot":
			return armor

		"PantsSlot":
			return pants

		"BootsSlot":
			return boots

		"WeaponLeftSlot":
			return weapon_left

		"WeaponRightSlot":
			return weapon_right

		"BackpackSlot":
			return backpack

		"RingSlot1":
			return ring_1

		"RingSlot2":
			return ring_2

		"NecklaceSlot":
			return necklace

	return null
	
func equip_to_slot(slot_name: String, item: ItemInstance) -> bool:

	if item == null:
		return false

	if item.item_data == null:
		return false

	var item_data: ItemData = item.item_data


	match slot_name:

		"HelmetSlot":

			if item_data.equipment_type != ItemData.EquipmentType.HELMET:
				return false

			helmet = item


		"ArmorSlot":

			if item_data.equipment_type != ItemData.EquipmentType.ARMOR:
				return false

			armor = item


		"PantsSlot":

			if item_data.equipment_type != ItemData.EquipmentType.PANTS:
				return false

			pants = item


		"BootsSlot":

			if item_data.equipment_type != ItemData.EquipmentType.BOOTS:
				return false

			boots = item


		"WeaponLeftSlot":

			if item_data.equipment_type != ItemData.EquipmentType.WEAPON:
				return false

			weapon_left = item

			_sync_player_weapon_hands()


		"WeaponRightSlot":

			if item_data.equipment_type != ItemData.EquipmentType.WEAPON:
				return false

			weapon_right = item

			_sync_player_weapon_hands()


		"BackpackSlot":

			if item_data.equipment_type != ItemData.EquipmentType.BACKPACK:
				return false

			if not item_data.is_backpack:
				return false

			if backpack != null:
				return false

			if not Inventorymanager.equip_backpack(
				item_data.backpack_slots
			):
				return false

			backpack = item


		"RingSlot1":

			if item_data.equipment_type != ItemData.EquipmentType.RING:
				return false

			ring_1 = item


		"RingSlot2":

			if item_data.equipment_type != ItemData.EquipmentType.RING:
				return false

			ring_2 = item


		"NecklaceSlot":

			if item_data.equipment_type != ItemData.EquipmentType.NECKLACE:
				return false

			necklace = item


		_:
			return false


	print(
		"EQUIP: ",
		item_data.item_name,
		" -> ",
		slot_name
	)

	return true

# =========================================================
# THÁO TRANG BỊ
# =========================================================

func unequip(
	type: ItemData.EquipmentType
) -> ItemInstance:

	var item: ItemInstance = null


	match type:

		# =================================================
		# HELMET
		# =================================================

		ItemData.EquipmentType.HELMET:

			item = helmet
			helmet = null


		# =================================================
		# ARMOR
		# =================================================

		ItemData.EquipmentType.ARMOR:

			item = armor
			armor = null


		# =================================================
		# PANTS
		# =================================================

		ItemData.EquipmentType.PANTS:

			item = pants
			pants = null


		# =================================================
		# BOOTS
		# =================================================

		ItemData.EquipmentType.BOOTS:

			item = boots
			boots = null


		# =================================================
		# WEAPON
		# =================================================

		ItemData.EquipmentType.WEAPON:

			item = weapon_left

			if item != null:

				weapon_left = null

			elif weapon_right != null:

				item = weapon_right
				weapon_right = null

			_sync_player_weapon_hands()


		# =================================================
		# BACKPACK
		# =================================================

		ItemData.EquipmentType.BACKPACK:

			item = backpack

			if item == null:
				return null


			# Kiểm tra có thể giảm inventory hay không
			if not Inventorymanager.remove_backpack():

				print(
					"KHÔNG THỂ THÁO BACKPACK"
				)

				return null


			backpack = null


		# =================================================
		# RING
		# =================================================

		ItemData.EquipmentType.RING:

			if ring_1 != null:

				item = ring_1
				ring_1 = null

			elif ring_2 != null:

				item = ring_2
				ring_2 = null


		# =================================================
		# NECKLACE
		# =================================================

		ItemData.EquipmentType.NECKLACE:

			item = necklace
			necklace = null


		_:

			return null


	if item != null:

		print(
			"UNEQUIP: ",
			item.item_data.item_name
		)


	return item

# =========================================================
# THÁO ITEM THEO ĐÚNG EQUIPMENT SLOT
# =========================================================

func unequip_from_slot(slot_name: String) -> ItemInstance:

	var item: ItemInstance = get_equipment_from_slot(slot_name)

	if item == null:
		return null


	if slot_name == "BackpackSlot":

		if not Inventorymanager.remove_backpack():
			print("KHÔNG THỂ THÁO BACKPACK")
			return null


	match slot_name:

		"HelmetSlot":
			helmet = null

		"ArmorSlot":
			armor = null

		"PantsSlot":
			pants = null

		"BootsSlot":
			boots = null

		"WeaponLeftSlot":
			weapon_left = null
			_sync_player_weapon_hands()

		"WeaponRightSlot":
			weapon_right = null
			_sync_player_weapon_hands()

		"BackpackSlot":
			backpack = null

		"RingSlot1":
			ring_1 = null

		"RingSlot2":
			ring_2 = null

		"NecklaceSlot":
			necklace = null

		_:
			return null


	print(
		"UNEQUIP: ",
		item.item_data.item_name,
		" <- ",
		slot_name
	)

	return item

# =========================================================
# USE ITEM
# =========================================================

func use_item(item: ItemInstance) -> bool:

	if item == null:
		return false

	if item.item_data == null:
		return false

	var item_data: ItemData = item.item_data


	# =====================================================
	# WEAPON
	# =====================================================

	if item_data.item_type == ItemData.ItemType.WEAPON:

		return equip_weapon(item)


	# =====================================================
	# EQUIPMENT
	# =====================================================

	if item_data.equipment_type != ItemData.EquipmentType.NONE:

		return equip(item)


	# =====================================================
	# ITEM KHÔNG PHẢI EQUIPMENT
	# =====================================================

	return false


# =========================================================
# EQUIP WEAPON
# =========================================================

func equip_weapon(item: ItemInstance) -> bool:

	if item == null:
		return false

	if item.item_data == null:
		return false

	var item_data: ItemData = item.item_data


	# =====================================================
	# KIỂM TRA ITEM
	# =====================================================

	if item_data.item_type != ItemData.ItemType.WEAPON:
		return false

	if item_data.equipment_type != ItemData.EquipmentType.WEAPON:
		return false


	# =====================================================
	# TAY TRÁI
	# =====================================================

	if weapon_left == null:

		weapon_left = item

		_sync_player_weapon_hands()

		print(
			"EQUIP WEAPON: ",
			item_data.item_name,
			" -> WeaponLeft"
		)

		return true


	# =====================================================
	# TAY PHẢI
	# =====================================================

	if weapon_right == null:

		weapon_right = item

		_sync_player_weapon_hands()

		print(
			"EQUIP WEAPON: ",
			item_data.item_name,
			" -> WeaponRight"
		)

		return true


	# =====================================================
	# CẢ HAI TAY ĐỀU ĐẦY
	# =====================================================

	print(
		"KHÔNG THỂ EQUIP WEAPON: CẢ HAI TAY ĐỀU ĐẦY"
	)

	return false
	
func _sync_player_weapon_hands() -> void:

	var player := _get_player()

	if player == null:
		return

	player.set_left_hand_item(weapon_left)
	player.set_right_hand_item(weapon_right)

func _get_player() -> Node:
	# Multiplayer: uu tien Player local, tranh equip nham vao remote player.
	for node in get_tree().get_nodes_in_group("player"):
		if not is_instance_valid(node):
			continue
		if node.get("network_managed") == true and node.get("is_local_player") == true:
			return node

	# Fallback cho che do single-player.
	for node in get_tree().get_nodes_in_group("player"):
		if is_instance_valid(node) and node.get("network_managed") != true:
			return node
	return null
