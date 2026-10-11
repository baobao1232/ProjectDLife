extends CharacterBody2D

@export var speed: float = 70.0

@export var right_hand_item: ItemInstance
@export var left_hand_item: ItemInstance
@onready var inventory_ui: InventoryUI = get_tree().current_scene.find_child(
	"InventoryUI",
	true,
	false
)
@export var test_item: ItemData
var current_interactable: Area2D = null
var facing_direction: int = 1

# =========================================================
# MULTIPLAYER - BỔ SUNG, GIỮ NGUYÊN CÁC HỆ THỐNG CŨ
# =========================================================

# Bật true cho Player được tạo bởi hệ thống multiplayer.
# Player chạy chế độ chơi đơn giữ nguyên false.
var network_managed: bool = false
var is_local_player: bool = true
var network_player_id: int = 0
var target_network_position: Vector2 = Vector2.ZERO
var network_move_direction: Vector2 = Vector2.ZERO
var network_has_received_position: bool = false
var network_equipment_initial_sent: bool = false
var _last_network_left_data: Dictionary = {}
var _last_network_right_data: Dictionary = {}


# =========================================================
# WALK ANIMATION
# =========================================================

var walk_time: float = 0.0
var is_walking: bool = false

var pivot_leg_left_start_rotation: float
var pivot_leg_right_start_rotation: float

var body_start_position: Vector2
var head_start_position: Vector2

@export var walk_animation_speed: float = 10.0
@export var walk_leg_angle: float = 12.0
@export var walk_body_bob: float = 1.0
@export var walk_head_bob: float = 0.5


# =========================================================
# TRẠNG THÁI GIỮ CHUỘT
# =========================================================

var right_hand_firing: bool = false
var left_hand_firing: bool = false


# =========================================================
# COOLDOWN TỪNG TAY
# =========================================================

var right_hand_cooldown: float = 0.0
var left_hand_cooldown: float = 0.0


# =========================================================
# TRẠNG THÁI CHÉM
# =========================================================

var right_hand_melee_attacking: bool = false
var left_hand_melee_attacking: bool = false


# =========================================================
# CẤU HÌNH ANIMATION CHÉM
# =========================================================

@export var melee_raise_angle: float = 55.0
@export var melee_raise_time: float = 0.12

@export var melee_swing_angle: float = 110.0
@export var melee_swing_time: float = 0.05

@export var melee_return_time: float = 0.14

# =========================================================
# IDLE ANIMATION
# =========================================================

var idle_time: float = 0.0

@export var idle_animation_speed: float = 2.5
@export var idle_body_bob: float = 0.5
@export var idle_head_bob: float = 0.25

func _ready() -> void:
	# =====================================================
	# ✅ THÊM GROUP "player" - BẮT BUỘC
	# =====================================================
	add_to_group("player")
	add_to_group("Player")
	print("✅ Player added to groups: ", get_groups())

	update_hand_items()
	setup_walk_animation()

	# Chạy deferred để hệ thống multiplayer kịp đánh dấu remote player
	# trước khi test inventory được khởi tạo.
	call_deferred("_initialize_test_inventory")


func _initialize_test_inventory() -> void:
	# Không thêm test item vào inventory của remote player.
	if network_managed and not is_local_player:
		return

	# =====================================================
	# TEST INVENTORY (giữ nguyên hành vi gốc)
	# =====================================================
	if test_item != null:
		print("TEST INVENTORY: ", test_item.item_name)
		var item_instance: ItemInstance = ItemFactory.create_item(test_item)
		if item_instance == null:
			print("TEST INVENTORY: CREATE INSTANCE FAILED")
		else:
			var result: bool = Inventorymanager.add_item(item_instance, 1)
			print("TEST ADD RESULT: ", result)
	else:
		print("TEST INVENTORY: test_item = NULL")
	
func _process(delta: float) -> void:
	if not network_managed or not network_has_received_position:
		return

	# Nhân vật mạng được nội suy giữa các snapshot để giảm giật.
	# Không dùng move_and_slide ở đây vì vị trí do server quyết định.
	var blend: float = 1.0 - exp(-18.0 * delta)
	global_position = global_position.lerp(target_network_position, blend)


