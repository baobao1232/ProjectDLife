class_name EquipmentSlot
extends TextureButton


@onready var item_icon: TextureRect = $ItemIcon


var current_item: ItemInstance = null
var equipment_type: ItemData.EquipmentType = ItemData.EquipmentType.NONE
var original_scale: Vector2
var is_hovered: bool = false
var is_drop_target: bool = false
var original_icon_scale: Vector2
var is_drag_source: bool = false

func _ready() -> void:
	if item_icon.material != null:
		item_icon.material = item_icon.material.duplicate()
		
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	item_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	item_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE

	item_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	original_icon_scale = item_icon.scale

	add_to_group("equipment_slots")

	original_scale = scale
	pivot_offset = size / 2.0

	setup_equipment_type()
	refresh_slot()

# =========================================================
# XÁC ĐỊNH SLOT
# =========================================================

func setup_equipment_type() -> void:

	match name:

		"HelmetSlot":
			equipment_type = ItemData.EquipmentType.HELMET

		"ArmorSlot":
			equipment_type = ItemData.EquipmentType.ARMOR

		"PantsSlot":
			equipment_type = ItemData.EquipmentType.PANTS

		"BootsSlot":
			equipment_type = ItemData.EquipmentType.BOOTS

		"WeaponLeftSlot":
			equipment_type = ItemData.EquipmentType.WEAPON

		"WeaponRightSlot":
			equipment_type = ItemData.EquipmentType.WEAPON

		"BackpackSlot":
			equipment_type = ItemData.EquipmentType.BACKPACK

		"RingSlot1":
			equipment_type = ItemData.EquipmentType.RING

		"RingSlot2":
			equipment_type = ItemData.EquipmentType.RING

		"NecklaceSlot":
			equipment_type = ItemData.EquipmentType.NECKLACE

		_:
			equipment_type = ItemData.EquipmentType.NONE


# =========================================================
# REFRESH TỪ EQUIPMENT MANAGER
# =========================================================

func refresh_slot() -> void:

	var item := Equipmentmanager.get_equipment_from_slot(name)

	set_item(item)

# =========================================================
# KIỂM TRA ITEM
# =========================================================

func can_equip(item: ItemInstance) -> bool:

	if item == null:
		return false

	if item.item_data == null:
		return false

	return item.item_data.equipment_type == equipment_type

# =========================================================
# HIỂN THỊ ITEM
# =========================================================

func set_item(item: ItemInstance) -> void:

	current_item = item

	if item == null:
		clear_slot()
		return

	if item.item_data == null:
		clear_slot()
		return

	var item_data: ItemData = item.item_data

	if not can_equip(item):

		print(
			"KHÔNG THỂ HIỂN THỊ: ",
			item_data.item_name,
			" → ",
			name
		)

		clear_slot()
		return

	item_icon.texture = item_data.icon
	item_icon.visible = true

	item_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	item_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# GIỮ NGUYÊN SCALE ĐÃ SET TRONG SCENE
	item_icon.scale = original_icon_scale

	# Pivot giữa icon để khi hover phóng ra đều 2 phía
	item_icon.pivot_offset = item_icon.size / 2.0

	update_rarity_shader()

	print(
		"EQUIPMENT SLOT SHOW: ",
		name,
		" → ",
		item_data.item_name,
		" | SIZE: ",
		size
	)
	
# =========================================================
# DRAG ITEM RA KHỎI EQUIPMENT
# =========================================================

func _get_drag_data(_at_position: Vector2) -> Variant:

	if current_item == null:
		return null

	if current_item.item_data == null:
		return null

	var item_data: ItemData = current_item.item_data

	print(
		"EQUIPMENT DRAG START: ",
		item_data.item_name,
		" | Slot: ",
		name
	)

	# Slot này là nguồn của drag
	is_drag_source = true
	update_highlight()

	var preview := TextureRect.new()

	preview.texture = item_data.icon
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.custom_minimum_size = Vector2(48, 48)
	preview.size = Vector2(48, 48)
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE

	set_drag_preview(preview)

	return {
		"type": "equipment_item",
		"item": current_item,
		"equipment_slot": name
	}
