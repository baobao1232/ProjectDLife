extends Control
class_name InventoryUI


# =========================================================
# NODE
# =========================================================
@onready var inventory_panel: Control = $Panel
@onready var title: Control = $Panel/Title
@onready var slots_grid: GridContainer = $Panel/InventoryPanel/SlotsScroll/MarginContainer/SlotsGrid
@onready var item_tooltip: ItemTooltip = $ItemTooltip


# =========================================================
# EQUIPMENT SLOTS
# =========================================================

@onready var helmet_slot: EquipmentSlot = $Panel/EquipmentPanel/HelmetSlot
@onready var armor_slot: EquipmentSlot = $Panel/EquipmentPanel/ArmorSlot
@onready var pants_slot: EquipmentSlot = $Panel/EquipmentPanel/PantsSlot
@onready var boots_slot: EquipmentSlot = $Panel/EquipmentPanel/BootsSlot

@onready var weapon_left_slot: EquipmentSlot = $Panel/EquipmentPanel/WeaponLeftSlot
@onready var weapon_right_slot: EquipmentSlot = $Panel/EquipmentPanel/WeaponRightSlot

@onready var backpack_slot: EquipmentSlot = $Panel/EquipmentPanel/BackpackSlot

@onready var ring_1_slot: EquipmentSlot = $Panel/EquipmentPanel/RingSlot1
@onready var ring_2_slot: EquipmentSlot = $Panel/EquipmentPanel/RingSlot2

@onready var necklace_slot: EquipmentSlot = $Panel/EquipmentPanel/NecklaceSlot


# =========================================================
# INVENTORY SLOT
# =========================================================

const SLOT_SCENE: PackedScene = preload(
	"res://UI/InventorySlot.tscn"
)


# =========================================================
# DATA
# =========================================================

var slots: Array[InventorySlot] = []

# Slot đang hover
var hovered_slot: Control = null
var is_dragging_inventory: bool = false
var drag_offset: Vector2 = Vector2.ZERO

# =========================================================
# READY
# =========================================================

func _ready() -> void: 
 
	visible = false 
	
	# =====================================================
	# INVENTORY - SCALE + CĂN GIỮA MÀN HÌNH
	# =====================================================
	
	inventory_panel.scale = Vector2(1.3, 1.3)
	
	var viewport_size := get_viewport_rect().size
	var scaled_size := inventory_panel.size * inventory_panel.scale
	
	inventory_panel.global_position = (
		viewport_size - scaled_size
	) / 2.0
	
	add_to_group("inventory_ui") 
 
	item_tooltip.hide_tooltip() 
 
	# ===================================================== 
	# TẠO SLOT 
	# ===================================================== 
 
	rebuild_slots() 
 
 
	# ===================================================== 
	# EQUIPMENT 
	# ===================================================== 
 
	refresh_equipment() 
	 
	# ===================================================== 
	# EQUIPMENT HOVER 
	# ===================================================== 
 
	helmet_slot.mouse_entered.connect( 
		_on_equipment_mouse_entered.bind(helmet_slot) 
	) 
 
	armor_slot.mouse_entered.connect( 
		_on_equipment_mouse_entered.bind(armor_slot) 
	) 
 
	pants_slot.mouse_entered.connect( 
		_on_equipment_mouse_entered.bind(pants_slot) 
	) 
 
	boots_slot.mouse_entered.connect( 
		_on_equipment_mouse_entered.bind(boots_slot) 
	) 
 
	weapon_left_slot.mouse_entered.connect( 
		_on_equipment_mouse_entered.bind(weapon_left_slot) 
	) 
 
	weapon_right_slot.mouse_entered.connect( 
		_on_equipment_mouse_entered.bind(weapon_right_slot) 
	) 
 
	backpack_slot.mouse_entered.connect( 
		_on_equipment_mouse_entered.bind(backpack_slot) 
	) 
 
	ring_1_slot.mouse_entered.connect( 
		_on_equipment_mouse_entered.bind(ring_1_slot) 
	) 
 
	ring_2_slot.mouse_entered.connect( 
		_on_equipment_mouse_entered.bind(ring_2_slot) 
	) 
 
	necklace_slot.mouse_entered.connect( 
		_on_equipment_mouse_entered.bind(necklace_slot) 
	) 
 
	print( 
		"InventoryUI READY - Slots: ", 
		slots.size() 
	) 
	 
	print("========== EQUIPMENT HOVER DEBUG ==========") 
 
	var equipment_slots: Array[EquipmentSlot] = [ 
		helmet_slot, 
		armor_slot, 
		pants_slot, 
		boots_slot, 
		weapon_left_slot, 
		weapon_right_slot, 
		backpack_slot, 
		ring_1_slot, 
		ring_2_slot, 
		necklace_slot 
	] 
 
	for slot in equipment_slots: 
 
		print( 
			slot.name, 
			" | mouse_filter=", slot.mouse_filter, 
			" | visible=", slot.visible, 
			" | position=", slot.global_position, 
			" | size=", slot.size, 
			" | item=", slot.current_item 
		) 
 
		print( 
			"  rect=", slot.get_global_rect() 
		) 
 
		slot.mouse_entered.connect( 
			func() -> void: 
				print(">>> EQUIPMENT HOVER:", slot.name) 
		) 
 
	print("==========================================") 
