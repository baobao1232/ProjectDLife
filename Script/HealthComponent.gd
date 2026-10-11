extends Node

class_name HealthComponent

signal health_changed(current_health: float, max_health: float)
signal died
signal damage_taken(amount: float)

@export var max_health: float = 100.0

var current_health: float


func _ready() -> void:
	current_health = max_health
	health_changed.emit(current_health, max_health)


func take_damage(amount: float) -> void:
	if amount <= 0.0:
		return

	if current_health <= 0.0:
		return

	current_health = max(current_health - amount, 0.0)

	damage_taken.emit(amount)
	health_changed.emit(current_health, max_health)

	if current_health <= 0.0:
		died.emit()

func heal(amount: float) -> void:
	if amount <= 0.0:
		return

	if current_health <= 0.0:
		return

	current_health = min(
		current_health + amount,
		max_health
	)

	health_changed.emit(
		current_health,
		max_health
	)
