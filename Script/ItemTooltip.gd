extends Panel
class_name ItemTooltip


# =========================================================
# NODE
# =========================================================
var current_slot_index: int = -1

@onready var margin_container: MarginContainer = $MarginContainer

@onready var item_icon: TextureRect = (
	$MarginContainer/VBoxContainer/ItemHeader/ItemIcon
)

@onready var item_name_label: Label = (
	$MarginContainer/VBoxContainer/ItemHeader/ItemInfo/ItemName
)

@onready var item_rarity_label: Label = (
	$MarginContainer/VBoxContainer/ItemHeader/ItemInfo/ItemRarity
)


# =========================================================
# STATS
# =========================================================

@onready var stats_grid: GridContainer = (
	$MarginContainer/VBoxContainer/Stats
)

# =========================================================
# DESCRIPTION
# =========================================================

@onready var description_label: Label = (
	$MarginContainer/VBoxContainer/Description
)

# =========================================================
# BUTTON
# =========================================================

@onready var use_button: Button = (
	$MarginContainer/VBoxContainer/Buttons/UseButton
)

@onready var drop_button: Button = (
	$MarginContainer/VBoxContainer/Buttons/DropButton
)


# =========================================================
# DATA
# =========================================================

var current_item: ItemInstance = null
var current_amount: int = 0
var current_equipment_slot: String = ""
var current_is_equipment: bool = false

# =========================================================
# READY
# =========================================================

func _ready() -> void:

	visible = false

	mouse_filter = Control.MOUSE_FILTER_STOP


	# =====================================================
	# NODE
	# =====================================================

	var vbox := (
		$MarginContainer/VBoxContainer
		as VBoxContainer
	)

	var item_header := (
		$MarginContainer/VBoxContainer/ItemHeader
		as HBoxContainer
	)


	# =====================================================
	# TOOLTIP SIZE
	# WIDTH GIỮ THEO SCENE
	# HEIGHT TỰ TÍNH THEO CONTENT
	# =====================================================

	custom_minimum_size.y = 0


	# =====================================================
	# MARGIN CONTAINER
	# =====================================================

	margin_container.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	margin_container.size_flags_vertical = (
		Control.SIZE_SHRINK_BEGIN
	)


	# =====================================================
	# VBOX
	# =====================================================

	vbox.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	vbox.size_flags_vertical = (
		Control.SIZE_SHRINK_BEGIN
	)


	# =====================================================
	# ICON
	# =====================================================

	item_icon.texture_filter = (
		CanvasItem.TEXTURE_FILTER_NEAREST
	)

	item_icon.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	item_icon.size_flags_horizontal = (
		Control.SIZE_SHRINK_BEGIN
	)

	item_icon.size_flags_vertical = (
		Control.SIZE_SHRINK_CENTER
	)

	# =====================================================
	# ITEM INFO
	# =====================================================

	var item_info := (
		$MarginContainer/VBoxContainer/ItemHeader/ItemInfo
		as VBoxContainer
	)

	item_info.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	item_info.size_flags_vertical = (
		Control.SIZE_SHRINK_CENTER
	)

	# =====================================================
	# ITEM NAME
	# =====================================================

	item_name_label.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	item_name_label.size_flags_vertical = (
		Control.SIZE_SHRINK_CENTER
	)

	item_name_label.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)

	# =====================================================
	# ITEM RARITY
	# =====================================================

	item_rarity_label.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	item_rarity_label.size_flags_vertical = (
		Control.SIZE_SHRINK_CENTER
	)

	item_rarity_label.add_theme_font_size_override(
		"font_size",
		10
	)

	# =====================================================
	# STATS
	# =====================================================

	stats_grid.columns = 2

	stats_grid.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	stats_grid.size_flags_vertical = (
		Control.SIZE_SHRINK_BEGIN
	)

	stats_grid.add_theme_font_size_override(
		"font_size",
		10
	)

	stats_grid.add_theme_constant_override(
		"h_separation",
		12
	)

	stats_grid.add_theme_constant_override(
		"v_separation",
		3
	)


	# =====================================================
	# DESCRIPTION
	# =====================================================

	description_label.custom_minimum_size = Vector2.ZERO

	description_label.size_flags_horizontal = (
		Control.SIZE_EXPAND_FILL
	)

	description_label.size_flags_vertical = (
		Control.SIZE_SHRINK_BEGIN
	)

	description_label.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
	)

	description_label.clip_text = false


	# =====================================================
	# BUTTONS
	# =====================================================

	use_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	drop_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	use_button.mouse_filter = Control.MOUSE_FILTER_STOP
	drop_button.mouse_filter = Control.MOUSE_FILTER_STOP

	use_button.focus_mode = Control.FOCUS_NONE
	drop_button.focus_mode = Control.FOCUS_NONE

	# =====================================================
	# BUTTON SIGNAL
	# =====================================================

	use_button.pressed.connect(
		_on_use_pressed
	)

	drop_button.pressed.connect(
		_on_drop_pressed
	)
	
