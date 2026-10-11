extends Node

## Loads ItemData .tres resources recursively from res://Items/Data.
## Add this script as an Autoload named ItemDatabase in Project Settings.

const ITEM_DATA_ROOT: String = "res://Items/Data"

var _items_by_id: Dictionary = {}
var _paths_by_id: Dictionary = {}

func _ready() -> void:
	reload_database()


func reload_database() -> void:
	_items_by_id.clear()
	_paths_by_id.clear()
	_scan_directory(ITEM_DATA_ROOT)
	print("[ItemDatabase] Loaded %d ItemData resources." % _items_by_id.size())


func get_item_data(item_id: String) -> ItemData:
	return _items_by_id.get(item_id) as ItemData


func has_item(item_id: String) -> bool:
	return _items_by_id.has(item_id)


func get_item_path(item_id: String) -> String:
	return str(_paths_by_id.get(item_id, ""))


func get_all_ids() -> Array[String]:
	var result: Array[String] = []
	for key in _items_by_id.keys():
		result.append(str(key))
	result.sort()
	return result


func _scan_directory(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		push_warning("[ItemDatabase] Cannot open directory: " + path)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while not file_name.is_empty():
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue

		var full_path := path.path_join(file_name)
		if dir.current_is_dir():
			_scan_directory(full_path)
		elif file_name.get_extension().to_lower() == "tres":
			_register_resource(full_path)

		file_name = dir.get_next()
	dir.list_dir_end()


func _register_resource(path: String) -> void:
	var resource := load(path)
	if not (resource is ItemData):
		return

	var data := resource as ItemData
	if data.id.strip_edges().is_empty():
		push_warning("[ItemDatabase] ItemData has empty id: " + path)
		return

	if _items_by_id.has(data.id):
		var existing_path: String = str(_paths_by_id[data.id])
		push_warning("[ItemDatabase] Duplicate id '%s': keeping %s; skipped %s" % [data.id, existing_path, path])
		return

	_items_by_id[data.id] = data
	_paths_by_id[data.id] = path
