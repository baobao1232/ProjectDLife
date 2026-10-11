extends Node2D

@export var duration: float = 0.05


func _ready() -> void:
	await get_tree().create_timer(duration).timeout
	queue_free()
