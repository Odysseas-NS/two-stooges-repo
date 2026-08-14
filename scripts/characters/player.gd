extends CharacterBody2D

signal leveled_up

@export var speed := 300.0
@export var max_health := 10
@export var xp_to_next_level := 5
@export var attack_damage: int = 1
@export var attack_cooldown: float = 1.0
@export var projectile_scene: PackedScene
@export var fire_rate := 0.8

var level := 1
var current_xp := 0
var health := max_health
var invincible := false
var attack_timer := 0.0

# Upgrade stats
var projectile_damage := 1
var projectile_speed_boost := 0.0

# Weapon manager
@onready var weapon_manager := $WeaponManager


func _ready():
	health = max_health
	setup_weapons()

func setup_weapons():
	if weapon_manager == null:
		return
	
	# Create projectile weapon (default, always enabled)
	# Pass method name as string instead of Callable
	var projectile_weapon = weapon_manager.Weapon.new(
		"projectile",
		"Magic Bolt",
		"fire_projectile_weapon",
		fire_rate
	)
	weapon_manager.add_weapon(projectile_weapon)


func _physics_process(delta: float) -> void:
	move_player(delta)
	attack_timer -= delta

	if attack_timer <= 0:
		perform_attack()


func move_player(_delta):
	var direction = Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		direction.x += 1
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
	if Input.is_action_pressed("ui_down"):
		direction.y += 1
	if Input.is_action_pressed("ui_up"):
		direction.y -= 1

	velocity = direction.normalized() * speed
	move_and_slide()
	
		# Handle animations based on movement
	if velocity.length() == 0:
		# Not moving - play idle animation
		update_animation("idle")
	else:
		# Moving - determine direction and play appropriate animation
		if abs(velocity.x) > abs(velocity.y):
			# Horizontal movement (left or right)
			update_animation("right")
			# Flip sprite for left movement
			$Sprite2D.flip_h = velocity.x < 0
		else:
			# Vertical movement (up or down) - use right animation
			update_animation("right")
			$Sprite2D.flip_h = false


func perform_attack():
	attack_timer = attack_cooldown

	var areas = $HurtArea.get_overlapping_areas()
	for area in areas:
		var enemy = area.get_parent()
		if enemy.has_method("take_damage"):
			enemy.take_damage(attack_damage)


func take_damage(amount: int):
	if invincible:
		return

	health -= amount
	print("Player HP:", health)

	if health <= 0:
		die()
	else:
		start_invincibility()


func start_invincibility():
	invincible = true
	await get_tree().create_timer(0.5).timeout
	invincible = false


func die():
	print("💀 Player died")
	queue_free()
	%GameOver.visible = true
	get_tree().paused = true


func gain_xp(amount: int):
	current_xp += amount
	print("XP:", current_xp, "/", xp_to_next_level)

	if current_xp >= xp_to_next_level:
		level_up()


func level_up():
	level += 1
	current_xp = 0
	xp_to_next_level = int(xp_to_next_level * 1.5)

	print("🆙 LEVEL UP! Level:", level)
	leveled_up.emit()


func fire_projectile_weapon():
	var target = get_nearest_enemy()
	if target == null:
		return

	var projectile = projectile_scene.instantiate()
	get_parent().add_child(projectile)
	projectile.global_position = global_position
	
	# Apply upgrade stats to projectile
	projectile.damage = projectile_damage
	projectile.speed += projectile_speed_boost

	var projectile_direction = (target.global_position - global_position).normalized()
	projectile.direction = projectile_direction

func fire_missile_weapon():
	if weapon_manager == null or weapon_manager.missile_scene == null:
		return

	var target = get_nearest_enemy()
	if target == null:
		return

	var missile = weapon_manager.missile_scene.instantiate()
	get_parent().add_child(missile)
	missile.global_position = global_position
	missile.direction = (target.global_position - global_position).normalized()

func has_weapon(weapon_id: String) -> bool:
	if weapon_manager == null:
		return false
	return weapon_manager.has_weapon(weapon_id)

# Function to call for animations
func update_animation(animation):
	# Get the AnimationPlayer from node (Orc node)
	get_node("AnimationPlayer").play(animation)



func get_nearest_enemy():
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest = null
	var shortest_distance = INF

	for enemy in enemies:
		var distance = global_position.distance_to(enemy.global_position)
		if distance < shortest_distance:
			shortest_distance = distance
			nearest = enemy

	return nearest
