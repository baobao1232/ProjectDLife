extends Node

## NetworkManager.gd - Godot 4.6
## Server-authoritative movement for the DLife project.
## Attach this script to the existing NetworkManager node in the map scene.

signal connection_status_changed(message: String)
signal snapshot_received(snapshot: Array)
signal debug_message(message: String)

const PORT: int = 7000
const MAX_CLIENTS: int = 20
const PLAYER_SPEED: float = 70.0
const SNAPSHOT_INTERVAL: float = 0.05
const SPAWN_ORIGIN: Vector2 = Vector2(48.0, 28.0)
const SPAWN_SPACING: float = 18.0

@export var server_ip: String = "127.0.0.1"
@export var port: int = PORT
@export var max_clients: int = MAX_CLIENTS
@export var player_speed: float = PLAYER_SPEED
@export var snapshot_interval: float = SNAPSHOT_INTERVAL

# Server state: peer_id -> {"position": Vector2, "input": Vector2}
var players: Dictionary = {}
var peer: ENetMultiplayerPeer = null
var _snapshot_elapsed: float = 0.0
var _is_server: bool = false
var _is_shutting_down: bool = false


func _ready() -> void:
	set_physics_process(true)
	_log("NetworkManager ready. UDP port: %d" % port)


# =========================================================
# SERVER STARTUP
# =========================================================

func start_server() -> Error:
	stop_network()

	var new_peer := ENetMultiplayerPeer.new()
	var error: Error = new_peer.create_server(port, max_clients)
	if error != OK:
		_log_error("Không thể tạo server: %s" % error_string(error))
		connection_status_changed.emit("Không thể tạo server: %s" % error_string(error))
		return error

	peer = new_peer
	multiplayer.multiplayer_peer = peer
	_is_server = true
	_is_shutting_down = false
	players.clear()
	_snapshot_elapsed = 0.0

	if not multiplayer.peer_connected.is_connected(_on_peer_connected):
		multiplayer.peer_connected.connect(_on_peer_connected)
	if not multiplayer.peer_disconnected.is_connected(_on_peer_disconnected):
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	_log("SERVER ONLINE | UDP %d | Max clients: %d" % [port, max_clients])
	connection_status_changed.emit("SERVER ONLINE")
	return OK


func _on_peer_connected(peer_id: int) -> void:
	if not _is_server:
		return

	if players.has(peer_id):
		return

	var spawn_position := _get_spawn_position()
	players[peer_id] = {
		"position": spawn_position,
		"input": Vector2.ZERO,
		"aim_angle": 0.0,
		"weapon_left": {},
		"weapon_right": {}
	}

	_log("Client connected: %d at %s" % [peer_id, str(spawn_position)])
	_broadcast_snapshot()


func _on_peer_disconnected(peer_id: int) -> void:
	if not _is_server:
		return

	players.erase(peer_id)
	_log("Client disconnected: %d" % peer_id)
	_broadcast_snapshot()


func _get_spawn_position() -> Vector2:
	# Spawn each player with a small horizontal gap from the previous one.
	return SPAWN_ORIGIN + Vector2(float(players.size()) * SPAWN_SPACING, 0.0)


# =========================================================
# CLIENT CONNECTION
# =========================================================

func join_server(ip: String = "") -> Error:
	stop_network()

	var target_ip := ip.strip_edges()
	if target_ip.is_empty():
		target_ip = server_ip.strip_edges()
	if target_ip.is_empty():
		target_ip = "127.0.0.1"

	var new_peer := ENetMultiplayerPeer.new()
	var error: Error = new_peer.create_client(target_ip, port)
	if error != OK:
		_log_error("Không thể tạo client tới %s:%d: %s" % [target_ip, port, error_string(error)])
		connection_status_changed.emit("Không thể tạo kết nối: %s" % error_string(error))
		return error

	peer = new_peer
	multiplayer.multiplayer_peer = peer
	_is_server = false
	_is_shutting_down = false
	players.clear()

	if not multiplayer.connected_to_server.is_connected(_on_connected_to_server):
		multiplayer.connected_to_server.connect(_on_connected_to_server)
	if not multiplayer.connection_failed.is_connected(_on_connection_failed):
		multiplayer.connection_failed.connect(_on_connection_failed)
	if not multiplayer.server_disconnected.is_connected(_on_server_disconnected):
		multiplayer.server_disconnected.connect(_on_server_disconnected)

	_log("Connecting to %s:%d ..." % [target_ip, port])
	connection_status_changed.emit("Đang kết nối tới %s:%d" % [target_ip, port])
	return OK


func _on_connected_to_server() -> void:
	_log("Connected to server. Local peer ID: %d" % multiplayer.get_unique_id())
	connection_status_changed.emit("Đã kết nối server")


func _on_connection_failed() -> void:
	_log_error("Kết nối server thất bại")
	connection_status_changed.emit("Kết nối thất bại")
	_clear_peer()


func _on_server_disconnected() -> void:
	_log_error("Đã mất kết nối server")
	connection_status_changed.emit("Mất kết nối server")
	snapshot_received.emit([])
	_clear_peer()


# =========================================================
# CLIENT -> SERVER INPUT
# =========================================================

func send_player_input(direction: Vector2, aim_angle: float = 0.0) -> void:
	if _is_server or peer == null:
		return
	if peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	if not is_finite(direction.x) or not is_finite(direction.y) or not is_finite(aim_angle):
		return
	submit_input.rpc_id(1, direction.limit_length(1.0), aim_angle)