func show_item(
	item: ItemInstance,
	amount: int = 1,
	inventory_slot_index: int = -1,
	equipment_slot_name: String = ""
) -> void:

	if item == null:
		return

	if item.item_data == null:
		return

	var item_data: ItemData = item.item_data

	current_item = item
	current_amount = amount
	current_slot_index = inventory_slot_index
	current_equipment_slot = equipment_slot_name
	current_is_equipment = (
		equipment_slot_name != ""
	)


	# =====================================================
	# ICON
	# =====================================================

	item_icon.texture = item_data.icon


	# =====================================================
	# NAME
	# =====================================================

	item_name_label.text = item_data.item_name

	var rarity_color := Inventorymanager.get_rarity_color(item)

	item_name_label.add_theme_color_override(
		"font_color",
		rarity_color
	)


	# =====================================================
	# RARITY
	# =====================================================

	match item.rarity:

		ItemData.Rarity.COMMON:
			item_rarity_label.text = "Common"

		ItemData.Rarity.UNCOMMON:
			item_rarity_label.text = "Uncommon"

		ItemData.Rarity.RARE:
			item_rarity_label.text = "Rare"

		ItemData.Rarity.EPIC:
			item_rarity_label.text = "Epic"

		ItemData.Rarity.LEGENDARY:
			item_rarity_label.text = "Legendary"

		_:
			item_rarity_label.text = ""

	item_rarity_label.add_theme_color_override(
		"font_color",
		rarity_color
	)


	# =====================================================
	# DESCRIPTION
	# =====================================================

	print("")
	print("========== DESCRIPTION DEBUG ==========")
	print("Item              : ", item_data.item_name)
	print("Description raw   : [", item_data.description, "]")
	print("Description empty : ", item_data.description.is_empty())
	print("Description len   : ", item_data.description.length())

	if not item_data.description.is_empty():

		description_label.text = item_data.description
		description_label.visible = true

		print(
			"Description LABEL : [",
			description_label.text,
			"]"
		)

	else:

		description_label.text = ""
		description_label.visible = false

		print("DESCRIPTION RỖNG")

	print("=======================================")


	# =====================================================
	# STATS
	# =====================================================

	var stats := build_stats(item)

	stats_grid.visible = not stats.is_empty()


	# =====================================================
	# BUTTON
	# =====================================================

	setup_buttons(item)


	# =====================================================
	# HIỆN TOOLTIP
	# =====================================================

	visible = true


	# =====================================================
	# DEFER LAYOUT
	# =====================================================

	call_deferred("_refresh_tooltip_layout")


	# =====================================================
	# DEBUG CONTENT
	# =====================================================

	print("")
	print("========== TOOLTIP CONTENT DEBUG ==========")

	print("ITEM: ", item_data.item_name)

	print("DESCRIPTION:")
	print(
		"  raw      = [",
		item_data.description,
		"]"
	)

	print(
		"  label    = [",
		description_label.text,
		"]"
	)

	print(
		"  label size  = ",
		description_label.size
	)

	print(
		"  label min   = ",
		description_label.get_minimum_size()
	)


	print("STATS:")

	print(
		"  children     = ",
		stats_grid.get_child_count()
	)

	print(
		"  visible      = ",
		stats_grid.visible
	)

	print(
		"  grid size    = ",
		stats_grid.size
	)

	print(
		"  grid min     = ",
		stats_grid.get_minimum_size()
	)

	print(
		"  columns      = ",
		stats_grid.columns
	)

	print(
		"  grid size   = ",
		stats_grid.size
	)

	print(
		"  grid min    = ",
		stats_grid.get_minimum_size()
	)

	print("===========================================")
	