func set_network_state(
	player_id: int,
	world_position: Vector2,
	local_player: bool
) -> void:
	network_managed = true
	network_player_id = player_id
	is_local_player = local_player
	if network_has_received_position:
		var position_delta: Vector2 = world_position - target_network_position
		if position_delta.length_squared() > 0.01:
			network_move_direction = position_delta.normalized()
		else:
			network_move_direction = Vector2.ZERO

	target_network_position = world_position

	if not network_has_received_position:
		global_position = world_position
		network_has_received_position = true

	# Chỉ Player cục bộ được camera, tương tác và nhận input.
	var camera: Camera2D = get_node_or_null("Camera2D")
	if camera != null:
		camera.enabled = local_player

	var interaction_area: Area2D = get_node_or_null("InteractionArea")
	if interaction_area != null:
		interaction_area.monitoring = local_player
		interaction_area.monitorable = local_player

	# Nếu scene có HurtBox thì chỉ bật hurtbox của nhân vật local ở giai đoạn này.
	# Đồng bộ sát thương mạng cần được xử lý phía server riêng.
	var hurt_box: Area2D = get_node_or_null("HurtBox")
	if hurt_box != null:
		hurt_box.monitoring = local_player
		hurt_box.monitorable = local_player


func _network_physics_process(delta: float) -> void:
	# Remote player không được đọc input, tương tác hoặc tự bắn từ máy này.
	if not is_local_player:
		var remote_direction: Vector2 = network_move_direction
		if remote_direction.length_squared() > 0.001:
			update_walk_animation(remote_direction, delta)
			idle_time = 0.0
			if absf(remote_direction.x) > 0.01:
				facing_direction = 1 if remote_direction.x > 0.0 else -1
				$Visual.scale.x = float(facing_direction)
		else:
			update_idle_animation(delta)
		return

	# Player local gửi hướng đi lên NetworkManager; server mới quyết định vị trí.
	var inventory: Node = get_tree().current_scene.find_child("InventoryUI", true, false)
	var direction := Vector2.ZERO
	if inventory == null or not inventory.visible:
		direction.x = Input.get_axis("move_left", "move_right")
		direction.y = Input.get_axis("move_up", "move_down")
		if direction.length() > 1.0:
			direction = direction.normalized()

	var network_manager: Node = get_tree().current_scene.find_child("NetworkManager", true, false)
	if network_manager != null and network_manager.has_method("send_player_input"):
		network_manager.send_player_input(direction)

	if direction.length_squared() > 0.0:
		update_walk_animation(direction, delta)
		idle_time = 0.0
	else:
		update_idle_animation(delta)

	update_facing()
	update_arm_aim()
	update_interaction_area()
	update_interactable()

	if right_hand_cooldown > 0.0:
		right_hand_cooldown -= delta
	if left_hand_cooldown > 0.0:
		left_hand_cooldown -= delta

	if right_hand_firing:
		auto_use_right_hand()
	if left_hand_firing:
		auto_use_left_hand()


