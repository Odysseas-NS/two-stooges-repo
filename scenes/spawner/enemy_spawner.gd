extends Node2D

# Configuration
@export var soldier_scene: PackedScene # Link to soldier.tscn
@export var max_enemies: int = 10
@export var spawn_interval: float = 5.0
@export var spawn_buffer: float = 100.0 # Pixels outside camera view

# State tracking
var active_enemies: Array = []
var player: CharacterBody2D # Reference to player (Orc)

func _ready() -> void:
	# Get reference to player
	player = get_parent().get_node_or_null("Orc")
	if player == null:
		push_error("EnemySpawner: Could not find player node 'Orc'")
		return

	# Create and configure spawn timer
	var spawn_timer = Timer.new()
	spawn_timer.name = "SpawnTimer"
	spawn_timer.wait_time = spawn_interval
	spawn_timer.autostart = true
	spawn_timer.one_shot = false
	add_child(spawn_timer)
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)

func _on_spawn_timer_timeout() -> void:
	# Check if we can spawn more enemies
	if active_enemies.size() >= max_enemies:
		return

	# Check if soldier scene is loaded
	if soldier_scene == null:
		push_warning("EnemySpawner: soldier_scene not set")
		return

	# Calculate spawn position and spawn enemy
	var spawn_pos = calculate_spawn_position()
	spawn_enemy(spawn_pos)

func calculate_spawn_position() -> Vector2:
	# Get player camera
	var camera = player.get_node_or_null("Camera2D")
	if camera == null:
		# Fallback if no camera
		return player.global_position + Vector2(500, 0)

	var camera_pos = player.global_position
	var zoom = camera.zoom.x

	# Calculate visible area
	var viewport = get_viewport()
	if viewport == null:
		return camera_pos + Vector2(500, 0)

	var viewport_size = viewport.get_visible_rect().size
	var visible_width = viewport_size.x / zoom
	var visible_height = viewport_size.y / zoom

	# Choose random side (0=top, 1=right, 2=bottom, 3=left)
	var side = randi() % 4
	var spawn_pos = Vector2.ZERO

	match side:
		0: # Top
			spawn_pos.x = camera_pos.x + randf_range(-visible_width/2, visible_width/2)
			spawn_pos.y = camera_pos.y - visible_height/2 - spawn_buffer
		1: # Right
			spawn_pos.x = camera_pos.x + visible_width/2 + spawn_buffer
			spawn_pos.y = camera_pos.y + randf_range(-visible_height/2, visible_height/2)
		2: # Bottom
			spawn_pos.x = camera_pos.x + randf_range(-visible_width/2, visible_width/2)
			spawn_pos.y = camera_pos.y + visible_height/2 + spawn_buffer
		3: # Left
			spawn_pos.x = camera_pos.x - visible_width/2 - spawn_buffer
			spawn_pos.y = camera_pos.y + randf_range(-visible_height/2, visible_height/2)

	return spawn_pos

func spawn_enemy(position: Vector2) -> void:
	# Instantiate enemy
	var enemy = soldier_scene.instantiate()
	enemy.global_position = position

	# Connect to tree_exited signal for cleanup
	enemy.tree_exited.connect(_on_enemy_freed.bind(enemy))

	# Add to scene and tracking array
	get_parent().add_child(enemy)
	active_enemies.append(enemy)

	print("Enemy spawned at ", position, " (Total: ", active_enemies.size(), "/", max_enemies, ")")

func _on_enemy_freed(enemy: Node) -> void:
	# Remove from tracking array when enemy is freed
	var index = active_enemies.find(enemy)
	if index != -1:
		active_enemies.remove_at(index)
		print("Enemy removed (Total: ", active_enemies.size(), "/", max_enemies, ")")
