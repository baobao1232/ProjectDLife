extends Node2D

## MultiplayerWorld.gd
## Attach to the root of Maps/Node2d.tscn.
## Requires NetworkManager. Players is created automatically if missing.

const PLAYER_SCENE: PackedScene = preload("res://Scene/Players.tscn")
const SERVER_ARG: String = "--server"

@onready var network: Node = $NetworkManager
var players_root: Node2D
var is_server_mode: bool = false
var spawned_players: Dictionary = {}

var status_label: Label
var connection_panel: PanelContainer
var ip_input: LineEdit
var connect_button: Button
var debug_lines: Array[String] = []
const MAX_DEBUG_LINES: int = 10


func _ready() -> void:
	is_server_mode = OS.get_cmdline_user_args().has(SERVER_ARG)
	players_root = get_node_or_null("Players") as Node2D
	if players_root == null:
		players_root = Node2D.new()
		players_root.name = "Players"
		add_child(players_root)
		_debug("Khong tim thay Players; da tu tao node.")

	# Xoa Player dat san; chi spawn tu snapshot server.
	var default_player: Node = get_node_or_null("Player")
	if default_player == null:
		default_player = players_root.get_node_or_null("Player")
	if is_instance_valid(default_player):
		default_player.free()
		_debug("Da xoa Player mac dinh.")

	_create_status_label()
	if not network.snapshot_received.is_connected(_on_snapshot_received):
		network.snapshot_received.connect(_on_snapshot_received)
	if not network.connection_status_changed.is_connected(_on_connection_status_changed):
		network.connection_status_changed.connect(_on_connection_status_changed)
	if network.has_signal("debug_message") and not network.debug_message.is_connected(_on_network_debug):
		network.debug_message.connect(_on_network_debug)

	_debug("DLife multiplayer controller ready")
	_debug("Mode: " + ("SERVER" if is_server_mode else "CLIENT"))
	if is_server_mode:
		var result: Error = network.start_server()
		if result == OK:
			_debug("SERVER ONLINE | UDP " + str(network.port))
		else:
			_debug("SERVER ERROR: " + error_string(result))
		return
	_create_connection_panel()


func _create_status_label() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "NetworkDebugLayer"
	canvas.layer = 100
	add_child(canvas)
	status_label = Label.new()
	status_label.name = "NetworkStatusLabel"
	status_label.position = Vector2(12, 12)
	status_label.size = Vector2(520, 230)
	status_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_label.add_theme_color_override("font_color", Color.WHITE)
	status_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	status_label.add_theme_constant_override("shadow_offset_x", 1)
	status_label.add_theme_constant_override("shadow_offset_y", 1)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	canvas.add_child(status_label)


func _debug(message: String) -> void:
	var line := "[%s] %s" % [Time.get_time_string_from_system(), message]
	print(line)
	debug_lines.append(line)
	while debug_lines.size() > MAX_DEBUG_LINES:
		debug_lines.pop_front()
	if is_instance_valid(status_label):
		status_label.text = "\n".join(debug_lines)


func _on_network_debug(message: String) -> void:
	_debug("NET: " + message)


func _create_connection_panel() -> void:
	var canvas := get_node_or_null("NetworkDebugLayer") as CanvasLayer
	if canvas == null:
		return
	connection_panel = PanelContainer.new()
	connection_panel.name = "ConnectionPanel"
	connection_panel.set_anchors_preset(Control.PRESET_CENTER)
	connection_panel.position = Vector2(-170, -100)
	connection_panel.custom_minimum_size = Vector2(340, 200)
	canvas.add_child(connection_panel)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	connection_panel.add_child(layout)
	var title := Label.new()
	title.text = "DLife - KẾT NỐI SERVER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	layout.add_child(title)
	var description := Label.new()
	description.text = "Nhập IP máy đang chạy server (UDP %s)" % str(network.port)
	layout.add_child(description)
	ip_input = LineEdit.new()
	ip_input.placeholder_text = "127.0.0.1 hoặc IP LAN"
	ip_input.text = str(network.server_ip)
	ip_input.clear_button_enabled = true
	ip_input.custom_minimum_size = Vector2(0, 38)
	layout.add_child(ip_input)
	connect_button = Button.new()
	connect_button.text = "KẾT NỐI"
	connect_button.custom_minimum_size = Vector2(0, 40)
	connect_button.pressed.connect(_on_connect_pressed)
	layout.add_child(connect_button)
	ip_input.text_submitted.connect(_on_ip_submitted)


func _on_ip_submitted(_text: String) -> void:
	_on_connect_pressed()


func _on_connect_pressed() -> void:
	var ip := ip_input.text.strip_edges()
	if ip.is_empty():
		_debug("ERROR: Chưa nhập IP server")
		return
	connect_button.disabled = true
	_debug("Connecting to %s:%s ..." % [ip, str(network.port)])
	var result: Error = network.join_server(ip)
	if result != OK:
		_debug("CLIENT ERROR: " + error_string(result))
		connect_button.disabled = false


func _on_connection_status_changed(message: String) -> void:
	_debug("NETWORK: " + message)
	var lowered := message.to_lower()
	if lowered.contains("đã kết nối"):
		if is_instance_valid(connection_panel):
			connection_panel.hide()
	elif lowered.contains("thất bại") or lowered.contains("mất kết nối") or lowered.contains("không thể tạo") or lowered.contains("không tạo được"):
		if is_instance_valid(connection_panel):
			connection_panel.show()
		if is_instance_valid(connect_button):
			connect_button.disabled = false


func _on_snapshot_received(snapshot: Array) -> void:
	if is_server_mode:
		return
	var active_ids: Dictionary = {}
	var local_id: int = multiplayer.get_unique_id()
	for entry in snapshot:
		if not (entry is Dictionary) or not entry.has("id") or not entry.has("position"):
			continue
		var player_id := int(entry["id"])
		var player_position: Vector2 = entry["position"]
		active_ids[player_id] = true
		var player: Node2D = spawned_players.get(player_id) as Node2D
		if not is_instance_valid(player):
			var instance: Node = PLAYER_SCENE.instantiate()
			player = instance as Node2D
			if player == null:
				push_error("Player scene root phải là Node2D hoặc CharacterBody2D")
				instance.free()
				continue
			player.name = "Player_%d" % player_id
			players_root.add_child(player)
			spawned_players[player_id] = player
			_debug("Spawned player ID %d" % player_id)
		var is_local := player_id == local_id
		if player.has_method("set_network_state"):
			player.set_network_state(player_id, player_position, is_local)
		else:
			push_error("Player.gd thiếu hàm set_network_state()")
		if player.has_method("set_player_name"):
			player.set_player_name("Player_%d" % player_id)
		if is_local and player.has_method("send_current_equipment_to_server"):
			player.send_current_equipment_to_server()
		if not is_local:
			if player.has_method("apply_network_aim"):
				player.apply_network_aim(float(entry.get("aim_angle", 0.0)))
			if player.has_method("apply_network_equipment"):
				player.apply_network_equipment(
					entry.get("weapon_left", {}),
					entry.get("weapon_right", {})
				)
	# Xoa player khong con trong snapshot.
	for key in spawned_players.keys().duplicate():
		var player_id := int(key)
		if not active_ids.has(player_id):
			var old_player: Node = spawned_players[key]
			spawned_players.erase(key)
			if is_instance_valid(old_player):
				old_player.queue_free()
			_debug("Removed player ID %d" % player_id)


func _exit_tree() -> void:
	if is_instance_valid(network) and network.has_method("stop_network"):
		network.stop_network()