func _physics_process(delta: float) -> void:
	if network_managed:
		_network_physics_process(delta)
		return

	# =====================================================
	# KHÓA PLAYER KHI MỞ INVENTORY
	# =====================================================

	var inventory_ui := get_tree().current_scene.find_child(
		"InventoryUI",
		true,
		false
	)

	if inventory_ui != null and inventory_ui.visible:

		velocity = Vector2.ZERO
		move_and_slide()

		return


	# =====================================================
	# DI CHUYỂN WASD
	# =====================================================

	var direction := Vector2.ZERO

	direction.x = Input.get_axis("move_left", "move_right")
	direction.y = Input.get_axis("move_up", "move_down")

	if direction.length() > 1.0:
		direction = direction.normalized()

	velocity = direction * speed
	move_and_slide()


	# =====================================================
	# WALK ANIMATION
	# =====================================================

	if direction.length() > 0.0:
		update_walk_animation(direction, delta)
		idle_time = 0.0
	else:
		update_idle_animation(delta)


	# =====================================================
	# QUAY MẶT THEO CHUỘT
	# =====================================================

	update_facing()


	# =====================================================
	# AIM HAI TAY
	# =====================================================

	update_arm_aim()


	# =====================================================
	# VÙNG TƯƠNG TÁC
	# =====================================================

	update_interaction_area()
	update_interactable()


	# =====================================================
	# GIẢM COOLDOWN
	# =====================================================

	if right_hand_cooldown > 0.0:
		right_hand_cooldown -= delta

	if left_hand_cooldown > 0.0:
		left_hand_cooldown -= delta


	# =====================================================
	# GIỮ CHUỘT
	# =====================================================

	if right_hand_firing:
		auto_use_right_hand()

	if left_hand_firing:
		auto_use_left_hand()

# =========================================================
# QUAY MẶT
# =========================================================

func update_facing() -> void:
	var mouse_position: Vector2 = get_global_mouse_position()

	if mouse_position.x > global_position.x:
		facing_direction = 1
	elif mouse_position.x < global_position.x:
		facing_direction = -1

	if facing_direction == -1:
		$Visual.scale.x = -1
	else:
		$Visual.scale.x = 1


# =========================================================
# AIM HAI TAY
# =========================================================

func update_arm_aim() -> void:
	var mouse_position: Vector2 = get_global_mouse_position()

	if not right_hand_melee_attacking:
		$Visual/ArmRight.look_at(mouse_position)

	if not left_hand_melee_attacking:
		$Visual/ArmLeft.look_at(mouse_position)


# =========================================================
# CHUỘT
# =========================================================

func _input(event: InputEvent) -> void:
	# Không cho remote player xử lý input của máy đang chạy client.
	if network_managed and not is_local_player:
		return

	# =====================================================
	# INVENTORY - PHÍM B
	# =====================================================

	if event is InputEventKey:

		if event.pressed and not event.echo:

			if event.keycode == KEY_B:

				print("ĐÃ BẤM B")

				if inventory_ui == null:

					print(
						"ERROR: Không tìm thấy InventoryUI"
					)

					return

				print(
					"InventoryUI tìm thấy: ",
					inventory_ui.name
				)

				inventory_ui.toggle_inventory()

				print(
					"Inventory visible: ",
					inventory_ui.visible
				)

				return


	# =====================================================
	# INTERACT - PHÍM E
	# =====================================================

	if event.is_action_pressed("interact"):

		print("ĐÃ BẤM E")

		if current_interactable != null:

			print(
				"ĐANG INTERACT: ",
				current_interactable.name
			)

			if current_interactable.has_method("interact"):

				current_interactable.interact()

			else:

				print(
					"OBJECT KHÔNG CÓ HÀM INTERACT: ",
					current_interactable.name
				)

		else:

			print(
				"BẤM E NHƯNG KHÔNG CÓ OBJECT"
			)

		return


	# =====================================================
	# CHUỘT
	# =====================================================

	if event is InputEventMouseButton:

		# =================================================
		# CHUỘT TRÁI
		# =================================================

		if event.button_index == MOUSE_BUTTON_LEFT:

			left_hand_firing = event.pressed

			if event.pressed:

				use_left_hand()


		# =================================================
		# CHUỘT PHẢI
		# =================================================

		elif event.button_index == MOUSE_BUTTON_RIGHT:

			right_hand_firing = event.pressed

			if event.pressed:

				use_right_hand()
# =========================================================
# TAY TRÁI
# =========================================================

func use_left_hand() -> void:
	if left_hand_item == null:
		print("Tay trái không có item")
		return

	if left_hand_item.item_data == null:
		return

	var item_data: ItemData = left_hand_item.item_data
	
	match item_data.item_type:
		ItemData.ItemType.WEAPON:
			use_weapon(left_hand_item, false)

		ItemData.ItemType.TOOL:
			use_tool(left_hand_item, false)

		ItemData.ItemType.CONSUMABLE:
			use_consumable(left_hand_item, false)

