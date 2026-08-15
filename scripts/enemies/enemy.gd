extends CharacterBody2D

signal defeated

@export var speed: float = 150.0
@export var health: int = 3
@export var damage := 1
@export var xp_drop_scene: PackedScene
@export var coin_drop_scene: PackedScene
@export_range(0.0, 1.0) var coin_drop_chance := 0.25

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
		defeated.emit()
		drop_xp()
		drop_coin()
		queue_free()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.take_damage(damage)

func drop_xp() -> void:
	if xp_drop_scene == null:
		return

	var gem := xp_drop_scene.instantiate()
	_defer_spawn_loot(gem, global_position)


func drop_coin() -> void:
	if coin_drop_scene == null:
		return
	if randf() > coin_drop_chance:
		return

	var coin := coin_drop_scene.instantiate()
	var offset := Vector2(randf_range(-14.0, 14.0), randf_range(-14.0, 14.0))
	_defer_spawn_loot(coin, global_position + offset)


func _defer_spawn_loot(loot: Node, spawn_position: Vector2) -> void:
	var parent := get_parent()
	call_deferred("_spawn_loot", loot, spawn_position, parent)


func _spawn_loot(loot: Node, spawn_pos: Vector2, parent: Node) -> void:
	if parent == null or loot == null:
		return
	parent.add_child(loot)
	loot.global_position = spawn_pos
