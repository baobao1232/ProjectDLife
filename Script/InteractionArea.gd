extends Area2D

# =========================================================
# KHOẢNG CÁCH VÙNG TƯƠNG TÁC
# =========================================================

@export var interaction_distance_x: float = 15.0
@export var interaction_distance_y: float = 10.0

@export var interaction_radius: float = 7.0

@export var show_debug: bool = true

const DEBUG_LINE_WIDTH := 1.0


func _ready() -> void:

	# =====================================================
	# COLLISION
	# =====================================================

	monitoring = true
	monitorable = true


	# =====================================================
	# DEBUG HIỂN THỊ TRÊN CÙNG
	# =====================================================

	visible = true
	z_index = 9999

	# Không nhận transform từ Player
	top_level = true

	queue_redraw()


func _is_remote_player() -> bool:
	var player := get_parent()
	return player != null \
		and player.get("network_managed") == true \
		and player.get("is_local_player") != true


func _process(_delta: float) -> void:
	var player := get_parent()
	if player != null and player.get("network_managed") == true and player.get("is_local_player") != true:
		visible = false
		return

	visible = true
	update_position()
	queue_redraw()


# =========================================================
# ĐẶT VÙNG TƯƠNG TÁC THEO CHUỘT
# =========================================================

func update_position() -> void:

	var player := get_parent()

	if player == null:
		return


	var direction: Vector2 = (
		player.get_global_mouse_position()
		- player.global_position
	).normalized()


	# =====================================================
	# QUỸ ĐẠO ELIP
	# =====================================================

	var offset := Vector2(
		direction.x * interaction_distance_x,
		direction.y * interaction_distance_y
	)


	# Vì top_level = true nên dùng global_position
	global_position = player.global_position + offset


	# =====================================================
	# XOAY THEO CHUỘT
	# =====================================================

	rotation = direction.angle()


# =========================================================
# DEBUG
# =========================================================

func _draw() -> void:

	if not show_debug:
		return


	# =====================================================
	# VÒNG VÙNG TƯƠNG TÁC
	# =====================================================

	draw_circle(
		Vector2.ZERO,
		interaction_radius,
		Color(1.0, 0.8, 0.0, 0.20)
	)


	# =====================================================
	# VIỀN
	# =====================================================

	draw_arc(
		Vector2.ZERO,
		interaction_radius,
		0.0,
		TAU,
		32,
		Color(1.0, 0.8, 0.0, 1.0),
		DEBUG_LINE_WIDTH,
		false
	)


	# =====================================================
	# TÂM
	# =====================================================

	draw_circle(
		Vector2.ZERO,
		2.0,
		Color(1.0, 0.8, 0.0, 1.0)
	)


	# =====================================================
	# CROSSHAIR NGANG
	# =====================================================

	draw_line(
		Vector2(-5, 0),
		Vector2(5, 0),
		Color(1.0, 0.8, 0.0, 1.0),
		1.0
	)


	# =====================================================
	# CROSSHAIR DỌC
	# =====================================================

	draw_line(
		Vector2(0, -5),
		Vector2(0, 5),
		Color(1.0, 0.8, 0.0, 1.0),
		1.0
	)
