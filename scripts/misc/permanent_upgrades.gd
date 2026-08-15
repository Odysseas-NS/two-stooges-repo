extends Control

const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"

const PANEL_BG := Color(0.12, 0.08, 0.22, 0.96)
const PANEL_BORDER := Color(0.78, 0.64, 0.24)
const BUTTON_BG := Color(0.32, 0.32, 0.36)
const BUTTON_HOVER := Color(0.4, 0.38, 0.48)
const BUTTON_PRESSED := Color(0.26, 0.24, 0.34)
const REFUND_BG := Color(0.55, 0.15, 0.15)
const REFUND_HOVER := Color(0.68, 0.2, 0.2)
const REFUND_PRESSED := Color(0.4, 0.1, 0.1)
const REFUND_BORDER := Color(0.85, 0.3, 0.3)
const ROW_BG := Color(0.18, 0.16, 0.28, 0.95)
const TEXT_PRIMARY := Color(0.95, 0.95, 0.95)
const TEXT_MUTED := Color(0.78, 0.78, 0.82)
const COIN_COLOR := Color(0.92, 0.78, 0.28)
const MAXED_COLOR := Color(0.55, 0.85, 0.55)

@onready var coins_label: Label = %CoinsLabel
@onready var upgrades_list: VBoxContainer = %UpgradesList


func _ready() -> void:
	_style_button(%BackButton, BUTTON_BG)
	_style_button(%RefundAllButton, REFUND_BG, REFUND_BORDER)
	coins_label.add_theme_color_override("font_color", COIN_COLOR)
	_refresh_ui()
	if not PlayerData.coins_changed.is_connected(_on_coins_changed):
		PlayerData.coins_changed.connect(_on_coins_changed)
	if not PlayerData.upgrades_changed.is_connected(_refresh_ui):
		PlayerData.upgrades_changed.connect(_refresh_ui)


func _exit_tree() -> void:
	if PlayerData.coins_changed.is_connected(_on_coins_changed):
		PlayerData.coins_changed.disconnect(_on_coins_changed)
	if PlayerData.upgrades_changed.is_connected(_refresh_ui):
		PlayerData.upgrades_changed.disconnect(_refresh_ui)


func _refresh_ui() -> void:
	coins_label.text = "Coins: %d" % PlayerData.coins
	for child in upgrades_list.get_children():
		child.queue_free()
	for upgrade_id in PlayerData.UPGRADE_IDS:
		upgrades_list.add_child(_build_upgrade_row(upgrade_id))


func _build_upgrade_row(upgrade_id: String) -> PanelContainer:
	var def: Dictionary = PlayerData.UPGRADE_DEFS[upgrade_id]
	var level := PlayerData.get_upgrade_level(upgrade_id)
	var max_level: int = def["bonuses"].size()
	var current_bonus := PlayerData.get_upgrade_bonus(upgrade_id)
	var next_cost := PlayerData.get_next_upgrade_cost(upgrade_id)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style(ROW_BG))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	margin.add_child(row)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)
	row.add_child(info)

	var title := Label.new()
	title.text = "%s  (%d/%d)" % [def["name"], level, max_level]
	title.add_theme_color_override("font_color", TEXT_PRIMARY)
	title.add_theme_font_size_override("font_size", 20)
	info.add_child(title)

	var description := Label.new()
	description.text = def["description"]
	description.add_theme_color_override("font_color", TEXT_MUTED)
	description.add_theme_font_size_override("font_size", 14)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(description)

	var bonus := Label.new()
	if level >= max_level:
		bonus.text = "Current bonus: +%d (maxed)" % current_bonus
		bonus.add_theme_color_override("font_color", MAXED_COLOR)
	else:
		var next_bonus: int = def["bonuses"][level]
		bonus.text = "Current: +%d  |  Next: +%d" % [current_bonus, next_bonus]
		bonus.add_theme_color_override("font_color", TEXT_MUTED)
	bonus.add_theme_font_size_override("font_size", 14)
	info.add_child(bonus)

	var buy_button := Button.new()
	buy_button.custom_minimum_size = Vector2(150, 0)
	buy_button.focus_mode = Control.FOCUS_NONE
	if level >= max_level:
		buy_button.text = "Maxed"
		buy_button.disabled = true
	else:
		buy_button.text = "Buy (%d)" % next_cost
		buy_button.disabled = not PlayerData.can_purchase_upgrade(upgrade_id)
		buy_button.pressed.connect(_on_buy_pressed.bind(upgrade_id))
	_style_button(buy_button, BUTTON_BG)
	row.add_child(buy_button)

	return panel


func _on_buy_pressed(upgrade_id: String) -> void:
	PlayerData.purchase_upgrade(upgrade_id)


func _on_coins_changed(_total: int) -> void:
	_refresh_ui()


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _on_refund_all_button_pressed() -> void:
	PlayerData.refund_all_upgrades()


func _style_button(button: Button, bg_color: Color, border_color: Color = PANEL_BORDER) -> void:
	var hover_color := REFUND_HOVER if bg_color != BUTTON_BG else BUTTON_HOVER
	var pressed_color := REFUND_PRESSED if bg_color != BUTTON_BG else BUTTON_PRESSED
	var disabled_color := Color(0.22, 0.22, 0.26)
	button.add_theme_stylebox_override("normal", _button_style(bg_color, border_color))
	button.add_theme_stylebox_override("hover", _button_style(hover_color, border_color))
	button.add_theme_stylebox_override("pressed", _button_style(pressed_color, border_color))
	button.add_theme_stylebox_override("disabled", _button_style(disabled_color, border_color))
	button.add_theme_color_override("font_color", TEXT_PRIMARY)
	button.add_theme_font_size_override("font_size", 20)


func _button_style(bg_color: Color, border_color: Color = PANEL_BORDER) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(2)
	style.content_margin_left = 12
	style.content_margin_top = 8
	style.content_margin_right = 12
	style.content_margin_bottom = 8
	return style


func _panel_style(bg_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = PANEL_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(2)
	return style
