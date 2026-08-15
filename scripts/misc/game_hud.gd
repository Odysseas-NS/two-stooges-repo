extends CanvasLayer

const HP_COLOR := Color(0.85, 0.15, 0.15)
const XP_COLOR := Color(0.2, 0.45, 0.95)
const COIN_COLOR := Color(0.92, 0.78, 0.28)
const BG_COLOR := Color(0.15, 0.15, 0.15, 0.85)
const HP_BAR_OFFSET := Vector2(0, 58)

@onready var hp_bar: ProgressBar = %HPBar
@onready var xp_bar: ProgressBar = %XPBar
@onready var level_label: Label = %LevelLabel
@onready var timer_label: Label = %TimerLabel
@onready var kill_label: Label = %KillLabel
@onready var coin_label: Label = %CoinLabel

var player: Node2D = null
var elapsed_time := 0.0
var kill_count := 0


func _ready() -> void:
	_style_bar(hp_bar, HP_COLOR, 2)
	_style_bar(xp_bar, XP_COLOR, 0)
	kill_label.text = "Kills: 0"
	timer_label.text = "00:00"
	coin_label.add_theme_color_override("font_color", COIN_COLOR)
	_update_coins_label(PlayerData.coins)
	if not PlayerData.coins_changed.is_connected(_update_coins_label):
		PlayerData.coins_changed.connect(_update_coins_label)


func _exit_tree() -> void:
	if PlayerData.coins_changed.is_connected(_update_coins_label):
		PlayerData.coins_changed.disconnect(_update_coins_label)


func setup(player_node: Node2D) -> void:
	player = player_node
	_refresh()


func register_kill() -> void:
	kill_count += 1
	kill_label.text = "Kills: %d" % kill_count


func _update_coins_label(total: int) -> void:
	coin_label.text = "Coins: %d" % total


func _process(delta: float) -> void:
	if not get_tree().paused:
		elapsed_time += delta
		timer_label.text = _format_time(elapsed_time)

	if player != null and is_instance_valid(player):
		_refresh()
		_update_hp_bar_position()


func _refresh() -> void:
	level_label.text = "Level %d" % player.level
	hp_bar.max_value = player.max_health
	hp_bar.value = player.health
	xp_bar.max_value = player.xp_to_next_level
	xp_bar.value = player.current_xp


func _update_hp_bar_position() -> void:
	var canvas_origin: Vector2 = player.get_global_transform_with_canvas().origin
	var bar_width: float = hp_bar.size.x
	hp_bar.global_position = canvas_origin + HP_BAR_OFFSET - Vector2(bar_width * 0.5, 0.0)


func _format_time(seconds: float) -> String:
	var total_seconds := int(seconds)
	@warning_ignore("integer_division")
	var minutes := total_seconds / 60
	var secs := total_seconds % 60
	return "%02d:%02d" % [minutes, secs]


func _style_bar(bar: ProgressBar, fill_color: Color, corner_radius: int) -> void:
	bar.show_percentage = false

	var bg := StyleBoxFlat.new()
	bg.bg_color = BG_COLOR
	bg.set_corner_radius_all(corner_radius)
	bar.add_theme_stylebox_override("background", bg)

	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.set_corner_radius_all(corner_radius)
	bar.add_theme_stylebox_override("fill", fill)
