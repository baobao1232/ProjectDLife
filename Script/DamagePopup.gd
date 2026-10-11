extends Node2D
@onready var label: Label = $Label

@export var float_distance: float = 30.0
@export var duration: float = 0.6

func setup_damage(
	damage: float,
	min_damage: float,
	max_damage: float,
	is_critical: bool = false
) -> void:
	var damage_label: Label = get_node_or_null("Label")

	if damage_label == null:
		push_error("DamagePopup: không tìm thấy child Label")
		return

	damage_label.text = "-%d" % int(round(damage))
	damage_label.modulate.a = 1.0

	# =========================
	# DAMAGE COLOR
	# =========================
	if is_critical:
		damage_label.modulate = Color(1.0, 0.1, 0.1)
	else:
		var damage_ratio := 0.0

		if max_damage > min_damage:
			damage_ratio = clamp(
				(damage - min_damage) / (max_damage - min_damage),
				0.0,
				1.0
			)

		damage_label.modulate = Color.WHITE.lerp(
			Color(1.0, 0.5, 0.0),
			damage_ratio
		)

	var start_position := position
	var end_position := start_position + Vector2(0, -float_distance)

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(
		self,
		"position",
		end_position,
		duration
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		damage_label,
		"modulate:a",
		0.0,
		duration
	).set_trans(Tween.TRANS_LINEAR)

	tween.chain().tween_callback(queue_free)