# =========================================================
# TAY PHẢI
# =========================================================

func use_right_hand() -> void:
	if right_hand_item == null:
		print("Tay phải không có item")
		return

	if right_hand_item.item_data == null:
		return

	var item_data: ItemData = right_hand_item.item_data

	match item_data.item_type:
		ItemData.ItemType.WEAPON:
			use_weapon(right_hand_item, true)

		ItemData.ItemType.TOOL:
			use_tool(right_hand_item, true)

		ItemData.ItemType.CONSUMABLE:
			use_consumable(right_hand_item, true)

# =========================================================
# AUTO USE - TAY TRÁI
# =========================================================

func auto_use_left_hand() -> void:
	if left_hand_item == null:
		return

	if left_hand_item.item_data == null:
		return

	if left_hand_item.item_data.item_type != ItemData.ItemType.WEAPON:
		return

	use_weapon(left_hand_item, false)

# =========================================================
# AUTO USE - TAY PHẢI
# =========================================================

func auto_use_right_hand() -> void:
	if right_hand_item == null:
		return

	if right_hand_item.item_data == null:
		return

	if right_hand_item.item_data.item_type != ItemData.ItemType.WEAPON:
		return

	use_weapon(right_hand_item, true)

# =========================================================
# HIỂN THỊ ITEM
# =========================================================

func update_hand_items() -> void:
	update_right_hand_item()
	update_left_hand_item()


func update_right_hand_item() -> void:
	var item_sprite: Sprite2D = $Visual/ArmRight/RightHandItem/ItemSprite

	if right_hand_item == null:
		item_sprite.texture = null
		item_sprite.position = Vector2.ZERO
		item_sprite.scale = Vector2.ONE
		return

	if right_hand_item.item_data == null:
		item_sprite.texture = null
		item_sprite.position = Vector2.ZERO
		item_sprite.scale = Vector2.ONE
		return

	var item_data: ItemData = right_hand_item.item_data

	item_sprite.texture = item_data.world_sprite
	item_sprite.scale = item_data.size
	item_sprite.position = -(item_data.grip_position * item_data.size)

func update_left_hand_item() -> void:
	var item_sprite: Sprite2D = $Visual/ArmLeft/LeftHandItem/ItemSprite

	if left_hand_item == null:
		item_sprite.texture = null
		item_sprite.position = Vector2.ZERO
		item_sprite.scale = Vector2.ONE
		return

	if left_hand_item.item_data == null:
		item_sprite.texture = null
		item_sprite.position = Vector2.ZERO
		item_sprite.scale = Vector2.ONE
		return

	var item_data: ItemData = left_hand_item.item_data

	item_sprite.texture = item_data.world_sprite
	item_sprite.scale = item_data.size
	item_sprite.position = -(item_data.grip_position * item_data.size)

# =========================================================
# ĐỔI ITEM
# =========================================================

func set_right_hand_item(item: ItemInstance) -> void:
	right_hand_item = item
	update_right_hand_item()
	_notify_network_equipment_changed()


func set_left_hand_item(item: ItemInstance) -> void:
	left_hand_item = item
	update_left_hand_item()
	_notify_network_equipment_changed()


func send_current_equipment_to_server() -> void:
	if network_equipment_initial_sent or not network_managed or not is_local_player:
		return
	network_equipment_initial_sent = true
	_notify_network_equipment_changed()


func _notify_network_equipment_changed() -> void:
	# Chi client local moi duoc gui trang bi len server.
	if not network_managed or not is_local_player:
		return

	var network_manager: Node = get_tree().current_scene.find_child(
		"NetworkManager", true, false
	)
	if network_manager != null and network_manager.has_method("send_equipment_state"):
		network_manager.send_equipment_state(
			_serialize_item_instance(left_hand_item),
			_serialize_item_instance(right_hand_item)
		)