# =========================================================
# CAN DROP DATA
# =========================================================

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:

	if typeof(data) != TYPE_DICTIONARY:
		set_drop_highlight(false)
		return false

	if not data.has("type"):
		set_drop_highlight(false)
		return false

	if not data.has("item"):
		set_drop_highlight(false)
		return false

	var item: ItemInstance = data["item"]

	if item == null:
		set_drop_highlight(false)
		return false

	if item.item_data == null:
		set_drop_highlight(false)
		return false


	# =====================================================
	# EQUIPMENT → EQUIPMENT
	# CHỈ CHO PHÉP SWAP 2 WEAPON SLOT
	# =====================================================

	if data["type"] == "equipment_item":

		if not data.has("equipment_slot"):
			set_drop_highlight(false)
			return false

		var source_slot: String = data["equipment_slot"]

		var is_weapon_swap := (
			(source_slot == "WeaponLeftSlot"
			or source_slot == "WeaponRightSlot")
			and
			(name == "WeaponLeftSlot"
			or name == "WeaponRightSlot")
		)

		if not is_weapon_swap:
			set_drop_highlight(false)
			return false

		# Không cần swap chính nó
		if source_slot == name:
			set_drop_highlight(false)
			return false

		var valid := can_equip(item)

		set_drop_highlight(valid)

		return valid


	# =====================================================
	# INVENTORY → EQUIPMENT
	# =====================================================

	if data["type"] == "inventory_item":

		var valid := can_equip(item)

		set_drop_highlight(valid)

		return valid


	set_drop_highlight(false)
	return false
	
# =========================================================
# DROP DATA
# =========================================================

func _drop_data(
	_at_position: Vector2,
	data: Variant
) -> void:

	if not _can_drop_data(_at_position, data):
		return


	# =====================================================
	# EQUIPMENT → EQUIPMENT
	# SWAP WEAPON LEFT ↔ RIGHT
	# =====================================================

	if data["type"] == "equipment_item":

		var source_slot: String = data["equipment_slot"]

		if (
			(source_slot != "WeaponLeftSlot"
			and source_slot != "WeaponRightSlot")
			or
			(name != "WeaponLeftSlot"
			and name != "WeaponRightSlot")
		):

			return


		if source_slot == name:
			return


		var source_item: ItemInstance = (
			Equipmentmanager.get_equipment_from_slot(source_slot)
		)

		var target_item: ItemInstance = (
			Equipmentmanager.get_equipment_from_slot(name)
		)


		if source_item == null:
			return


		# =================================================
		# SWAP 2 WEAPON SLOT
		# =================================================

		var source_is_left := (
			source_slot == "WeaponLeftSlot"
		)

		var target_is_left := (
			name == "WeaponLeftSlot"
		)


		if source_is_left:

			Equipmentmanager.weapon_left = target_item
			Equipmentmanager.weapon_right = source_item

		elif target_is_left:

			Equipmentmanager.weapon_left = source_item
			Equipmentmanager.weapon_right = target_item


		# =================================================
		# SYNC PLAYER
		# =================================================

		Equipmentmanager._sync_player_weapon_hands()


		# =================================================
		# REFRESH 2 EQUIPMENT SLOT
		# =================================================

		for node in get_tree().get_nodes_in_group("equipment_slots"):

			if node is EquipmentSlot:

				if (
					node.name == "WeaponLeftSlot"
					or node.name == "WeaponRightSlot"
				):

					node.refresh_slot()


		# =================================================
		# REFRESH INVENTORY UI
		# =================================================

		var inventory_ui := get_tree().get_first_node_in_group(
			"inventory_ui"
		) as InventoryUI

		if inventory_ui != null:
			inventory_ui.hide_item_tooltip()


		print(
			"WEAPON SWAP: ",
			source_slot,
			" ↔ ",
			name
		)

		return


	# =====================================================
	# INVENTORY → EQUIPMENT
	# =====================================================

	if data["type"] != "inventory_item":
		return


	var item: ItemInstance = data["item"]
	var source_slot: int = data["source_slot"]


	if item == null:
		return

	if item.item_data == null:
		return


	var item_data: ItemData = item.item_data


	print(
		"EQUIPMENT DROP: ",
		item_data.item_name,
		" | Inventory Slot: ",
		source_slot,
		" -> ",
		name
	)


	# =====================================================
	# KIỂM TRA SOURCE SLOT
	# =====================================================

	var source_item: ItemInstance = Inventorymanager.get_item(source_slot)
	var source_amount := Inventorymanager.get_amount(source_slot)


	if source_item == null:

		print(
			"EQUIPMENT DROP FAILED: source slot trống"
		)

		return


	if source_item.unique_id != item.unique_id:

		print(
			"EQUIPMENT DROP FAILED: source slot không còn item kéo"
		)

		return


	if source_amount <= 0:

		print(
			"EQUIPMENT DROP FAILED: amount không hợp lệ"
		)

		return


	# =====================================================
	# ITEM ĐANG CÓ TRONG EQUIPMENT
	# =====================================================

	var old_item: ItemInstance = (
		Equipmentmanager.get_equipment_from_slot(name)
	)


	# =====================================================
	# EQUIPMENT SLOT TRỐNG
	# =====================================================

	if old_item == null:

		var equipped := Equipmentmanager.equip_to_slot(
			name,
			item
		)

		if not equipped:

			print(
				"EQUIPMENT DROP FAILED: không equip được ",
				item_data.item_name
			)

			return


		var removed := Inventorymanager.remove_item_from_slot(
			source_slot,
			1
		)

		if not removed:

			Equipmentmanager.unequip_from_slot(name)

			print(
				"EQUIPMENT DROP FAILED: không xóa được inventory"
			)

			return


	# =====================================================
	# EQUIPMENT SLOT CÓ ITEM
	# → SWAP VỚI INVENTORY
	# =====================================================

	else:

		var destination_slot := source_slot

		if source_amount > 1:

			destination_slot = Inventorymanager.find_empty_slot()

			if destination_slot == -1:

				print(
					"SWAP FAILED: Inventory không có slot trống"
				)

				return


		# -------------------------------------------------
		# BACKPACK
		# -------------------------------------------------

		if name == "BackpackSlot":

			if not item_data.is_backpack:

				print(
					"SWAP FAILED: item không phải backpack"
				)

				return


			if not Inventorymanager.equip_backpack(
				item_data.backpack_slots
			):

				print(
					"SWAP FAILED: không thể đổi backpack"
				)

				return


			Equipmentmanager.backpack = item


		# -------------------------------------------------
		# EQUIPMENT THƯỜNG
		# -------------------------------------------------

		else:

			if not Equipmentmanager.equip_to_slot(
				name,
				item
			):

				print(
					"SWAP FAILED: không equip được item mới"
				)

				return


		# -------------------------------------------------
		# XÓA ITEM MỚI KHỎI INVENTORY
		# -------------------------------------------------

		var removed := Inventorymanager.remove_item_from_slot(
			source_slot,
			1
		)

		if not removed:

			print(
				"SWAP FAILED: không xóa được item mới khỏi inventory"
			)

			return


		# -------------------------------------------------
		# TRẢ ITEM CŨ VỀ INVENTORY
		# -------------------------------------------------

		if not Inventorymanager.set_slot(
			destination_slot,
			old_item,
			1
		):

			# ROLLBACK
			Inventorymanager.set_slot(
				source_slot,
				item,
				source_amount
			)


			if name == "BackpackSlot":

				if old_item.item_data != null:

					Inventorymanager.equip_backpack(
						old_item.item_data.backpack_slots
					)

				Equipmentmanager.backpack = old_item

			else:

				Equipmentmanager.equip_to_slot(
					name,
					old_item
				)


			print(
				"SWAP FAILED: không thể trả item cũ vào inventory"
			)

			return


	# =====================================================
	# REFRESH EQUIPMENT
	# =====================================================

	refresh_slot()


	# =====================================================
	# REFRESH INVENTORY UI
	# =====================================================

	var inventory_ui := get_tree().get_first_node_in_group(
		"inventory_ui"
	) as InventoryUI

	if inventory_ui != null:

		inventory_ui.refresh_inventory()
		inventory_ui.hide_item_tooltip()


	print(
		"EQUIPMENT EQUIPPED: ",
		item_data.item_name,
		" -> ",
		name
	)