# =========================================================
# PROCESS
# =========================================================
# Kiểm tra chuột đang ở:
#
# 1. InventorySlot
# 2. ItemTooltip
#
# Nếu ở một trong hai → giữ tooltip.
#
# Nếu ra ngoài cả hai → ẩn tooltip.
# =========================================================

func _process(_delta: float) -> void:

	if not item_tooltip.visible:
		return

	if hovered_slot == null:
		return

	var mouse_position := get_viewport().get_mouse_position()

	# =====================================================
	# CHUỘT Ở SLOT
	# =====================================================

	var mouse_on_slot := (
		hovered_slot.get_global_rect().has_point(
			mouse_position
		)
	)

	# =====================================================
	# CHUỘT Ở TOOLTIP
	# =====================================================

	var mouse_on_tooltip := (
		item_tooltip.get_global_rect().has_point(
			mouse_position
		)
	)

	# =====================================================
	# VẪN Ở SLOT HOẶC TOOLTIP
	# =====================================================

	if mouse_on_slot or mouse_on_tooltip:
		return

	# =====================================================
	# RA NGOÀI
	# =====================================================

	hovered_slot = null
	item_tooltip.hide_tooltip()

func rebuild_slots() -> void:

	for child in slots_grid.get_children():

		child.queue_free()


	slots.clear()


	slots_grid.columns = 5


	var slot_count: int = (
		Inventorymanager.get_slot_count()
	)


	print(
		"InventoryUI BUILD SLOTS: ",
		slot_count
	)


	# =====================================================
	# TẠO TỪNG SLOT
	# =====================================================

	for i in range(slot_count):

		var slot_node := SLOT_SCENE.instantiate()

		var slot := slot_node as InventorySlot


		if slot == null:

			print(
				"ERROR: InventorySlot.tscn không dùng InventorySlot.gd"
			)

			continue


		slot.name = "Slot_%d" % i
		slot.slot_index = i

		slot.custom_minimum_size = Vector2(
			42,
			42
		)


		# =================================================
		# HOVER
		# =================================================

		slot.mouse_entered.connect(
			_on_slot_mouse_entered.bind(slot)
		)


		slots_grid.add_child(slot)

		slots.append(slot)


# =========================================================
# HOVER VÀO ITEM
# =========================================================

func _on_equipment_mouse_entered(
	slot: EquipmentSlot
) -> void:

	if slot.current_item == null:
		return

	# =====================================================
	# SLOT ĐANG HOVER
	# =====================================================

	hovered_slot = slot

	# =====================================================
	# HIỆN TOOLTIP
	# =====================================================

	item_tooltip.show_item(
		slot.current_item,
		1,
		-1,
		slot.name
	)

	# =====================================================
	# VỊ TRÍ BÊN DƯỚI EQUIPMENT SLOT
	# =====================================================

	var slot_rect := slot.get_global_rect()

	var tooltip_global_position := Vector2(
		slot_rect.position.x,
		slot_rect.position.y + slot_rect.size.y + 1.0
	)

	var tooltip_parent := item_tooltip.get_parent() as Control

	item_tooltip.position = (
		tooltip_parent
		.get_global_transform()
		.affine_inverse()
		* tooltip_global_position
	)

	item_tooltip.position.x = roundf(
		item_tooltip.position.x
	)

	item_tooltip.position.y = roundf(
		item_tooltip.position.y
	)
	
func _on_slot_mouse_entered(
	slot: InventorySlot
) -> void:

	if slot.current_item == null:
		return

	# =====================================================
	# SLOT ĐANG HOVER
	# =====================================================

	hovered_slot = slot

	# =====================================================
	# HIỆN TOOLTIP
	# =====================================================

	item_tooltip.show_item(
		slot.current_item,
		slot.current_amount,
		slot.slot_index
	)

	# =====================================================
	# VỊ TRÍ BÊN DƯỚI SLOT
	# =====================================================

	var slot_rect := slot.get_global_rect()

	var tooltip_global_position := Vector2(
		slot_rect.position.x,
		slot_rect.position.y + slot_rect.size.y + 1.0
	)

	var tooltip_parent := item_tooltip.get_parent() as Control

	item_tooltip.position = (
		tooltip_parent
		.get_global_transform()
		.affine_inverse()
		* tooltip_global_position
	)

	item_tooltip.position.x = roundf(
		item_tooltip.position.x
	)

	item_tooltip.position.y = roundf(
		item_tooltip.position.y
	)
	
