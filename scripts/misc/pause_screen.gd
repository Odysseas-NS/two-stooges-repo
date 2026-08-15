extends CanvasLayer

const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"

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

var _upgrade_screen: CanvasLayer = null
var _game_over: CanvasLayer = null


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_style_button(%ResumeButton, BUTTON_BG)
	_style_button(%QuitButton, QUIT_BG, QUIT_BORDER)


func setup(upgrade_screen: CanvasLayer, game_over: CanvasLayer) -> void:
	_upgrade_screen = upgrade_screen
	_game_over = game_over


func _unhandled_input(event: InputEvent) -> void:
	if not _is_pause_key(event):
		return

	if visible:
		hide_pause()
		get_viewport().set_input_as_handled()
		return

	if _can_open_pause():
		show_pause()
		get_viewport().set_input_as_handled()


func show_pause() -> void:
	visible = true
	get_tree().paused = true


func hide_pause() -> void:
	visible = false
	get_tree().paused = false


func is_open() -> bool:
	return visible


func _can_open_pause() -> bool:
	if _upgrade_screen != null and _upgrade_screen.visible:
		return false
	if _game_over != null and _game_over.visible:
		return false
	return true


func _is_pause_key(event: InputEvent) -> bool:
	if event.is_action_pressed("ui_cancel"):
		return true
	if event is InputEventKey:
		var key_event := event as InputEventKey
		return key_event.pressed and not key_event.echo and key_event.keycode == KEY_ESCAPE
	return false


func _on_resume_button_pressed() -> void:
	hide_pause()


func _on_quit_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _style_button(button: Button, bg_color: Color, border_color: Color = PANEL_BORDER) -> void:
	var hover_color := QUIT_HOVER if bg_color != BUTTON_BG else BUTTON_HOVER
	var pressed_color := QUIT_PRESSED if bg_color != BUTTON_BG else BUTTON_PRESSED
	button.process_mode = Node.PROCESS_MODE_ALWAYS
	button.add_theme_stylebox_override("normal", _button_style(bg_color, border_color))
	button.add_theme_stylebox_override("hover", _button_style(hover_color, border_color))
	button.add_theme_stylebox_override("pressed", _button_style(pressed_color, border_color))
	button.add_theme_color_override("font_color", TEXT_PRIMARY)
	button.add_theme_font_size_override("font_size", 24)


func _button_style(bg_color: Color, border_color: Color = PANEL_BORDER) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(2)
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style
