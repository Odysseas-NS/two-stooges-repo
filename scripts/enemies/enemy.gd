extends CharacterBody2D

@export var speed: float = 150.0
@export var health: int = 3
@export var damage := 1
@export var xp_drop_scene: PackedScene

var player: Node2D

func _ready():
	player = get_tree().get_first_node_in_group("player")

func _physics_process(_delta):
	if player == null:
		return

	var direction = (player.global_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()

func take_damage(amount: int):
	health -= amount
	if health <= 0:
		drop_xp()
		queue_free()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.take_damage(damage)

func drop_xp():
	if xp_drop_scene == null:
		return

	# Defer the spawn to avoid physics query flush error
	var gem = xp_drop_scene.instantiate()
	var spawn_position = global_position
	var parent = get_parent()
	
	call_deferred("_spawn_xp_gem", gem, spawn_position, parent)

func _spawn_xp_gem(gem, spawn_pos: Vector2, parent: Node):
	if parent == null or gem == null:
		return
	parent.add_child(gem)
	gem.global_position = spawn_pos
