extends CanvasLayer

const HP_COLOR := Color(0.85, 0.15, 0.15)
const XP_COLOR := Color(0.2, 0.45, 0.95)
const COIN_COLOR := Color(0.92, 0.78, 0.28)
const BG_COLOR := Color(0.15, 0.15, 0.15, 0.85)
const SLOT_BG := Color(0.12, 0.12, 0.14, 0.92)
const SLOT_BORDER := Color(0.55, 0.52, 0.48)
const HP_BAR_OFFSET := Vector2(0, 58)
const MAX_WEAPON_SLOTS := 6
const WEAPON_SLOT_SIZE := 44

@onready var hp_bar: ProgressBar = %HPBar
@onready var xp_bar: ProgressBar = %XPBar
@onready var level_label: Label = %LevelLabel
@onready var timer_label: Label = %TimerLabel
@onready var kill_label: Label = %KillLabel
@onready var coin_label: Label = %CoinLabel
@onready var weapon_slots: HBoxContainer = %WeaponSlots

var player: Node2D = null
var elapsed_time := 0.0
var kill_count := 0
var _slot_icons: Array[TextureRect] = []


func _ready() -> void:
	_style_bar(hp_bar, HP_COLOR, 2)
	_style_bar(xp_bar, XP_COLOR, 0)
	_build_weapon_slots()
	kill_label.text = "Kills: 0"
	timer_label.text = "00:00"
	coin_label.add_theme_color_override("font_color", COIN_COLOR)
	_update_coins_label(PlayerData.coins)
	if not PlayerData.coins_changed.is_connected(_update_coins_label):
		PlayerData.coins_changed.connect(_update_coins_label)


func _exit_tree() -> void:
	if PlayerData.coins_changed.is_connected(_update_coins_label):
		PlayerData.coins_changed.disconnect(_update_coins_label)
	if player != null and is_instance_valid(player):
		var weapon_manager = player.get_node_or_null("WeaponManager")
		if weapon_manager != null and weapon_manager.weapons_changed.is_connected(_refresh_weapons):
			weapon_manager.weapons_changed.disconnect(_refresh_weapons)


func setup(player_node: Node2D) -> void:
	player = player_node
	_connect_weapon_manager()
	_refresh()
	_refresh_weapons()


func _connect_weapon_manager() -> void:
	if player == null:
		return
	var weapon_manager = player.get_node_or_null("WeaponManager")
	if weapon_manager == null:
		return
	if not weapon_manager.weapons_changed.is_connected(_refresh_weapons):
		weapon_manager.weapons_changed.connect(_refresh_weapons)


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


func _build_weapon_slots() -> void:
	for _i in range(MAX_WEAPON_SLOTS):
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(WEAPON_SLOT_SIZE, WEAPON_SLOT_SIZE)
		slot.add_theme_stylebox_override("panel", _slot_style())

		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.offset_left = 4
		icon.offset_top = 4
		icon.offset_right = -4
		icon.offset_bottom = -4
		icon.visible = false
		slot.add_child(icon)

		weapon_slots.add_child(slot)
		_slot_icons.append(icon)


func _refresh_weapons() -> void:
	if player == null or not is_instance_valid(player):
		return

	var weapon_manager = player.get_node_or_null("WeaponManager")
	if weapon_manager == null:
		return

	for i in range(MAX_WEAPON_SLOTS):
		var icon := _slot_icons[i]
		if i < weapon_manager.weapons.size():
			var weapon = weapon_manager.weapons[i]
			var icon_path: String = weapon_manager.get_weapon_icon(weapon.id)
			if icon_path.is_empty():
				icon.texture = null
				icon.visible = false
			else:
				icon.texture = load(icon_path)
				icon.visible = true
		else:
			icon.texture = null
			icon.visible = false


func _slot_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = SLOT_BG
	style.border_color = SLOT_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(2)
	return style


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