func hide_tooltip() -> void:

	current_item = null
	current_amount = 0
	current_slot_index = -1

	visible = false

# =========================================================
# BUILD STATS
# =========================================================

# =========================================================
# BUILD STATS
# =========================================================

func build_stats(item: ItemInstance) -> String:

	if item == null:
		return ""

	if item.item_data == null:
		return ""

	for child in stats_grid.get_children():
		child.queue_free()

	# =====================================================
	# GỘP ROLLED OPTION
	# =====================================================

	var option_values: Dictionary = {}

	for option in item.rolled_options:

		if option == null:
			continue

		var option_value: float = option.min_value

		if is_zero_approx(option_value):
			continue

		if not option_values.has(option.stat_type):
			option_values[option.stat_type] = 0.0

		option_values[option.stat_type] += option_value

	# =====================================================
	# ROLLED BASE STATS
	# =====================================================

	var has_stats := false

	for stat in item.rolled_stats:

		if stat == null:
			continue

		if is_zero_approx(stat.value):
			continue

		var label := Label.new()

		var stat_text := "%s: %s" % [
			_get_stat_name(stat.type),
			_format_stat_value(
				stat.type,
				stat.value
			)
		]

		# =================================================
		# OPTION CÙNG LOẠI
		# =================================================

		if option_values.has(stat.type):

			var option_value: float = option_values[stat.type]

			stat_text += "  +%s" % [
				_format_stat_value(
					stat.type,
					option_value
				)
			]

		label.text = stat_text

		label.add_theme_font_size_override(
			"font_size",
			10
		)

		label.size_flags_horizontal = (
			Control.SIZE_EXPAND_FILL
		)

		stats_grid.add_child(label)

		has_stats = true

	# =====================================================
	# OPTION KHÔNG CÓ BASE STAT
	# =====================================================

	for stat_type in option_values:

		var already_exists := false

		for stat in item.rolled_stats:

			if stat != null and stat.type == stat_type:
				already_exists = true
				break

		if already_exists:
			continue

		var option_value: float = option_values[stat_type]

		var label := Label.new()

		label.text = "%s: +%s" % [
			_get_stat_name(stat_type),
			_format_stat_value(
				stat_type,
				option_value
			)
		]

		label.add_theme_font_size_override(
			"font_size",
			10
		)

		label.size_flags_horizontal = (
			Control.SIZE_EXPAND_FILL
		)

		stats_grid.add_child(label)

		has_stats = true

	# =====================================================
	# RESULT
	# =====================================================

	if not has_stats:

		stats_grid.visible = false

		return ""

	stats_grid.columns = 2
	stats_grid.visible = true

	return "has_stats"

func _is_zero_stat(value) -> bool:

	if value == null:
		return true

	if value is int:
		return value == 0

	if value is float:
		return is_zero_approx(value)

	if value is Vector2:
		return value == Vector2.ZERO

	if value is Vector3:
		return value == Vector3.ZERO

	if value is String:
		return value.is_empty()

	return false
	
# =========================================================
# FORMAT STAT NAME
# =========================================================

func _format_stat_name(property_name: String) -> String:

	var text := property_name.replace("_", " ")

	return text.capitalize()
	
# =========================================================
# FORMAT STAT VALUE
# =========================================================

