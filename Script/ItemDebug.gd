extends Node2D

@export var show_debug: bool = true

const DEBUG_RADIUS := 1.0


func _ready() -> void:
	top_level = true
	z_as_relative = false
	show_behind_parent = false
	z_index = 1000000

func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if not show_debug:
		return

	var player := get_tree().get_first_node_in_group("player")

	if player == null:
		return

	draw_right_hand_debug(player)
	draw_left_hand_debug(player)

func draw_right_hand_debug(player: Node) -> void:
	var item: ItemInstance = player.right_hand_item

	if item == null:
		return

	if item.item_data == null:
		return

	var item_data: ItemData = item.item_data

	var sprite: Sprite2D = player.get_node_or_null(
		"Visual/ArmRight/RightHandItem/ItemSprite"
	)

	if sprite == null:
		return

	if sprite.texture == null:
		return

	var grip_global := sprite.to_global(
		item_data.grip_position
	)

	var muzzle_global := sprite.to_global(
		item_data.muzzle_position
	)

	var grip_local := to_local(grip_global)
	var muzzle_local := to_local(muzzle_global)

	# GRIP - ĐỎ
	draw_debug_point(
		grip_local,
		Color.RED
	)

	# MUZZLE - VÀNG
	draw_debug_point(
		muzzle_local,
		Color.YELLOW
	)

	# NỐI GRIP -> MUZZLE
	draw_line(
		grip_local,
		muzzle_local,
		Color.WHITE,
		1.0
	)

func draw_left_hand_debug(player: Node) -> void:
	var item: ItemInstance = player.left_hand_item

	if item == null:
		return

	if item.item_data == null:
		return

	var item_data: ItemData = item.item_data

	var sprite: Sprite2D = player.get_node_or_null(
		"Visual/ArmLeft/LeftHandItem/ItemSprite"
	)

	if sprite == null:
		return

	if sprite.texture == null:
		return

	var grip_global: Vector2 = sprite.to_global(
		item_data.grip_position
	)

	var muzzle_global: Vector2 = sprite.to_global(
		item_data.muzzle_position
	)

	draw_debug_point(
		to_local(grip_global),
		Color.RED
	)

	draw_debug_point(
		to_local(muzzle_global),
		Color.YELLOW
	)


func draw_debug_point(position: Vector2, color: Color) -> void:
	# Vòng tròn lớn để dễ nhìn
	draw_circle(
		position,
		1.0,
		color
	)

	# Dấu +
	draw_line(
		position - Vector2(2, 0),
		position + Vector2(2, 0),
		color,
		1.0
	)

	draw_line(
		position - Vector2(0, 2),
		position + Vector2(0, 2),
		color,
		1.0
	)