@rpc("any_peer", "call_remote", "unreliable")
func submit_input(direction: Vector2, aim_angle: float) -> void:
	if not multiplayer.is_server() or not _is_server:
		return
	var sender_id: int = multiplayer.get_remote_sender_id()
	if not players.has(sender_id):
		return
	if not is_finite(direction.x) or not is_finite(direction.y) or not is_finite(aim_angle):
		return
	players[sender_id]["input"] = direction.limit_length(1.0)
	players[sender_id]["aim_angle"] = wrapf(aim_angle, -PI, PI)


# Client gui trang bi; server chi luu descriptor da serialize, khong nhan Resource tu client.
func send_equipment_state(left_item: Dictionary, right_item: Dictionary) -> void:
	if _is_server or peer == null:
		return
	if peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return
	submit_equipment_state.rpc_id(1, left_item, right_item)


@rpc("any_peer", "call_remote", "reliable")
func submit_equipment_state(left_item: Dictionary, right_item: Dictionary) -> void:
	if not multiplayer.is_server() or not _is_server:
		return
	var sender_id := multiplayer.get_remote_sender_id()
	if not players.has(sender_id):
		return
	players[sender_id]["weapon_left"] = _sanitize_item_descriptor(left_item)
	players[sender_id]["weapon_right"] = _sanitize_item_descriptor(right_item)
	_log("Equipment updated for peer %d" % sender_id)
	_broadcast_snapshot()


func _sanitize_item_descriptor(data: Dictionary) -> Dictionary:
	if data.is_empty():
		return {}
	var item_id := str(data.get("item_id", ""))
	if item_id.is_empty() or item_id.length() > 128:
		return {}
	# Chi cho phep cac kieu du lieu primitive de snapshot an toan qua RPC.
	var clean_stats: Array = []
	for stat in data.get("rolled_stats", []):
		if stat is Dictionary:
			clean_stats.append({
				"type": int(stat.get("type", 0)),
				"value": float(stat.get("value", 0.0))
			})
	var clean_options: Array = []
	for option in data.get("rolled_options", []):
		if option is Dictionary:
			clean_options.append({
				"stat_type": int(option.get("stat_type", 0)),
				"min_value": float(option.get("min_value", 0.0)),
				"max_value": float(option.get("max_value", 0.0))
			})
	return {
		"item_id": item_id,
		"unique_id": str(data.get("unique_id", "")),
		"rarity": int(data.get("rarity", 0)),
		"durability": clampf(float(data.get("durability", 100.0)), 0.0, 100.0),
		"rolled_stats": clean_stats,
		"rolled_options": clean_options
	}


# =========================================================
# SERVER MOVEMENT / SNAPSHOTS
# =========================================================

func _physics_process(delta: float) -> void:
	if not _is_server or peer == null:
		return
	if not multiplayer.is_server():
		return

	for id_variant in players.keys():
		var peer_id: int = int(id_variant)
		var player_state: Dictionary = players[peer_id]
		var direction: Vector2 = player_state.get("input", Vector2.ZERO)

		if direction.length_squared() > 0.0001:
			var position: Vector2 = player_state.get("position", SPAWN_ORIGIN)
			position += direction.limit_length(1.0) * player_speed * delta
			player_state["position"] = position
			players[peer_id] = player_state

	_snapshot_elapsed += delta
	if _snapshot_elapsed >= maxf(snapshot_interval, 0.01):
		_snapshot_elapsed = 0.0
		_broadcast_snapshot()


func _build_snapshot() -> Array:
	var snapshot: Array = []
	for id_variant in players.keys():
		var peer_id: int = int(id_variant)
		var state: Dictionary = players[peer_id]
		snapshot.append({
			"id": peer_id,
			"position": state.get("position", SPAWN_ORIGIN),
			"aim_angle": state.get("aim_angle", 0.0),
			"weapon_left": state.get("weapon_left", {}),
			"weapon_right": state.get("weapon_right", {})
		})
	return snapshot


func _broadcast_snapshot() -> void:
	if not _is_server or peer == null:
		return

	var snapshot: Array = _build_snapshot()
	if snapshot.is_empty():
		return

	for peer_id in multiplayer.get_peers():
		receive_snapshot.rpc_id(peer_id, snapshot)


@rpc("authority", "call_remote", "unreliable")
func receive_snapshot(snapshot: Array) -> void:
	# The server is the authority for this node; clients only consume snapshots.
	if multiplayer.is_server():
		return
	snapshot_received.emit(snapshot)


# =========================================================
# CLEANUP / STATUS
# =========================================================

func stop_network() -> void:
	_is_shutting_down = true
	_is_server = false
	players.clear()
	_snapshot_elapsed = 0.0
	_clear_peer()
	_is_shutting_down = false


func _clear_peer() -> void:
	if peer != null:
		peer.close()
		peer = null

	if is_inside_tree():
		multiplayer.multiplayer_peer = null


func is_connected_to_server() -> bool:
	return peer != null and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED


func is_server_running() -> bool:
	return _is_server and peer != null and multiplayer.is_server()


func _log(message: String) -> void:
	print("[NetworkManager] ", message)
	debug_message.emit(message)


func _log_error(message: String) -> void:
	push_warning("[NetworkManager] " + message)
	debug_message.emit("ERROR: " + message)