func _format_stat_value(stat_type: ItemStat.StatType, value: float) -> String:

	var rounded_value: float = round(value * 100.0) / 100.0
	var text: String

	if is_equal_approx(rounded_value, round(rounded_value)):
		text = str(int(round(rounded_value)))
	else:
		text = str(rounded_value)

	if stat_type == ItemStat.StatType.CRIT_CHANCE \
	or stat_type == ItemStat.StatType.CRIT_DAMAGE:
		return text + "%"

	return text

# =========================================================
# KIỂM TRA USE
# =========================================================

func can_use_item(item: ItemInstance) -> bool:

	if item == null:
		return false

	if item.item_data == null:
		return false

	match item.item_data.item_type:

		ItemData.ItemType.BACKPACK:
			return true

		ItemData.ItemType.WEAPON:
			return true

		ItemData.ItemType.TOOL:
			return true

		ItemData.ItemType.CONSUMABLE:
			return true

	return false


# =========================================================
# USE
# =========================================================

# =========================================================
# USE
# =========================================================

func _on_use_pressed() -> void:

	if current_item == null:
		return

	# =====================================================
	# THÁO ITEM KHỎI EQUIPMENT
	# =====================================================

	if current_is_equipment:
		_unequip_current_item()
		return

	# =====================================================
	# ITEM TRONG INVENTORY
	# =====================================================

	if current_slot_index < 0:
		return

	if current_item.item_data == null:
		return

	var item_name: String = current_item.item_data.item_name

	print(
		"USE ITEM: ",
		item_name,
		" | Slot: ",
		current_slot_index
	)

	var success: bool = Inventorymanager.use_item(
		current_slot_index
	)

	if not success:
		print("USE FAILED: ", item_name)
		return

	refresh_inventory_ui()

	var inventory_ui := get_tree().get_first_node_in_group(
		"inventory_ui"
	) as InventoryUI

	if inventory_ui != null:
		inventory_ui.refresh_equipment()

	hide_tooltip()
# =========================================================
# DROP
# =========================================================

func _on_drop_pressed() -> void:
	if current_item == null:
		print("ERROR: No item to drop")
		return
	
	# =====================================================
	# XÁC ĐỊNH SỐ LƯỢNG DROP
	# =====================================================
	
	var drop_amount = 1  # Mặc định drop 1
	
	# Nếu giữ Shift -> drop tất cả
	if Input.is_key_pressed(KEY_SHIFT):
		drop_amount = current_amount
		print("DROP ALL: ", drop_amount)
	
	# Nếu giữ Ctrl -> drop 1 nửa stack
	elif Input.is_key_pressed(KEY_CTRL):
		drop_amount = max(1, floor(current_amount / 2))
		print("DROP HALF: ", drop_amount)
	
	# =====================================================
	# KIỂM TRA SLOT CHỨA ITEM
	# =====================================================
	
	var slot_index = Inventorymanager.find_item(current_item)
	if slot_index == -1:
		print("ERROR: Không tìm thấy item trong inventory")
		return
	
	# Kiểm tra số lượng trong slot
	var available_amount = Inventorymanager.get_amount(slot_index)
	if available_amount < drop_amount:
		print("ERROR: Không đủ số lượng để drop")
		return
	
	# =====================================================
	# THỰC HIỆN DROP
	# =====================================================
	
	var success = Inventorymanager.drop_item(slot_index, drop_amount)
	
	if success:
		print("✅ DROPPED: ", current_item.item_data.item_name, " x", drop_amount)
		
		# Ẩn tooltip
		hide_tooltip()
		
		# Refresh UI Inventory
		refresh_inventory_ui()
		
		# Play sound (nếu có)
		# AudioManager.play_sound("drop_item")
		
	else:
		print("❌ DROP FAILED!")

# =========================================================
# DEBUG LAYOUT
# =========================================================

