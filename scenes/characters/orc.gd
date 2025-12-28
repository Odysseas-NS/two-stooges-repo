extends CharacterBody2D

@export var speed = 250 # Characters Movement speed

func get_input():
	"""
	Get input function to map the direction of the player and make the movement
	"""
	var input_direction = Input.get_vector("letf", "right", "up", "down")
	velocity = input_direction * speed

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


func _physics_process(delta: float) -> void:
	get_input()
	move_and_slide()

# Function to call for animations
func update_animation(animation):
	# Get the AnimationPlayer from node (Orc node)
	get_node("AnimationPlayer").play(animation)
