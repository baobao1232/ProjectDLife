extends Node

@export var test_item: ItemData


func _ready() -> void:

	var instance := ItemInstance.new()

	print("========== ITEM INSTANCE TEST ==========")
	print("Instance created: ", instance != null)
	print("Rarity: ", instance.rarity)
	print("Durability: ", instance.durability)
	print("Unique ID: ", instance.unique_id)
	print("========================================")

	test_item_factory()


func test_item_factory() -> void:

	if test_item == null:
		print("TEST FACTORY: test_item = NULL")
		return

	var instance := ItemFactory.create_item(test_item)

	if instance == null:
		print("TEST FACTORY: CREATE FAILED")
		return

	print("========== ITEM FACTORY TEST ==========")
	print("ItemData   : ", instance.item_data.item_name)
	print("Unique ID  : ", instance.unique_id)
	print("Rarity     : ", ItemData.Rarity.keys()[instance.rarity])
	print("Durability : ", instance.durability)
	print("========================================")