func _debug_layout() -> void:

	print("")
	print("========== ITEM TOOLTIP DEBUG ==========")

	var vbox := (
		$MarginContainer/VBoxContainer
		as VBoxContainer
	)

	var item_header := (
		$MarginContainer/VBoxContainer/ItemHeader
		as HBoxContainer
	)


	# =====================================================
	# PANEL
	# =====================================================

	print("")
	print("--- PANEL ---")

	print(
		"Panel local pos      : ", position
	)

	print(
		"Panel global pos     : ", global_position
	)

	print(
		"Panel size            : ", size
	)

	print(
		"Panel min size       : ", get_minimum_size()
	)

	print(
		"Panel scale           : ", scale
	)

	print(
		"Panel anchors         : L=",
		anchor_left,
		" R=",
		anchor_right,
		" T=",
		anchor_top,
		" B=",
		anchor_bottom
	)

	print(
		"Panel offsets         : L=",
		offset_left,
		" R=",
		offset_right,
		" T=",
		offset_top,
		" B=",
		offset_bottom
	)


	# =====================================================
	# MARGIN
	# =====================================================

	print("")
	print("--- MARGIN CONTAINER ---")

	print(
		"Margin local pos     : ",
		margin_container.position
	)

	print(
		"Margin global pos    : ",
		margin_container.global_position
	)

	print(
		"Margin size          : ",
		margin_container.size
	)

	print(
		"Margin min size      : ",
		margin_container.get_minimum_size()
	)

	print(
		"Margin scale         : ",
		margin_container.scale
	)

	print(
		"Margin anchors       : L=",
		margin_container.anchor_left,
		" R=",
		margin_container.anchor_right,
		" T=",
		margin_container.anchor_top,
		" B=",
		margin_container.anchor_bottom
	)

	print(
		"Margin offsets       : L=",
		margin_container.offset_left,
		" R=",
		margin_container.offset_right,
		" T=",
		margin_container.offset_top,
		" B=",
		margin_container.offset_bottom
	)


	# =====================================================
	# VBOX
	# =====================================================

	print("")
	print("--- VBOX ---")

	print(
		"VBox local pos       : ",
		vbox.position
	)

	print(
		"VBox global pos      : ",
		vbox.global_position
	)

	print(
		"VBox size            : ",
		vbox.size
	)

	print(
		"VBox min size        : ",
		vbox.get_minimum_size()
	)

	print(
		"VBox scale           : ",
		vbox.scale
	)

	print(
		"VBox separation      : ",
		vbox.get_theme_constant("separation")
	)


	# =====================================================
	# HEADER
	# =====================================================

	print("")
	print("--- ITEM HEADER ---")

	print(
		"Header local pos     : ",
		item_header.position
	)

	print(
		"Header global pos    : ",
		item_header.global_position
	)

	print(
		"Header size          : ",
		item_header.size
	)

	print(
		"Header min size      : ",
		item_header.get_minimum_size()
	)

	print(
		"Header scale         : ",
		item_header.scale
	)

	print(
		"Header alignment     : ",
		item_header.alignment
	)

	print(
		"Header clip          : ",
		item_header.clip_contents
	)


	# =====================================================
	# ICON
	# =====================================================

	print("")
	print("--- ITEM ICON ---")

	print(
		"Icon local pos       : ",
		item_icon.position
	)

	print(
		"Icon global pos      : ",
		item_icon.global_position
	)

	print(
		"Icon size            : ",
		item_icon.size
	)

	print(
		"Icon min size        : ",
		item_icon.get_minimum_size()
	)

	print(
		"Icon scale           : ",
		item_icon.scale
	)

	print(
		"Icon texture         : ",
		item_icon.texture
	)

	print(
		"Icon texture size    : ",
		item_icon.texture.get_size()
		if item_icon.texture != null
		else Vector2.ZERO
	)

	print(
		"Icon expand mode     : ",
		item_icon.expand_mode
	)

	print(
		"Icon stretch mode    : ",
		item_icon.stretch_mode
	)

	print(
		"Icon H flags         : ",
		item_icon.size_flags_horizontal
	)

	print(
		"Icon V flags         : ",
		item_icon.size_flags_vertical
	)


	# =====================================================
	# ITEM NAME
	# =====================================================

	print("")
	print("--- ITEM NAME ---")

	print(
		"Name local pos       : ",
		item_name_label.position
	)

	print(
		"Name global pos      : ",
		item_name_label.global_position
	)

	print(
		"Name size            : ",
		item_name_label.size
	)

	print(
		"Name min size        : ",
		item_name_label.get_minimum_size()
	)

	print(
		"Name scale           : ",
		item_name_label.scale
	)

	print(
		"Name rotation        : ",
		item_name_label.rotation
	)

	print(
		"Name pivot           : ",
		item_name_label.pivot_offset
	)

	print(
		"Name H flags         : ",
		item_name_label.size_flags_horizontal
	)

	print(
		"Name V flags         : ",
		item_name_label.size_flags_vertical
	)

	print(
		"Name autowrap        : ",
		item_name_label.autowrap_mode
	)

	print(
		"Name clip            : ",
		item_name_label.clip_text
	)

	print(
		"Name vertical align  : ",
		item_name_label.vertical_alignment
	)

	print(
		"Name horizontal align: ",
		item_name_label.horizontal_alignment
	)

	print(
		"Name text            : \"",
		item_name_label.text,
		"\""
	)

	print(
		"Name text length     : ",
		item_name_label.text.length()
	)

	print(
		"Name line count      : ",
		item_name_label.get_line_count()
	)

	print(
		"Name content width   : ",
		item_name_label.get_minimum_size().x
	)

	print(
		"Name content height  : ",
		item_name_label.get_minimum_size().y
	)

	# =====================================================
	# BUTTONS
	# =====================================================

	print("")
	print("--- BUTTONS ---")

	print(
		"UseButton pos        : ",
		use_button.position,
		" size=",
		use_button.size,
		" visible=",
		use_button.visible
	)

	print(
		"DropButton pos       : ",
		drop_button.position,
		" size=",
		drop_button.size,
		" visible=",
		drop_button.visible
	)


	# =====================================================
	# PARENT CHAIN
	# =====================================================

	print("")
	print("--- PARENT CHAIN ---")

	var node: Node = item_name_label

	while node != null:

		if node is Control:

			var control := node as Control

			print(
				node.name,
				" | local=",
				control.position,
				" global=",
				control.global_position,
				" size=",
				control.size,
				" scale=",
				control.scale
			)

		else:

			print(
				node.name,
				" | ",
				node.get_class()
			)

		node = node.get_parent()

	# =====================================================
	# STATS FONT DEBUG
	# =====================================================

	print("")
	print("--- STATS FONT DEBUG ---")

	print(
		"StatsGrid font size = ",
		stats_grid.get_theme_font_size("font_size")
	)

	print(
		"StatsGrid theme = ",
		stats_grid.theme
	)

	print(
		"StatsGrid scale = ",
		stats_grid.scale
	)

	print(
		"StatsGrid size = ",
		stats_grid.size
	)

	print(
		"StatsGrid child count = ",
		stats_grid.get_child_count()
	)

	for i in range(stats_grid.get_child_count()):

		var child := stats_grid.get_child(i)

		if child is Label:

			var label := child as Label

			print(
				"Stat[",
				i,
				"] text = [",
				label.text,
				"]"
			)

			print(
				"  font size = ",
				label.get_theme_font_size("font_size")
			)

			print(
				"  font      = ",
				label.get_theme_font("font")
			)

			print(
				"  size      = ",
				label.size
			)

			print(
				"  min size  = ",
				label.get_minimum_size()
			)

	print("--------------------------------")
	
	# =====================================================
	# FINAL
	# =====================================================

	print("")
	print("========== END ITEM TOOLTIP DEBUG ==========")
	print("")

