extends Node2D

## Repeating ground layer that follows the camera to create an endless map feel.
@export var texture: Texture2D = preload("res://assets/map/TS_Forest_Grass.png")
@export var tile_size := Vector2(16, 16)
@export var atlas_tile := Vector2i(1, 1)
@export var viewport_padding := 2.5

@onready var _sprite: Sprite2D = $Sprite2D

var _camera: Camera2D


func _ready() -> void:
	_configure_sprite()
	call_deferred("_bind_camera")


func _configure_sprite() -> void:
	_sprite.texture = texture
	_sprite.centered = false
	_sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_sprite.region_enabled = true
	_sprite.region_rect = Rect2(
		atlas_tile.x * tile_size.x,
		atlas_tile.y * tile_size.y,
		tile_size.x,
		tile_size.y
	)


func _bind_camera() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player != null:
		_camera = player.get_node_or_null("Camera2D") as Camera2D


func _process(_delta: float) -> void:
	if _camera == null:
		return

	var viewport_size := get_viewport_rect().size / _camera.zoom
	var coverage := viewport_size * viewport_padding
	var center := _camera.get_screen_center_position()

	var tile_snapped_pos := Vector2(
		floor(center.x / tile_size.x) * tile_size.x,
		floor(center.y / tile_size.y) * tile_size.y
	)

	global_position = tile_snapped_pos - coverage * 0.5
	_sprite.scale = coverage / tile_size
