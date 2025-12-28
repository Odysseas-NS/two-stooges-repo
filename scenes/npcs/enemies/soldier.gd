extends CharacterBody2D

@export var speed = 150 # Enemy movement speed (slower than player)
@export var patrol_radius = 200 # How far from spawn point to wander

var spawn_position: Vector2
var target_position: Vector2
var idle_timer: float = 0.0
var movement_timer: float = 0.0
var is_moving: bool = false

func _ready() -> void:
	# Remember spawn position for patrol area
	spawn_position = global_position
	# Choose initial target
	choose_new_target()

func _physics_process(delta: float) -> void:
	# Update timers
	if is_moving:
		movement_timer += delta
		# Move for 2-4 seconds then idle
		if movement_timer > randf_range(2.0, 4.0):
			is_moving = false
			idle_timer = 0.0
			movement_timer = 0.0
			update_animation("idle")
	else:
		idle_timer += delta
		# Idle for 1-3 seconds then move
		if idle_timer > randf_range(1.0, 3.0):
			is_moving = true
			choose_new_target()
			movement_timer = 0.0
			idle_timer = 0.0

	# Move towards target if moving
	if is_moving:
		move_towards_target(delta)
	else:
		velocity = Vector2.ZERO

	move_and_slide()

func choose_new_target() -> void:
	# Choose random position within patrol radius of spawn point
	var random_offset = Vector2(
		randf_range(-patrol_radius, patrol_radius),
		randf_range(-patrol_radius, patrol_radius)
	)
	target_position = spawn_position + random_offset
	update_animation("walk")

func move_towards_target(delta: float) -> void:
	var direction = (target_position - global_position).normalized()
	velocity = direction * speed

	# Flip sprite based on movement direction
	if velocity.x != 0:
		$Sprite2D.flip_h = velocity.x < 0

	# Check if reached target
	if global_position.distance_to(target_position) < 10:
		is_moving = false
		idle_timer = 0.0
		update_animation("idle")

# Function to control animations
func update_animation(animation: String) -> void:
	if has_node("AnimationPlayer"):
		$AnimationPlayer.play(animation)
