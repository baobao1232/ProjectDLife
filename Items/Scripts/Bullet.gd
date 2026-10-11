extends Area2D

var direction: Vector2 = Vector2.ZERO
var speed: float = 800.0
var max_distance: float = 500.0
var damage: float = 0.0
var weapon_item: ItemInstance
var start_position: Vector2


func _ready() -> void:
	print("=== BULLET READY ===")
	print("Layer: ", collision_layer)
	print("Mask: ", collision_mask)
	print("Monitoring: ", monitoring)
	print("Monitorable: ", monitorable)
	print("Shape count: ", get_child_count())

	for child in get_children():
		print("Child: ", child.name, " | ", child.get_class())

	
func setup(
	bullet_direction: Vector2,
	item: ItemInstance
) -> void:
	if item == null:
		queue_free()
		return

	if item.item_data == null:
		queue_free()
		return

	weapon_item = item

	direction = bullet_direction.normalized()

	var bullet_speed := get_item_stat(
		weapon_item,
		ItemStat.StatType.BULLET_SPEED
	)

	var weapon_range := get_item_stat(
		weapon_item,
		ItemStat.StatType.RANGE
	)

	var weapon_damage := get_item_stat(
		weapon_item,
		ItemStat.StatType.DAMAGE
	)

	speed = bullet_speed
	max_distance = weapon_range
	damage = weapon_damage

	start_position = global_position
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	var movement := direction * speed * delta

	var from := global_position
	var to := from + movement

	var query := PhysicsRayQueryParameters2D.create(from, to)
	query.collision_mask = 2
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.exclude = [self]

	var result := get_world_2d().direct_space_state.intersect_ray(query)

	if not result.is_empty():
		var collider = result["collider"]

		print(
			"=== BULLET RAY HIT === ",
			collider.name,
			" | ",
			collider.get_class()
		)

		if collider is HurtBox:
			var min_damage := get_item_stat_min(
				weapon_item,
				ItemStat.StatType.DAMAGE
			)

			var max_damage := get_item_stat_max(
				weapon_item,
				ItemStat.StatType.DAMAGE
			)

			var is_critical := false

			collider.take_damage(
				damage,
				min_damage,
				max_damage,
				is_critical
			)

			queue_free()
			return

	global_position = to

	if global_position.distance_to(start_position) >= max_distance:
		queue_free()
	
func get_item_stat(
	item: ItemInstance,
	stat_type: ItemStat.StatType
) -> float:
	var total: float = 0.0

	for stat in item.rolled_stats:
		if stat == null:
			continue

		if stat.type == stat_type:
			total += stat.value

	for option in item.rolled_options:
		if option == null:
			continue

		if option.stat_type == stat_type:
			total += option.min_value

	return total

func get_item_stat_min(
	item: ItemInstance,
	stat_type: ItemStat.StatType
) -> float:
	var total: float = 0.0

	for stat in item.item_data.stats:
		if stat == null:
			continue

		if stat.type == stat_type:
			total += stat.min_value

	for option in item.rolled_options:
		if option == null:
			continue

		if option.stat_type == stat_type:
			total += option.min_value

	return total

func get_item_stat_max(
	item: ItemInstance,
	stat_type: ItemStat.StatType
) -> float:
	var total: float = 0.0

	for stat in item.item_data.stats:
		if stat == null:
			continue

		if stat.type == stat_type:
			total += stat.max_value

	for option in item.rolled_options:
		if option == null:
			continue

		if option.stat_type == stat_type:
			total += option.max_value

	return total