func _serialize_item_instance(item: ItemInstance) -> Dictionary:
	if item == null or item.item_data == null:
		return {}

	var stats: Array = []
	for stat in item.rolled_stats:
		if stat == null:
			continue
		stats.append({"type": int(stat.type), "value": float(stat.value)})

	var options: Array = []
	for option in item.rolled_options:
		if option == null:
			continue
		options.append({
			"stat_type": int(option.stat_type),
			"min_value": float(option.min_value),
			"max_value": float(option.max_value)
		})

	return {
		"item_id": item.item_data.id,
		"unique_id": item.unique_id,
		"rarity": int(item.rarity),
		"durability": float(item.durability),
		"rolled_stats": stats,
		"rolled_options": options
	}


func apply_network_equipment(left_data: Dictionary, right_data: Dictionary) -> void:
	# Chi dung de hien thi trang bi nhan tu server tren remote player.
	# Snapshot den lien tuc, chi tao lai ItemInstance khi du lieu that su doi.
	if is_local_player:
		return

	if left_data != _last_network_left_data:
		_last_network_left_data = left_data.duplicate(true)
		left_hand_item = _deserialize_item_instance(left_data)
		update_left_hand_item()

	if right_data != _last_network_right_data:
		_last_network_right_data = right_data.duplicate(true)
		right_hand_item = _deserialize_item_instance(right_data)
		update_right_hand_item()


func _deserialize_item_instance(data: Dictionary) -> ItemInstance:
	if data.is_empty():
		return null

	var item_id := str(data.get("item_id", ""))
	if item_id.is_empty():
		return null

	var database := get_node_or_null("/root/ItemDatabase")
	if database == null or not database.has_method("get_item_data"):
		push_warning("Khong tim thay Autoload ItemDatabase.")
		return null

	var item_data: ItemData = database.get_item_data(item_id)
	if item_data == null:
		push_warning("ItemDatabase khong tim thay item id: " + item_id)
		return null

	var instance := ItemInstance.new()
	instance.item_data = item_data
	instance.unique_id = str(data.get("unique_id", ""))
	instance.rarity = int(data.get("rarity", ItemData.Rarity.COMMON))
	instance.durability = float(data.get("durability", 100.0))

	for stat_data in data.get("rolled_stats", []):
		if not (stat_data is Dictionary):
			continue
		var stat := ItemStat.new()
		stat.type = int(stat_data.get("type", ItemStat.StatType.DAMAGE))
		stat.value = float(stat_data.get("value", 0.0))
		instance.rolled_stats.append(stat)

	for option_data in data.get("rolled_options", []):
		if not (option_data is Dictionary):
			continue
		var option := ItemOption.new()
		option.stat_type = int(option_data.get("stat_type", ItemStat.StatType.DAMAGE))
		option.min_value = float(option_data.get("min_value", 0.0))
		option.max_value = float(option_data.get("max_value", 0.0))
		instance.rolled_options.append(option)

	return instance

# =========================================================
# GET ITEM STAT
# BASE STAT + ITEM OPTION
# =========================================================

func get_item_stat(
	item: ItemInstance,
	stat_type: ItemStat.StatType
) -> float:

	if item == null:
		return 0.0

	var total: float = 0.0

	# =====================================================
	# ROLLED BASE STAT
	# =====================================================

	for stat in item.rolled_stats:

		if stat == null:
			continue

		if stat.type != stat_type:
			continue

		total += stat.value

	# =====================================================
	# ROLLED OPTION
	# =====================================================

	for option in item.rolled_options:

		if option == null:
			continue

		if option.stat_type != stat_type:
			continue

		total += option.min_value

	return total
	
# =========================================================
# WEAPON DISPATCHER
# =========================================================

func use_weapon(item: ItemInstance, is_right_hand: bool) -> void:

	if item == null:
		return

	if item.item_data == null:
		return

	var item_data: ItemData = item.item_data

	match item_data.weapon_type:

		ItemData.WeaponType.RANGED:
			fire_weapon(item, is_right_hand)

		ItemData.WeaponType.MELEE:
			melee_attack(item, is_right_hand)

