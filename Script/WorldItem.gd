class_name WorldItem
extends Area2D

@export var item_instance: ItemInstance

@onready var sprite: Sprite2D = $Sprite2D
@onready var item_name_label: Label = $ItemNameLabel
@onready var interact_button: AnimatedSprite2D = $ItemNameLabel/InteractButton


func _ready() -> void:

	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	z_index = 0

	item_name_label.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	item_name_label.z_index = 1000
	item_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	interact_button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	interact_button.z_index = 1
	interact_button.visible = false
	interact_button.stop()
	interact_button.centered = true

	item_name_label.modulate = Color.WHITE
	item_name_label.self_modulate = Color.WHITE

	item_name_label.visible = false
	interact_button.visible = false

	if item_instance == null:
		print("ERROR: WorldItem chưa có ItemInstance: ", name)
		return

	# =====================================================
	# ITEM ĐẶT SẴN TRÊN MAP CHƯA ĐƯỢC ROLL
	# =====================================================

	if item_instance.item_data == null:
		print("ERROR: ItemInstance chưa có ItemData: ", name)
		return

	if item_instance.unique_id.is_empty():
		var item_data_source: ItemData = item_instance.item_data
		item_instance = ItemFactory.create_item(item_data_source)

		if item_instance == null:
			print("ERROR: Không tạo được ItemInstance: ", name)
			return

	var item_data: ItemData = item_instance.item_data

	sprite.texture = item_data.world_sprite
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	item_name_label.text = item_data.item_name

	print(
		"WorldItem READY: ",
		item_data.item_name,
		" | UID: ",
		item_instance.unique_id,
		" | Rarity: ",
		item_instance.rarity,
		" | Stats: ",
		item_instance.rolled_stats.size()
	)

# =========================================================
# HIỆN BUTTON E
# =========================================================

func show_interact_button() -> void:

	if interact_button == null:
		return

	interact_button.visible = true
	interact_button.play("default")


# =========================================================
# ẨN BUTTON E
# =========================================================

func hide_interact_button() -> void:

	if interact_button == null:
		return

	interact_button.visible = false
	interact_button.stop()


# =========================================================
# INTERACT
# =========================================================

func interact() -> void:

	if item_instance == null:
		print("Không thể nhặt: WorldItem không có ItemInstance")
		return

	if item_instance.item_data == null:
		print("Không thể nhặt: ItemInstance không có ItemData")
		return

	var item_data: ItemData = item_instance.item_data

	print(
		"NHẶT ITEM: ",
		item_data.item_name,
		" | UID: ",
		item_instance.unique_id,
		" | Rarity: ",
		item_instance.rarity
	)

	var success: bool = Inventorymanager.add_item(
		item_instance,
		1
	)

	if not success:
		print(
			"KHÔNG THỂ NHẶT: Inventory đầy - ",
			item_data.item_name
		)
		return

	print(
		"NHẶT THÀNH CÔNG: ",
		item_data.item_name,
		" | UID: ",
		item_instance.unique_id,
		" | Rarity: ",
		item_instance.rarity
	)

	queue_free()
