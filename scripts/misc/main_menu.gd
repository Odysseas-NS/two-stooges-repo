extends Control

const GAME_SCENE := "res://scenes/main/main.tscn"
const UPGRADES_SCENE := "res://scenes/ui/permanent_upgrades.tscn"

const PANEL_BG := Color(0.12, 0.08, 0.22, 0.96)
const PANEL_BORDER := Color(0.78, 0.64, 0.24)
const BUTTON_BG := Color(0.32, 0.32, 0.36)
const BUTTON_HOVER := Color(0.4, 0.38, 0.48)
const BUTTON_PRESSED := Color(0.26, 0.24, 0.34)
const QUIT_BG := Color(0.55, 0.15, 0.15)
const QUIT_HOVER := Color(0.68, 0.2, 0.2)
const QUIT_PRESSED := Color(0.4, 0.1, 0.1)
const QUIT_BORDER := Color(0.85, 0.3, 0.3)
const TEXT_PRIMARY := Color(0.95, 0.95, 0.95)
const TEXT_MUTED := Color(0.78, 0.78, 0.82)

@onready var placeholder_popup: PanelContainer = %PlaceholderPopup
@onready var placeholder_label: Label = %PlaceholderLabel
@onready var coins_label: Label = %CoinsLabel


func _ready() -> void:
	_style_menu_buttons()
	_style_quit_button()
	placeholder_popup.visible = false
	coins_label.add_theme_color_override("font_color", Color(0.92, 0.78, 0.28))
	_update_coins_label(PlayerData.coins)
	if not PlayerData.coins_changed.is_connected(_update_coins_label):
		PlayerData.coins_changed.connect(_update_coins_label)


func _exit_tree() -> void:
	if PlayerData.coins_changed.is_connected(_update_coins_label):
		PlayerData.coins_changed.disconnect(_update_coins_label)


func _style_menu_buttons() -> void:
	for button in [%PlayButton, %OptionsButton, %UpgradesButton, %ClosePlaceholderButton]:
		button.add_theme_stylebox_override("normal", _button_style(BUTTON_BG))
		button.add_theme_stylebox_override("hover", _button_style(BUTTON_HOVER))
		button.add_theme_stylebox_override("pressed", _button_style(BUTTON_PRESSED))
		button.add_theme_color_override("font_color", TEXT_PRIMARY)
		button.add_theme_font_size_override("font_size", 24)


func _style_quit_button() -> void:
	%QuitButton.add_theme_stylebox_override("normal", _button_style(QUIT_BG, QUIT_BORDER))
	%QuitButton.add_theme_stylebox_override("hover", _button_style(QUIT_HOVER, QUIT_BORDER))
	%QuitButton.add_theme_stylebox_override("pressed", _button_style(QUIT_PRESSED, QUIT_BORDER))
	%QuitButton.add_theme_color_override("font_color", TEXT_PRIMARY)
	%QuitButton.add_theme_font_size_override("font_size", 24)


func _button_style(bg_color: Color, border_color: Color = PANEL_BORDER) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
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
	get_tree().change_scene_to_file(UPGRADES_SCENE)


func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_close_placeholder_button_pressed() -> void:
	placeholder_popup.visible = false


func _show_placeholder(message: String) -> void:
	placeholder_label.text = message
	placeholder_popup.visible = true


func _update_coins_label(total: int) -> void:
	coins_label.text = "Coins: %d" % total