# =========================================================
# CLEAR SLOT
# =========================================================

func clear_slot() -> void:

	current_item = null

	item_icon.texture = null
	item_icon.visible = false
	item_icon.scale = original_icon_scale
	update_rarity_shader()
# =========================================================
# HOVER / SELECT
# =========================================================

func _on_mouse_entered() -> void:

	is_hovered = true
	update_highlight()


func _on_mouse_exited() -> void:

	is_hovered = false
	update_highlight()


func set_drop_highlight(active: bool) -> void:

	if active:

		# Chỉ giữ 1 drop target
		for node in get_tree().get_nodes_in_group("equipment_slots"):

			if node != self and node is EquipmentSlot:

				node.is_drop_target = false
				node.update_highlight()

	is_drop_target = active
	update_highlight()


func update_highlight() -> void:

	var active := (
		is_hovered
		or is_drop_target
		or is_drag_source
	)

	if active:

		pivot_offset = size / 2.0
		scale = original_scale * 1.12

	else:

		scale = original_scale


# =========================================================
# KẾT THÚC DRAG
# =========================================================

func _notification(what: int) -> void:

	if what == NOTIFICATION_DRAG_END:

		for node in get_tree().get_nodes_in_group("equipment_slots"):

			if node is EquipmentSlot:

				node.is_drag_source = false
				node.is_drop_target = false
				node.update_highlight()

func update_rarity_shader() -> void:

	var shader_material := item_icon.material as ShaderMaterial

	if shader_material == null:
		return

	if current_item == null:
		shader_material.set_shader_parameter(
			"rarity_effect",
			false
		)
		return

	# COMMON = không có hiệu ứng rarity
	if current_item.rarity == ItemData.Rarity.COMMON:

		shader_material.set_shader_parameter(
			"rarity_effect",
			false
		)

		return

	# Các rarity còn lại = bật hiệu ứng
	shader_material.set_shader_parameter(
		"rarity_effect",
		true
	)

	var rarity_color: Color = Inventorymanager.get_rarity_color(
		current_item
	)

	shader_material.set_shader_parameter(
		"outline_color",
		rarity_color
	)