func _refresh_tooltip_layout() -> void:

	await get_tree().process_frame
	await get_tree().process_frame


	# =====================================================
	# MARGIN
	# =====================================================

	var margin_left := 8
	var margin_right := 8
	var margin_top := 8
	var margin_bottom := 8

	margin_container.add_theme_constant_override(
		"margin_left",
		margin_left
	)

	margin_container.add_theme_constant_override(
		"margin_right",
		margin_right
	)

	margin_container.add_theme_constant_override(
		"margin_top",
		margin_top
	)

	margin_container.add_theme_constant_override(
		"margin_bottom",
		margin_bottom
	)


	# =====================================================
	# MARGIN FULL RECT
	# =====================================================

	margin_container.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)


	# =====================================================
	# CHỜ GODOT TÍNH LAYOUT
	# =====================================================

	await get_tree().process_frame


	# =====================================================
	# CHỈ TÍNH HEIGHT
	# =====================================================

	var vbox := (
		$MarginContainer/VBoxContainer
		as VBoxContainer
	)

	var content_height := (
		vbox.get_combined_minimum_size().y
	)


	# =====================================================
	# CHỈ ĐỔI CHIỀU DỌC
	# =====================================================

	size.y = (
		content_height
		+ margin_top
		+ margin_bottom
	)
	
	await get_tree().process_frame

	$MarginContainer/VBoxContainer/Buttons.reset_size()

	use_button.reset_size()
	drop_button.reset_size()

	# =====================================================
	# DEBUG MARGIN
	# =====================================================

	print("")
	print("==============================================")
	print("========== TOOLTIP MARGIN DEBUG =============")
	print("==============================================")

	print("")
	print("--- PANEL ---")

	print("Panel position       = ", position)
	print("Panel global         = ", global_position)
	print("Panel size           = ", size)
	print("Panel min size       = ", get_minimum_size())


	print("")
	print("--- MARGIN CONTAINER ---")

	print("Margin position      = ", margin_container.position)
	print("Margin global        = ", margin_container.global_position)
	print("Margin size          = ", margin_container.size)
	print("Margin min size      = ", margin_container.get_minimum_size())

	print("")
	print("THEME MARGINS:")

	print(
		"  left   = ",
		margin_container.get_theme_constant("margin_left")
	)

	print(
		"  right  = ",
		margin_container.get_theme_constant("margin_right")
	)

	print(
		"  top    = ",
		margin_container.get_theme_constant("margin_top")
	)

	print(
		"  bottom = ",
		margin_container.get_theme_constant("margin_bottom")
	)


	print("")
	print("--- VBOX ---")

	print("VBox position        = ", vbox.position)
	print("VBox global          = ", vbox.global_position)
	print("VBox size            = ", vbox.size)
	print("VBox min size        = ", vbox.get_minimum_size())
	print("VBox custom min      = ", vbox.custom_minimum_size)


	print("")
	print("--- CHILD POSITIONS ---")

	print(
		"Header position      = ",
		$MarginContainer/VBoxContainer/ItemHeader.position
	)

	print(
		"Header size          = ",
		$MarginContainer/VBoxContainer/ItemHeader.size
	)

	print(
		"Stats position       = ",
		stats_grid.position
	)

	print(
		"Stats size           = ",
		stats_grid.size
	)

	print(
		"Description position = ",
		description_label.position
	)

	print(
		"Description size     = ",
		description_label.size
	)

	print(
		"Buttons position     = ",
		$MarginContainer/VBoxContainer/Buttons.position
	)

	print(
		"Buttons size         = ",
		$MarginContainer/VBoxContainer/Buttons.size
	)


	print("")
	print("--- EXPECTED ---")

	print(
		"Expected content X   = ",
		margin_left
	)

	print(
		"Expected content Y   = ",
		margin_top
	)

	print(
		"Actual VBox X        = ",
		vbox.position.x
	)

	print(
		"Actual VBox Y        = ",
		vbox.position.y
	)

	print("==============================================")

