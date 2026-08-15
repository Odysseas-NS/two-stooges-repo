extends CanvasLayer

const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"

const BUTTON_BG := Color(0.32, 0.32, 0.36)
const BUTTON_HOVER := Color(0.4, 0.38, 0.48)
const BUTTON_PRESSED := Color(0.26, 0.24, 0.34)
const REVIVE_BG := Color(0.18, 0.45, 0.22)
const REVIVE_HOVER := Color(0.22, 0.55, 0.28)
const REVIVE_PRESSED := Color(0.14, 0.35, 0.18)
const QUIT_BG := Color(0.55, 0.15, 0.15)
const QUIT_HOVER := Color(0.68, 0.2, 0.2)
const QUIT_PRESSED := Color(0.4, 0.1, 0.1)
const PANEL_BORDER := Color(0.78, 0.64, 0.24)
const TEXT_PRIMARY := Color(0.95, 0.95, 0.95)

var _player: CharacterBody2D


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_style_button(%ReviveButton, REVIVE_BG, REVIVE_BG.lightened(0.15))
	_style_button(%QuitButton, QUIT_BG, Color(0.85, 0.3, 0.3))


func setup(player: CharacterBody2D) -> void:
	_player = player


func show_game_over(can_revive: bool) -> void:
	%ReviveButton.visible = can_revive
	visible = true
	get_tree().paused = true


func hide_game_over() -> void:
	visible = false
	get_tree().paused = false


func _on_revive_button_pressed() -> void:
	if _player == null or _player.revives_remaining <= 0:
		return

	_player.revives_remaining -= 1
	_player.revive()
	hide_game_over()


func _on_quit_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _style_button(button: Button, bg_color: Color, border_color: Color) -> void:
	button.process_mode = Node.PROCESS_MODE_ALWAYS
	button.add_theme_stylebox_override("normal", _button_style(bg_color, border_color))
	button.add_theme_stylebox_override("hover", _button_style(bg_color.lightened(0.08), border_color))
	button.add_theme_stylebox_override(
		"pressed",
		_button_style(bg_color.darkened(0.08), border_color)
	)
	button.add_theme_color_override("font_color", TEXT_PRIMARY)
	button.add_theme_font_size_override("font_size", 28)


func _button_style(bg_color: Color, border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(2)
	style.content_margin_left = 18
	style.content_margin_top = 10
	style.content_margin_right = 18
	style.content_margin_bottom = 10
	return style
