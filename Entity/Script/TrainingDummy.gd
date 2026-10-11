extends Node2D

@onready var health: HealthComponent = $HealthComponent

func _ready() -> void:
	health.died.connect(_on_died)
	health.health_changed.connect(_on_health_changed)

	$HealthLabel.text = "%d/%d" % [
		health.current_health,
		health.max_health
	]

	print("Training Dummy HP: ", health.current_health)

func _on_health_changed(current_health: float, max_health: float) -> void:
	print("TRAINING DUMMY HP: ", current_health, " / ", max_health)

	$HealthLabel.text = "%d/%d" % [
		current_health,
		max_health
	]

	var sprite := $Sprite2D

	sprite.modulate = Color(1.0, 0.2, 0.2)

	await get_tree().create_timer(0.08).timeout

	if is_instance_valid(sprite):
		sprite.modulate = Color.WHITE
		
func _on_died() -> void:
	print("TRAINING DUMMY DEAD")

	health.current_health = health.max_health
	
func _show_damage_popup(
	damage: float,
	min_damage: float,
	max_damage: float,
	is_critical: bool
) -> void:
	var popup_scene := preload("res://Items/Scenes/DamagePopup.tscn")
	var popup := popup_scene.instantiate()

	popup.global_position = global_position + Vector2(0, -20)
	get_tree().current_scene.add_child(popup)

	popup.setup_damage(
		damage,
		min_damage,
		max_damage,
		is_critical
	)