# =========================================================
# SÚNG
# =========================================================

func fire_weapon(item: ItemInstance, is_right_hand: bool) -> void:

	if item == null:
		return

	if item.item_data == null:
		return

	var item_data: ItemData = item.item_data

	var fire_rate: float = get_item_stat(
		item,
		ItemStat.StatType.FIRE_RATE
	)

	if fire_rate <= 0.0:
		print("WEAPON ERROR: Fire Rate <= 0: ", item_data.item_name)
		return

	if is_right_hand:

		if right_hand_cooldown > 0.0:
			return

		right_hand_cooldown = fire_rate

	else:

		if left_hand_cooldown > 0.0:
			return

		left_hand_cooldown = fire_rate

	var item_sprite: Sprite2D

	if is_right_hand:
		item_sprite = $Visual/ArmRight/RightHandItem/ItemSprite
	else:
		item_sprite = $Visual/ArmLeft/LeftHandItem/ItemSprite

	if item_sprite.texture == null:
		print(
			"WEAPON ERROR: ItemSprite không có texture: ",
			item_data.item_name
		)
		return

	var muzzle_position: Vector2 = item_sprite.to_global(
		item_data.muzzle_position
	)

	var direction: Vector2 = (
		get_global_mouse_position() - muzzle_position
	).normalized()

	var bullet_scene: PackedScene = preload(
		"res://Items/Scenes/Bullet.tscn"
	)

	var bullet = bullet_scene.instantiate()

	get_tree().current_scene.add_child(bullet)

	bullet.global_position = muzzle_position
	bullet.rotation = direction.angle()

	var muzzle_flash_scene: PackedScene = preload(
		"res://Items/Scenes/MuzzleFlash.tscn"
	)

	var muzzle_flash := muzzle_flash_scene.instantiate()

	get_tree().current_scene.add_child(muzzle_flash)

	muzzle_flash.global_position = muzzle_position
	muzzle_flash.rotation = direction.angle()

	var bullet_speed: float = get_item_stat(
		item,
		ItemStat.StatType.BULLET_SPEED
	)

	var weapon_range: float = get_item_stat(
		item,
		ItemStat.StatType.RANGE
	)

	var damage: float = get_item_stat(
		item,
		ItemStat.StatType.DAMAGE
	)

	print("========== FIRE WEAPON ==========")
	print("Weapon      : ", item_data.item_name)
	print("Fire Rate   : ", fire_rate)
	print("Bullet Speed: ", bullet_speed)
	print("Range       : ", weapon_range)
	print("Damage      : ", damage)
	print(
		"Hand        : ",
		"RIGHT" if is_right_hand else "LEFT"
	)
	print("=================================")

	bullet.setup(
		direction,
		item
	)

# =========================================================
# CẬN CHIẾN
# =========================================================

func melee_attack(item: ItemInstance, is_right_hand: bool) -> void:

	if item == null:
		return

	if item.item_data == null:
		return

	var attack_cooldown: float = get_item_stat(
		item,
		ItemStat.StatType.ATTACK_SPEED
	)

	if attack_cooldown <= 0.0:
		return

	if is_right_hand:

		if right_hand_melee_attacking:
			return

		if right_hand_cooldown > 0.0:
			return

		right_hand_cooldown = attack_cooldown
		right_hand_melee_attacking = true

	else:

		if left_hand_melee_attacking:
			return

		if left_hand_cooldown > 0.0:
			return

		left_hand_cooldown = attack_cooldown
		left_hand_melee_attacking = true

	var arm: Node2D

	if is_right_hand:
		arm = $Visual/ArmRight
	else:
		arm = $Visual/ArmLeft

	var start_rotation: float = arm.rotation

	var raise_angle: float = deg_to_rad(
		melee_raise_angle
	)

	var raise_rotation: float

	if is_right_hand:
		raise_rotation = start_rotation - raise_angle
	else:
		raise_rotation = start_rotation + raise_angle

	var swing_angle: float = deg_to_rad(
		melee_swing_angle
	)

	var swing_rotation: float

	if is_right_hand:
		swing_rotation = raise_rotation + swing_angle
	else:
		swing_rotation = raise_rotation - swing_angle

	var tween := create_tween()

	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(
		arm,
		"rotation",
		raise_rotation,
		melee_raise_time
	)

	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)

	tween.tween_property(
		arm,
		"rotation",
		swing_rotation,
		melee_swing_time
	)

	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(
		arm,
		"rotation",
		start_rotation,
		melee_return_time
	)

	await tween.finished

	if is_right_hand:
		right_hand_melee_attacking = false
	else:
		left_hand_melee_attacking = false
		