func refresh_inventory_ui() -> void:
	var inventory_ui = get_tree().get_first_node_in_group("inventory_ui")
	if inventory_ui != null:
		if inventory_ui.has_method("refresh_inventory"):
			inventory_ui.refresh_inventory()
		if inventory_ui.has_method("update_slots"):
			inventory_ui.update_slots()

func setup_buttons(item: ItemInstance) -> void:

	if item == null:
		return

	if item.item_data == null:
		return

	var item_data: ItemData = item.item_data


	# =====================================================
	# EQUIPMENT SLOT
	# =====================================================

	if current_is_equipment:

		use_button.visible = true
		use_button.text = "Tháo ra"

		drop_button.visible = false

		return


	# =====================================================
	# INVENTORY
	# =====================================================

	drop_button.visible = true


	match item_data.item_type:

		# =================================================
		# WEAPON
		# =================================================

		ItemData.ItemType.WEAPON:

			use_button.visible = true
			use_button.text = "Trang bị"


		# =================================================
		# BACKPACK
		# =================================================

		ItemData.ItemType.BACKPACK:

			use_button.visible = true
			use_button.text = "Trang bị"


		# =================================================
		# CONSUMABLE
		# =================================================

		ItemData.ItemType.CONSUMABLE:

			use_button.visible = true

			match item_data.consumable_action:

				ItemData.ConsumableAction.EAT:
					use_button.text = "Ăn"

				ItemData.ConsumableAction.DRINK:
					use_button.text = "Uống"

				ItemData.ConsumableAction.USE:
					use_button.text = "Dùng"


		# =================================================
		# TOOL
		# =================================================

		ItemData.ItemType.TOOL:

			use_button.visible = true
			use_button.text = "Dùng"


		# =================================================
		# MATERIAL
		# =================================================

		ItemData.ItemType.MATERIAL:

			use_button.visible = false


		_:

			use_button.visible = false