# =========================================================
# ẨN TOOLTIP
# =========================================================

func hide_item_tooltip() -> void:

	hovered_slot = null

	item_tooltip.hide_tooltip()


# =========================================================
# MỞ / ĐÓNG INVENTORY
# =========================================================

func toggle_inventory() -> void:

	visible = not visible


	print(
		"Inventory visible: ",
		visible
	)


	if visible:

		refresh_inventory()

		refresh_equipment()
		
		

	else:

		hide_item_tooltip()


# =========================================================
# REFRESH INVENTORY
# =========================================================

func refresh_inventory() -> void:

	var slot_count: int = (
		Inventorymanager.get_slot_count()
	)

	# =====================================================
	# SỐ SLOT THAY ĐỔI
	# =====================================================

	if slots.size() != slot_count:

		# Tooltip không được giữ item cũ
		hide_item_tooltip()

		rebuild_slots()

	# =====================================================
	# CẬP NHẬT ITEM
	# =====================================================

	for i in range(slots.size()):

		var item: ItemInstance = (
			Inventorymanager.get_item(i)
		)

		var amount: int = (
			Inventorymanager.get_amount(i)
		)

		if item != null:

			slots[i].set_item(
				item,
				amount
			)

		else:

			slots[i].clear_slot()

# =========================================================
# REFRESH EQUIPMENT
# =========================================================

func refresh_equipment() -> void:

	# =====================================================
	# HELMET
	# =====================================================

	helmet_slot.set_item(
		Equipmentmanager.helmet
	)

	# =====================================================
	# ARMOR
	# =====================================================

	armor_slot.set_item(
		Equipmentmanager.armor
	)

	# =====================================================
	# PANTS
	# =====================================================

	pants_slot.set_item(
		Equipmentmanager.pants
	)

	# =====================================================
	# BOOTS
	# =====================================================

	boots_slot.set_item(
		Equipmentmanager.boots
	)

	# =====================================================
	# WEAPON LEFT
	# =====================================================

	weapon_left_slot.set_item(
		Equipmentmanager.weapon_left
	)

	# =====================================================
	# WEAPON RIGHT
	# =====================================================

	weapon_right_slot.set_item(
		Equipmentmanager.weapon_right
	)

	# =====================================================
	# BACKPACK
	# =====================================================

	backpack_slot.set_item(
		Equipmentmanager.backpack
	)

	# =====================================================
	# RING 1
	# =====================================================

	ring_1_slot.set_item(
		Equipmentmanager.ring_1
	)

	# =====================================================
	# RING 2
	# =====================================================

	ring_2_slot.set_item(
		Equipmentmanager.ring_2
	)

	# =====================================================
	# NECKLACE
	# =====================================================

	necklace_slot.set_item(
		Equipmentmanager.necklace
	)

func _show_tooltip_below_slot(
	slot: Control,
	item: ItemInstance,
	amount: int
) -> void:

	hovered_slot = slot

	var inventory_slot_index: int = -1

	if slot is InventorySlot:
		inventory_slot_index = slot.slot_index

	item_tooltip.show_item(
		item,
		amount,
		inventory_slot_index
	)

	var slot_rect := slot.get_global_rect()

	var tooltip_global_position := Vector2(
		slot_rect.position.x,
		slot_rect.end.y + 1.0
	)

	var tooltip_parent := item_tooltip.get_parent() as Control

	item_tooltip.position = (
		tooltip_parent
		.get_global_transform()
		.affine_inverse()
		* tooltip_global_position
	)

	item_tooltip.position.x = roundf(item_tooltip.position.x)
	item_tooltip.position.y = roundf(item_tooltip.position.y)

# =========================================================
# DRAG INVENTORY
# KÉO BẰNG THANH TITLE
# =========================================================

func _input(event: InputEvent) -> void:

	if not visible:
		return

	# =====================================================
	# NHẤN CHUỘT TRÁI
	# =====================================================

	if event is InputEventMouseButton:

		if event.button_index != MOUSE_BUTTON_LEFT:
			return

		if event.pressed:

			# Chỉ bắt đầu kéo khi click vào Title
			if title.get_global_rect().has_point(
				event.global_position
			):

				is_dragging_inventory = true

				drag_offset = (
					event.global_position
					- inventory_panel.global_position
				)

				hide_item_tooltip()

				get_viewport().set_input_as_handled()

		else:

			is_dragging_inventory = false

		return

	# =====================================================
	# KÉO
	# =====================================================

	if event is InputEventMouseMotion:

		if not is_dragging_inventory:
			return

		inventory_panel.global_position = (
			event.global_position
			- drag_offset
		)

		get_viewport().set_input_as_handled()
