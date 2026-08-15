extends CanvasLayer

signal upgrade_selected(upgrade)

const PANEL_BG := Color(0.12, 0.08, 0.22, 0.96)
const PANEL_BORDER := Color(0.78, 0.64, 0.24)
const CARD_BG := Color(0.32, 0.32, 0.36)
const CARD_BORDER := Color(0.78, 0.64, 0.24)
const CARD_HOVER := Color(0.4, 0.38, 0.48)
const CARD_PRESSED := Color(0.26, 0.24, 0.34)
const ICON_BG := Color(0.18, 0.16, 0.28)
const TEXT_PRIMARY := Color(0.95, 0.95, 0.95)
const TEXT_MUTED := Color(0.78, 0.78, 0.82)
const NEW_BADGE := Color(1.0, 0.92, 0.25)

@onready var options_container: VBoxContainer = %OptionsContainer

var current_upgrades: Array = []


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS


func show_upgrades(upgrades: Array) -> void:
	current_upgrades = upgrades

	for child in options_container.get_children():
		child.queue_free()

	call_deferred("_create_upgrade_cards", upgrades)

	visible = true
	get_tree().paused = true


func _create_upgrade_cards(upgrades: Array) -> void:
	for i in range(upgrades.size()):
		options_container.add_child(_build_upgrade_card(upgrades[i], i))


func _build_upgrade_card(upgrade, index: int) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(520, 92)
	button.focus_mode = Control.FOCUS_NONE
	button.process_mode = Node.PROCESS_MODE_ALWAYS
	button.flat = false
	button.text = ""
	button.add_theme_stylebox_override("normal", _card_style(CARD_BG))
	button.add_theme_stylebox_override("hover", _card_style(CARD_HOVER))
	button.add_theme_stylebox_override("pressed", _card_style(CARD_PRESSED))
	button.pressed.connect(_on_upgrade_button_pressed.bind(index))

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	button.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	margin.add_child(row)

	row.add_child(_build_icon(upgrade))

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 4)
	row.add_child(content)

	var header := HBoxContainer.new()
	content.add_child(header)

	var name_label := Label.new()
	name_label.text = upgrade.name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_color_override("font_color", TEXT_PRIMARY)
	name_label.add_theme_font_size_override("font_size", 22)
	header.add_child(name_label)

	var badge := Label.new()
	badge.text = "New!" if upgrade.id.begins_with("unlock_") else ""
	badge.add_theme_color_override("font_color", NEW_BADGE)
	badge.add_theme_font_size_override("font_size", 18)
	header.add_child(badge)

	var description := Label.new()
	description.text = upgrade.description
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_color_override("font_color", TEXT_MUTED)
	description.add_theme_font_size_override("font_size", 16)
	content.add_child(description)

	return button


func _build_icon(upgrade) -> PanelContainer:
	var icon_panel := PanelContainer.new()
	icon_panel.custom_minimum_size = Vector2(56, 56)
	icon_panel.add_theme_stylebox_override("panel", _icon_style(_icon_color_for_upgrade(upgrade)))

	var icon_label := Label.new()
	icon_label.text = _icon_text_for_upgrade(upgrade)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon_label.add_theme_color_override("font_color", TEXT_PRIMARY)
	icon_label.add_theme_font_size_override("font_size", 24)
	icon_panel.add_child(icon_label)

	return icon_panel


func _icon_text_for_upgrade(upgrade) -> String:
	if upgrade.id.begins_with("unlock_"):
		return "★"
	if upgrade.id.contains("damage"):
		return "⚔"
	if upgrade.id.contains("fire_rate"):
		return "⚡"
	if upgrade.id.contains("speed"):
		return "»"
	if upgrade.id.contains("health"):
		return "♥"
	if upgrade.id.contains("projectile"):
		return "•"
	return upgrade.name.substr(0, 1)


func _icon_color_for_upgrade(upgrade) -> Color:
	if upgrade.id.begins_with("unlock_"):
		return Color(0.55, 0.42, 0.12)
	if upgrade.id.contains("damage"):
		return Color(0.55, 0.18, 0.18)
	if upgrade.id.contains("fire_rate"):
		return Color(0.55, 0.4, 0.12)
	if upgrade.id.contains("speed"):
		return Color(0.18, 0.45, 0.22)
	if upgrade.id.contains("health"):
		return Color(0.52, 0.18, 0.32)
	if upgrade.id.contains("projectile"):
		return Color(0.18, 0.32, 0.55)
	return ICON_BG


func _card_style(bg_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = CARD_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(2)
	style.content_margin_left = 4
	style.content_margin_top = 4
	style.content_margin_right = 4
	style.content_margin_bottom = 4
	return style


func _icon_style(bg_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = PANEL_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(2)
	return style


func _on_upgrade_button_pressed(index: int) -> void:
	if index >= current_upgrades.size():
		push_error("Invalid upgrade index: %d" % index)
		return

	upgrade_selected.emit(current_upgrades[index])
	hide_upgrades()


func hide_upgrades() -> void:
	visible = false
	get_tree().paused = false
