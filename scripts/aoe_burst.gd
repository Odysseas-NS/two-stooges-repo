extends Node2D

@export var damage := 2
@export var radius := 150.0
@export var cooldown := 2.0

var timer := 0.0
var player: Node2D

func _ready():
	# Get player from weapon manager's parent
	var weapon_manager = get_parent()
	if weapon_manager:
		player = weapon_manager.get_parent()

func _physics_process(delta):
	if player == null:
		return
	
	timer -= delta
	if timer <= 0:
		burst()
		timer = cooldown

func burst():
	if player == null:
		return
	
	# Find all enemies in radius
	var enemies = get_tree().get_nodes_in_group("enemies")
	var hit_count = 0
	
	for enemy in enemies:
		var distance = player.global_position.distance_to(enemy.global_position)
		if distance <= radius:
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage)
				hit_count += 1
	
	if hit_count > 0:
		# Visual feedback (you can add particles/effects here later)
		print("💥 AoE Burst hit ", hit_count, " enemies")
