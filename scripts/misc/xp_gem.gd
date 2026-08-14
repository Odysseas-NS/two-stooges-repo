extends Area2D

@export var xp_value := 1

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.gain_xp(xp_value)
		queue_free()
