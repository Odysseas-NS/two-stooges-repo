extends Area2D

@export var coin_value := 1


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		PlayerData.add_coins(coin_value)
		queue_free()
