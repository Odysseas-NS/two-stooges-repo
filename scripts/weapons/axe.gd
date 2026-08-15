extends Area2D

@export var launch_speed := 500.0
@export var fall_gravity := 900.0
@export var damage := 1
@export var offscreen_margin := 48.0

var velocity := Vector2.ZERO
var _damaged_ids: Dictionary = {}


func launch(from_position: Vector2, facing: int) -> void:
	global_position = from_position
	velocity = Vector2(facing * launch_speed * 0.75, -launch_speed * 0.85)
	_update_rotation()


func _physics_process(delta: float) -> void:
	velocity.y += fall_gravity * delta
	global_position += velocity * delta
	_update_rotation()

	if global_position.y >= _get_screen_bottom_y():
		queue_free()


func _get_screen_bottom_y() -> float:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return global_position.y + offscreen_margin

	var half_height := get_viewport().get_visible_rect().size.y * 0.5 / camera.zoom.y
	return camera.global_position.y + half_height + offscreen_margin


func _update_rotation() -> void:
	if velocity.length_squared() > 1.0:
		rotation = velocity.angle()


func _try_damage(body: Node) -> void:
	if body == null:
		return
	var id := body.get_instance_id()
	if _damaged_ids.has(id):
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
		_damaged_ids[id] = true


func _on_body_entered(body: Node) -> void:
	_try_damage(body)


func _on_area_entered(area: Area2D) -> void:
	_try_damage(area.get_parent())
