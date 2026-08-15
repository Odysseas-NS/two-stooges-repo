extends Area2D

@export var xp_value := 1

const MAGNET_SPEED := 420.0


func _physics_process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null or not player is Node2D:
		return

	var pickup_range := 0.0
	if "pickup_range" in player:
		pickup_range = float(player.pickup_range)
	if pickup_range <= 0.0:
		return

	var player_pos: Vector2 = player.global_position
	if global_position.distance_to(player_pos) <= pickup_range:
		global_position = global_position.move_toward(player_pos, MAGNET_SPEED * delta)


func _on_body_entered(body):
	if body.is_in_group("player"):
		body.gain_xp(xp_value)
		queue_free()
