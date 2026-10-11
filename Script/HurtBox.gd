extends Area2D

class_name HurtBox

@export var health_component: HealthComponent

func _ready() -> void:
	print("=== HURTBOX READY ===")
	print("Name: ", name)
	print("Global Position: ", global_position)
	print("Layer: ", collision_layer)
	print("Mask: ", collision_mask)
	print("Monitoring: ", monitoring)
	print("Monitorable: ", monitorable)

	for child in get_children():
		if child is CollisionShape2D:
			print(
				"CollisionShape: ",
				child.name,
				" | disabled=",
				child.disabled,
				" | shape=",
				child.shape,
				" | global_pos=",
				child.global_position
			)

func take_damage(
	amount: float,
	min_damage: float = 0.0,
	max_damage: float = 0.0,
	is_critical: bool = false
) -> void:
	if health_component == null:
		return

	health_component.take_damage(amount)

	var owner_node := get_parent()

	if owner_node.has_method("_show_damage_popup"):
		owner_node._show_damage_popup(
			amount,
			min_damage,
			max_damage,
			is_critical
		)