# =========================================================
# TOOL
# =========================================================

func use_tool(item: ItemInstance, is_right_hand: bool) -> void:
	if item == null:
		return
	if item.item_data == null:
		return

	print("Dùng tool: ", item.item_data.item_name)

# =========================================================
# CONSUMABLE
# =========================================================

func use_consumable(item: ItemInstance, is_right_hand: bool) -> void:
	if item == null:
		return
	if item.item_data == null:
		return

	print("Dùng vật phẩm: ", item.item_data.item_name)
	
# =========================================================
# INTERACTION AREA
# =========================================================

func update_interaction_area() -> void:

	var direction: Vector2 = (
		get_global_mouse_position() - global_position
	).normalized()

	var offset := Vector2(
		direction.x * $InteractionArea.interaction_distance_x,
		direction.y * $InteractionArea.interaction_distance_y
	)

	$InteractionArea.global_position = global_position + offset
	$InteractionArea.rotation = direction.angle()

# =========================================================
# DETECT OBJECT CÓ THỂ TƯƠNG TÁC
# =========================================================

func update_interactable() -> void:

	var old_interactable: Area2D = current_interactable

	current_interactable = null

	var areas: Array[Area2D] = (
		$InteractionArea.get_overlapping_areas()
	)

	# =====================================================
	# TÌM OBJECT CÓ THỂ TƯƠNG TÁC
	# =====================================================

	for area: Area2D in areas:

		if area.has_method("interact"):

			if area is WorldItem:

				var world_item: WorldItem = area

				if world_item.item_instance == null:
					print(
						"WorldItem không có ItemInstance: ",
						world_item.name
					)
					continue

				if world_item.item_instance.item_data == null:
					print(
						"ItemInstance không có ItemData: ",
						world_item.name
					)
					continue

			current_interactable = area
			break

	# =====================================================
	# TARGET KHÔNG THAY ĐỔI
	# =====================================================

	if old_interactable == current_interactable:
		return

	# =====================================================
	# TẮT OBJECT CŨ
	# =====================================================

	if old_interactable != null:

		if old_interactable is WorldItem:

			var old_item: WorldItem = old_interactable

			old_item.item_name_label.visible = false
			old_item.hide_interact_button()

			if old_item.item_instance != null \
			and old_item.item_instance.item_data != null:

				print(
					"Ẩn tên: ",
					old_item.item_instance.item_data.item_name
				)

			else:

				print(
					"Ẩn WorldItem không có ItemInstance: ",
					old_item.name
				)

	# =====================================================
	# KHÔNG CÓ OBJECT
	# =====================================================

	if current_interactable == null:

		print(
			"Không còn WorldItem trong vùng tương tác"
		)

		return

	# =====================================================
	# WORLD ITEM
	# =====================================================

	if current_interactable is WorldItem:

		var new_item: WorldItem = current_interactable

		if new_item.item_instance == null:

			print(
				"WorldItem không có ItemInstance: ",
				new_item.name
			)

			return

		if new_item.item_instance.item_data == null:

			print(
				"ItemInstance không có ItemData: ",
				new_item.name
			)

			return

		var item_data: ItemData = (
			new_item.item_instance.item_data
		)

		# =================================================
		# HIỆN TÊN ITEM
		# =================================================

		new_item.item_name_label.text = item_data.item_name
		new_item.item_name_label.visible = true

		# =================================================
		# HIỆN BUTTON E
		# =================================================

		new_item.show_interact_button()

		# =================================================
		# DEBUG
		# =================================================

		print(
			"ITEM DETECTED: ",
			item_data.item_name,
			" | UID: ",
			new_item.item_instance.unique_id,
			" | Rarity: ",
			new_item.item_instance.rarity
		)

	# =====================================================
	# OBJECT KHÁC WORLD ITEM
	# =====================================================

	else:

		print(
			"OBJECT DETECTED: ",
			current_interactable.name
		)