func _unequip_current_item() -> void:

	if current_item == null:
		return

	if current_equipment_slot == "":
		return


	# =====================================================
	# TÌM SLOT TRỐNG TRONG INVENTORY
	# =====================================================

	var inventory_slot := Inventorymanager.find_empty_slot()

	if inventory_slot == -1:

		print("UNEQUIP FAILED: Inventory đầy")

		return


	var item_to_return := current_item


	# =====================================================
	# THÁO EQUIPMENT
	# =====================================================

	var success := Equipmentmanager.unequip_from_slot(
		current_equipment_slot
	)

	if not success:

		print(
			"UNEQUIP FAILED: ",
			current_equipment_slot
		)

		return


	# =====================================================
	# TRẢ ITEM VỀ INVENTORY
	# =====================================================

	var added := Inventorymanager.set_slot(
		inventory_slot,
		item_to_return,
		1
	)

	if not added:

		# Rollback nếu inventory không nhận item
		Equipmentmanager.equip_to_slot(
			current_equipment_slot,
			item_to_return
		)

		print("UNEQUIP FAILED: Không thể trả item vào inventory")

		return


	# =====================================================
	# REFRESH UI
	# =====================================================

	refresh_inventory_ui()

	var inventory_ui := get_tree().get_first_node_in_group(
		"inventory_ui"
	) as InventoryUI

	if inventory_ui != null:
		inventory_ui.refresh_equipment()


	hide_tooltip()

func _get_stat_name(stat_type: ItemStat.StatType) -> String:
	match stat_type:
		ItemStat.StatType.DAMAGE:
			return "Damage"
		ItemStat.StatType.CRIT_CHANCE:
			return "Crit Chance"
		ItemStat.StatType.CRIT_DAMAGE:
			return "Crit Damage"
		ItemStat.StatType.RANGE:
			return "Range"
		ItemStat.StatType.FIRE_RATE:
			return "Fire Rate"
		ItemStat.StatType.BULLET_SPEED:
			return "Bullet Speed"
		ItemStat.StatType.MAGAZINE_SIZE:
			return "Magazine Size"
		ItemStat.StatType.RELOAD_TIME:
			return "Reload Time"
		ItemStat.StatType.ATTACK_SPEED:
			return "Attack Speed"
		ItemStat.StatType.ATTACK_RANGE:
			return "Attack Range"
		ItemStat.StatType.HP:
			return "HP"
		ItemStat.StatType.MAX_HP:
			return "Max HP"
		ItemStat.StatType.ARMOR:
			return "Armor"
		ItemStat.StatType.SPEED:
			return "Speed"
		ItemStat.StatType.BACKPACK_SLOTS:
			return "Backpack Slots"
		_:
			return "Unknown"
