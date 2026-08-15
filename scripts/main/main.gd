extends Node2D


@export var enemy_scene: PackedScene
@export var upgrade_screen_scene: PackedScene = preload("res://scenes/ui/upgrade_screen.tscn")
@export var game_hud_scene: PackedScene = preload("res://scenes/ui/game_hud.tscn")
@export var pause_screen_scene: PackedScene = preload("res://scenes/ui/pause_screen.tscn")
@export var spawn_distance_min := 600.0  # Minimum distance from player
@export var spawn_distance_max := 800.0  # Maximum distance from player

@onready var spawner := $EnemySpawner
@onready var difficulty_manager = $DifficultyManager
@onready var upgrade_manager := $UpgradeManager
@onready var player := $Player

var upgrade_screen: CanvasLayer
var game_hud: CanvasLayer
var pause_screen: CanvasLayer

func _ready():
	print("DifficultyManager:", difficulty_manager)
	spawner.wait_time = 1.5
	
	# Setup upgrade system
	print("🔧 Setting up upgrade system...")
	print("  upgrade_screen_scene: ", upgrade_screen_scene)
	
	if upgrade_screen_scene == null:
		push_error("❌ upgrade_screen_scene is not assigned in the Main scene!")
		push_error("   Please assign res://scenes/ui/upgrade_screen.tscn in the Inspector")
		return
	
	upgrade_screen = upgrade_screen_scene.instantiate()
	if upgrade_screen == null:
		push_error("❌ Failed to instantiate upgrade_screen!")
		return
	
	add_child(upgrade_screen)
	print("✅ Upgrade screen instantiated and added")
	
	if upgrade_screen.has_signal("upgrade_selected"):
		upgrade_screen.upgrade_selected.connect(_on_upgrade_selected)
		print("✅ Connected upgrade_selected signal")
	else:
		push_error("❌ upgrade_screen doesn't have upgrade_selected signal!")
	
	if player != null:
		player.leveled_up.connect(_on_player_level_up)
		player.died.connect(_on_player_died)

	game_hud = game_hud_scene.instantiate()
	add_child(game_hud)
	if game_hud.has_method("setup") and player != null:
		game_hud.setup(player)

	pause_screen = pause_screen_scene.instantiate()
	add_child(pause_screen)
	if pause_screen.has_method("setup"):
		pause_screen.setup(upgrade_screen, %GameOver)

	if %GameOver.has_method("setup"):
		%GameOver.setup(player)



func _process(_delta):
	if difficulty_manager == null:
		return

	var diff := get_total_difficulty()
	spawner.wait_time = max(0.2, 1.5 - diff * 0.1)



func _on_enemy_spawner_timeout():
	if enemy_scene == null:
		return

	var enemy = enemy_scene.instantiate()
	add_child(enemy)

	apply_difficulty(enemy)
	enemy.global_position = get_random_spawn_position()

	if game_hud != null and enemy.has_signal("defeated"):
		enemy.defeated.connect(game_hud.register_kill)


func apply_difficulty(enemy):
	var diff := get_total_difficulty()

	enemy.health = int(enemy.health * diff)
	enemy.speed *= 1.0 + diff * 0.1
	if "damage" in enemy:
		enemy.damage = maxi(1, int(enemy.damage * (1.0 + diff * 0.08)))


func get_total_difficulty() -> float:
	if difficulty_manager == null:
		return 1.0

	var diff: float = difficulty_manager.difficulty
	if player != null and "difficulty_bonus" in player:
		diff += float(player.difficulty_bonus)
	return diff


func _on_player_died() -> void:
	if %GameOver.has_method("show_game_over") and player != null:
		%GameOver.show_game_over(player.revives_remaining > 0)


func get_random_spawn_position() -> Vector2:
	if player == null:
		# Fallback if player not found
		var radius = 700
		var fallback_angle = randf() * TAU
		return global_position + Vector2(cos(fallback_angle), sin(fallback_angle)) * radius
	
	var player_pos = player.global_position
	var viewport = get_viewport()
	
	# Get viewport size (visible area)
	var viewport_size = viewport.get_visible_rect().size
	
	# Calculate minimum safe distance to spawn outside viewport
	# Use the larger dimension (width or height) plus a buffer
	var viewport_diagonal = viewport_size.length()
	var safe_distance = max(viewport_diagonal / 2.0, spawn_distance_min)
	
	# Clamp to max distance
	safe_distance = min(safe_distance, spawn_distance_max)
	
	# Random angle around player (360 degrees)
	var spawn_angle = randf() * TAU
	
	# Calculate spawn position at safe distance from player
	var spawn_pos = player_pos + Vector2(cos(spawn_angle), sin(spawn_angle)) * safe_distance
	
	return spawn_pos


func _on_player_level_up():
	print("🎯 _on_player_level_up() called")
	print("  upgrade_screen: ", upgrade_screen)
	print("  upgrade_manager: ", upgrade_manager)
	
	if upgrade_screen == null:
		push_error("❌ upgrade_screen is null!")
		return
	
	if upgrade_manager == null:
		push_error("❌ upgrade_manager is null!")
		return
	
	var upgrades = upgrade_manager.get_random_upgrades(3, player)
	print("  Got ", upgrades.size(), " upgrades")
	upgrade_screen.show_upgrades(upgrades)
	print("  Called show_upgrades()")

func _on_upgrade_selected(upgrade):
	print("🎁 _on_upgrade_selected() called")
	print("  upgrade: ", upgrade)
	print("  upgrade_manager: ", upgrade_manager)
	print("  player: ", player)
	
	if upgrade_manager == null:
		push_error("❌ upgrade_manager is null!")
		return
	
	if player == null:
		push_error("❌ player is null!")
		return
	
	print("  Applying upgrade: ", upgrade.name)
	upgrade_manager.apply_upgrade(upgrade, player)
	print("✅ Applied upgrade: ", upgrade.name)