# =========================================================
# WALK ANIMATION
# =========================================================

func setup_walk_animation() -> void:

	# =====================================================
	# LƯU ROTATION GỐC CỦA PIVOT
	# =====================================================

	pivot_leg_left_start_rotation = (
		$Visual/PivotLegLeft.rotation
	)

	pivot_leg_right_start_rotation = (
		$Visual/PivotLegRight.rotation
	)


	# =====================================================
	# LƯU BODY / HEAD
	# =====================================================

	body_start_position = $Visual/Body.position
	head_start_position = $Visual/Head.position



# =========================================================
# WALK
# =========================================================

func update_walk_animation(
	direction: Vector2,
	delta: float
) -> void:

	var moving := direction.length() > 0.0


	# =====================================================
	# ĐANG ĐI
	# =====================================================

	if moving:

		is_walking = true

		walk_time += delta * walk_animation_speed

		var swing := sin(walk_time)


		# =================================================
		# CHÂN TRÁI
		# XOAY RA
		# =================================================

		$Visual/PivotLegLeft.rotation = (
			pivot_leg_left_start_rotation
			+ deg_to_rad(swing * walk_leg_angle)
		)


		# =================================================
		# CHÂN PHẢI
		# XOAY NGƯỢC LẠI
		# =================================================

		$Visual/PivotLegRight.rotation = (
			pivot_leg_right_start_rotation
			- deg_to_rad(swing * walk_leg_angle)
		)


		# =================================================
		# BODY NHÚN NHẸ
		# =================================================

		$Visual/Body.position = (
			body_start_position
			+ Vector2(
				0.0,
				-abs(swing) * walk_body_bob
			)
		)


		# =================================================
		# HEAD NHÚN NHẸ
		# =================================================

		$Visual/Head.position = (
			head_start_position
			+ Vector2(
				0.0,
				-abs(swing) * walk_head_bob
			)
		)


	# =====================================================
	# ĐỨNG YÊN
	# =====================================================

	else:

		if not is_walking:
			return

		is_walking = false
		walk_time = 0.0


		# =================================================
		# TRẢ PIVOT VỀ VỊ TRÍ GỐC
		# =================================================

		$Visual/PivotLegLeft.rotation = (
			pivot_leg_left_start_rotation
		)

		$Visual/PivotLegRight.rotation = (
			pivot_leg_right_start_rotation
		)


		# =================================================
		# BODY / HEAD VỀ GỐC
		# =================================================

		$Visual/Body.position = body_start_position
		$Visual/Head.position = head_start_position

# =========================================================
# IDLE ANIMATION
# =========================================================

func update_idle_animation(delta: float) -> void:

	# Nếu vừa dừng đi thì reset walk trước
	if is_walking:
		is_walking = false
		walk_time = 0.0

		$Visual/PivotLegLeft.rotation = (
			pivot_leg_left_start_rotation
		)

		$Visual/PivotLegRight.rotation = (
			pivot_leg_right_start_rotation
		)

	idle_time += delta * idle_animation_speed

	var breathe := sin(idle_time)


	# =====================================================
	# BODY - THỞ NHẸ
	# =====================================================

	$Visual/Body.position = (
		body_start_position
		+ Vector2(
			0.0,
			breathe * idle_body_bob
		)
	)


	# =====================================================
	# HEAD - NHÚN NHẸ HƠN BODY
	# =====================================================

	$Visual/Head.position = (
		head_start_position
		+ Vector2(
			0.0,
			breathe * idle_head_bob
		)
	)
