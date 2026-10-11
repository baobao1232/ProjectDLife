class_name InventorySlot
extends TextureButton


@onready var item_icon: TextureRect = $ItemIcon


# =========================================================
# DATA
# =========================================================

var current_item: ItemInstance = null
var current_amount: int = 0

# Vị trí của slot trong InventoryManager
var slot_index: int = -1

var is_hovered: bool = false
var is_drop_target: bool = false
var original_scale: Vector2
var is_drag_source: bool = false

# =========================================================
# READY
# =========================================================

func _ready() -> void:
	if item_icon.material != null:
		item_icon.material = item_icon.material.duplicate()
		
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	item_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	item_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE

	item_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	item_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	pivot_offset = size / 2.0
	original_scale = scale

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	add_to_group("inventory_slots")

	clear_slot()

# =========================================================
# SET ITEM
# =========================================================

func set_item(
	item: ItemInstance,
	amount: int
) -> void:

	if item == null:

		clear_slot()
		return

	if item.item_data == null:

		clear_slot()
		return

	current_item = item
	current_amount = amount

	item_icon.texture = item.item_data.icon
	item_icon.visible = true

	update_rarity_shader()

# =========================================================
# CLEAR
# =========================================================

func clear_slot() -> void:

	current_item = null
	current_amount = 0

	item_icon.texture = null
	item_icon.visible = false
	update_rarity_shader()
# =========================================================
# DRAG DATA
# =========================================================

func _get_drag_data(_at_position: Vector2) -> Variant:

	if current_item == null:
		return null

	if current_item.item_data == null:
		return null

	var item_data: ItemData = current_item.item_data

	print(
		"DRAG START: ",
		item_data.item_name,
		" | Slot: ",
		slot_index
	)

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
		"type": "inventory_item",
		"item": current_item,
		"amount": current_amount,
		"source_slot": slot_index
	}
	
# =========================================================
# KIỂM TRA DROP
# =========================================================

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		set_drop_highlight(false)
		return false

	if not data.has("type"):
		set_drop_highlight(false)
		return false

	var drop_type: String = data["type"]

	if drop_type == "inventory_item":
		if not data.has("source_slot"):
			set_drop_highlight(false)
			return false

		var source_slot: int = data["source_slot"]

		if source_slot == slot_index:
			return false

		if source_slot < 0:
			set_drop_highlight(false)
			return false

		if source_slot >= Inventorymanager.slots.size():
			set_drop_highlight(false)
			return false

		set_drop_highlight(true)
		return true

	if drop_type == "equipment_item":
		if not data.has("item"):
			set_drop_highlight(false)
			return false

		if not data.has("equipment_slot"):
			set_drop_highlight(false)
			return false

		var item: ItemInstance = data["item"]

		if item == null:
			set_drop_highlight(false)
			return false

		if item.item_data == null:
			set_drop_highlight(false)
			return false

		# Chỉ cho tháo equipment vào SLOT TRỐNG
		if current_item != null:
			set_drop_highlight(false)
			return false

		set_drop_highlight(true)
		return true

	set_drop_highlight(false)
	return false
	
# =========================================================
# DROP
# =========================================================

func _drop_data(
	_at_position: Vector2,
	data: Variant
) -> void:
	if not _can_drop_data(_at_position, data):
		return

	var drop_type: String = data["type"]

	if drop_type == "inventory_item":
		var source_slot: int = data["source_slot"]

		print(
			"DROP INVENTORY: Slot ",
			source_slot,
			" -> Slot ",
			slot_index
		)

		var success := Inventorymanager.move_item(
			source_slot,
			slot_index
		)

		if not success:
			return

		var inventory_ui := get_tree().get_first_node_in_group(
			"inventory_ui"
		) as InventoryUI

		if inventory_ui != null:
			inventory_ui.refresh_inventory()
			inventory_ui.hide_item_tooltip()

		return

	if drop_type == "equipment_item":
		var item: ItemInstance = data["item"]
		var equipment_slot_name: String = data["equipment_slot"]

		if item == null or item.item_data == null:
			return

		print(
			"DROP EQUIPMENT: ",
			item.item_data.item_name,
			" | ",
			equipment_slot_name,
			" -> Inventory Slot ",
			slot_index
		)

		if current_item != null:
			print(
				"EQUIPMENT DROP FAILED: Inventory Slot ",
				slot_index,
				" đang có item"
			)
			return

		var equipment_slot_node: EquipmentSlot = null

		var all_equipment_slots := get_tree().get_nodes_in_group(
			"equipment_slots"
		)

		for node in all_equipment_slots:
			if node is EquipmentSlot:
				if node.name == equipment_slot_name:
					equipment_slot_node = node
					break

		if equipment_slot_node == null:
			print(
				"EQUIPMENT DROP FAILED: Không tìm thấy ",
				equipment_slot_name
			)
			return

		if equipment_slot_node.current_item == null:
			print(
				"EQUIPMENT DROP FAILED: Equipment slot đã trống"
			)
			return

		if equipment_slot_node.current_item.item_data == null:
			return

		if equipment_slot_node.current_item.item_data.id != item.item_data.id:
			print(
				"EQUIPMENT DROP FAILED: Item không khớp"
			)
			return

		var unequipped_item := Equipmentmanager.unequip_from_slot(
			equipment_slot_name
		)

		if unequipped_item == null:
			print(
				"EQUIPMENT DROP FAILED: Không tháo được equipment"
			)
			return

		Inventorymanager.slots[slot_index]["item"] = unequipped_item
		Inventorymanager.slots[slot_index]["amount"] = 1

		equipment_slot_node.set_item(null)

		for node in all_equipment_slots:
			if node is EquipmentSlot:
				node.refresh_slot()

		var inventory_ui := get_tree().get_first_node_in_group(
			"inventory_ui"
		) as InventoryUI

		if inventory_ui != null:
			inventory_ui.refresh_inventory()
			inventory_ui.hide_item_tooltip()

		print(
			"EQUIPMENT UNEQUIPPED: ",
			unequipped_item.item_data.item_name,
			" -> Inventory Slot ",
			slot_index
		)

		return

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

		# Tắt drop target của các slot khác
		# NHƯNG KHÔNG TẮT slot đang là nguồn kéo
		for node in get_tree().get_nodes_in_group("inventory_slots"):

			if node != self and node is InventorySlot:

				if not node.is_drag_source:

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

		# Drag kết thúc → reset TẤT CẢ slot
		for node in get_tree().get_nodes_in_group("inventory_slots"):

			if node is InventorySlot:

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
