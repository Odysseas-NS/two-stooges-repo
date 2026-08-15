extends Control

const GAME_SCENE := "res://scenes/main/main.tscn"

const PANEL_BG := Color(0.12, 0.08, 0.22, 0.96)
const PANEL_BORDER := Color(0.78, 0.64, 0.24)
const BUTTON_BG := Color(0.32, 0.32, 0.36)
const BUTTON_HOVER := Color(0.4, 0.38, 0.48)
const BUTTON_PRESSED := Color(0.26, 0.24, 0.34)
const TEXT_PRIMARY := Color(0.95, 0.95, 0.95)
const TEXT_MUTED := Color(0.78, 0.78, 0.82)

@onready var placeholder_popup: PanelContainer = %PlaceholderPopup
@onready var placeholder_label: Label = %PlaceholderLabel


func _ready() -> void:
	_style_menu_buttons()
	placeholder_popup.visible = false


func _style_menu_buttons() -> void:
	for button in [%PlayButton, %OptionsButton, %UpgradesButton, %ClosePlaceholderButton]:
		button.add_theme_stylebox_override("normal", _button_style(BUTTON_BG))
		button.add_theme_stylebox_override("hover", _button_style(BUTTON_HOVER))
		button.add_theme_stylebox_override("pressed", _button_style(BUTTON_PRESSED))
		button.add_theme_color_override("font_color", TEXT_PRIMARY)
		button.add_theme_font_size_override("font_size", 24)


func _button_style(bg_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = PANEL_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(2)
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_options_button_pressed() -> void:
	_show_placeholder("Options coming soon!")


func _on_upgrades_button_pressed() -> void:
	_show_placeholder("Permanent upgrades coming soon!")


func _on_close_placeholder_button_pressed() -> void:
	placeholder_popup.visible = false


func _show_placeholder(message: String) -> void:
	placeholder_label.text = message
	placeholder_popup.visible = true
