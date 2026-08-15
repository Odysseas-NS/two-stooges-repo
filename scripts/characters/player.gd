extends CharacterBody2D

signal leveled_up
signal died

@export var speed := 300.0
@export var max_health := 10
@export var xp_to_next_level := 5
@export var attack_damage: int = 1
@export var attack_cooldown: float = 1.0
@export var axe_scene: PackedScene
@export var fire_rate := 0.8

var level := 1
var current_xp := 0
var health := max_health
var invincible := false
var attack_timer := 0.0
var xp_gain_bonus := 0
var is_dead := false

var _regen_buffer := 0.0

# Permanent upgrade stats
var projectile_damage := 1
var axe_speed_boost := 0.0
var gold_gain_bonus := 0
var cooldown_reduction := 0.0
var difficulty_bonus := 0.0
var pickup_range := 0.0
var armor := 0
var health_regen := 0.0
var projectile_count := 1
var revives_remaining := 0

# Weapon manager
@onready var weapon_manager := $WeaponManager


func _ready():
	PlayerData.apply_to_player(self)
	setup_weapons()

func setup_weapons():
	if weapon_manager == null:
		return
	
	var axe_weapon = weapon_manager.Weapon.new(
		"axe",
		"Axe",
		"fire_axe_weapon",
		fire_rate
	)
	weapon_manager.add_weapon(axe_weapon)


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	move_player(delta)
	attack_timer -= delta

	if attack_timer <= 0:
		perform_attack()

	if health_regen > 0.0 and health < max_health:
		_regen_buffer += health_regen * delta
		while _regen_buffer >= 1.0 and health < max_health:
			health += 1
			_regen_buffer -= 1.0


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
	
	if velocity.length() == 0:
		update_animation("idle")
	else:
		if abs(velocity.x) > abs(velocity.y):
			update_animation("right")
			$Sprite2D.flip_h = velocity.x < 0
		else:
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
	if invincible or is_dead:
		return

	var reduced := maxi(1, amount - armor)
	health -= reduced
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
	if is_dead:
		return

	is_dead = true
	print("💀 Player died")
	visible = false
	weapon_manager.set_process(false)
	died.emit()


func revive():
	is_dead = false
	health = max_health
	visible = true
	weapon_manager.set_process(true)
	start_invincibility()


func gain_xp(amount: int):
	current_xp += amount + xp_gain_bonus
	print("XP:", current_xp, "/", xp_to_next_level)

	if current_xp >= xp_to_next_level:
		level_up()


func level_up():
	level += 1
	current_xp = 0
	xp_to_next_level = int(xp_to_next_level * 1.5)

	print("🆙 LEVEL UP! Level:", level)
	leveled_up.emit()


func fire_axe_weapon():
	var facing := -1 if $Sprite2D.flip_h else 1
	for i in range(projectile_count):
		var axe = axe_scene.instantiate()
		get_parent().add_child(axe)
		weapon_manager.apply_projectile_damage(axe, projectile_damage)
		axe.launch_speed += axe_speed_boost

		var spread_offset := Vector2((i - (projectile_count - 1) * 0.5) * 14.0, 0.0)
		axe.launch(global_position + spread_offset, facing)


func fire_magic_missile_weapon():
	if weapon_manager == null or weapon_manager.magic_missile_scene == null:
		return

	var target = get_nearest_enemy()
	if target == null:
		return

	for i in range(projectile_count):
		var missile = weapon_manager.magic_missile_scene.instantiate()
		get_parent().add_child(missile)
		weapon_manager.apply_projectile_damage(missile, projectile_damage)
		missile.global_position = global_position + Vector2((i - (projectile_count - 1) * 0.5) * 10.0, 0.0)
		missile.direction = (target.global_position - global_position).normalized()

func has_weapon(weapon_id: String) -> bool:
	if weapon_manager == null:
		return false
	return weapon_manager.has_weapon(weapon_id)

func update_animation(animation):
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
