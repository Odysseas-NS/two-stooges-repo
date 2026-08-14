extends Node2D

@export var rotation_speed := 300.0  # degrees per second
@export var radius := 100.0
@export var damage := 1
@export var damage_cooldown := 0.5  # Time between damage ticks

var angle := 0.0
var damage_timer := 0.0
var player: Node2D

func _ready():
	# Get player from weapon manager's parent
	var weapon_manager = get_parent()
	if weapon_manager:
		player = weapon_manager.get_parent()

func _physics_process(delta):
	if player == null:
		return
	
	# Rotate around player
	angle += rotation_speed * delta
	var radians = deg_to_rad(angle)
	
	# Position relative to player
	global_position = player.global_position + Vector2(cos(radians), sin(radians)) * radius
	
	# Rotate the blade itself
	rotation = radians + PI / 2
	
	# Damage nearby enemies
	damage_timer -= delta
	if damage_timer <= 0:
		damage_nearby_enemies()
		damage_timer = damage_cooldown

var hit_count = 0

func damage_nearby_enemies():
	var hitbox = $Hitbox
	if hitbox == null:
		return
	
	var areas = hitbox.get_overlapping_areas()
	for area in areas:
		var enemy = area.get_parent()
		if enemy.has_method("take_damage"):
			enemy.take_damage(damage)
			hit_count += 1

	if hit_count > 0:
		# Visual feedback (you can add particles/effects here later)
		print("💥Rotating Blade hit ", hit_count, " enemies")
