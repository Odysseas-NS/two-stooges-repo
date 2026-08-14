extends CanvasLayer

signal upgrade_selected(upgrade)

@onready var upgrade_container := $UpgradePanel/VBoxContainer

var current_upgrades: Array = []

func _ready():
	visible = false
	# Ensure this layer processes even when tree is paused
	process_mode = Node.PROCESS_MODE_ALWAYS

func show_upgrades(upgrades: Array):
	print("📺 show_upgrades() called with ", upgrades.size(), " upgrades")
	current_upgrades = upgrades
	
	# Clear previous buttons first
	for child in upgrade_container.get_children():
		if child.name != "Title":  # Keep the title label
			child.queue_free()
	
	# Defer button creation to ensure container is ready
	call_deferred("_create_upgrade_buttons", upgrades)
	
	visible = true
	get_tree().paused = true
	print("📺 Upgrade screen visible: ", visible, " Paused: ", get_tree().paused)

func _create_upgrade_buttons(upgrades: Array):
	# Create buttons for each upgrade
	for i in range(upgrades.size()):
		var upgrade = upgrades[i]
		var button = Button.new()
		button.text = upgrade.name + "\n" + upgrade.description
		button.custom_minimum_size = Vector2(300, 80)
		# Ensure button processes input even when tree is paused
		button.process_mode = Node.PROCESS_MODE_ALWAYS
		button.pressed.connect(_on_upgrade_button_pressed.bind(i))
		upgrade_container.add_child(button)
		print("  Created button for: ", upgrade.name)

func _on_upgrade_button_pressed(index: int):
	print("🔘 Button pressed! Index: ", index)
	print("  current_upgrades.size(): ", current_upgrades.size())
	
	if index >= current_upgrades.size():
		push_error("❌ Invalid upgrade index: ", index)
		return
	
	var selected_upgrade = current_upgrades[index]
	print("  Selected upgrade: ", selected_upgrade.name)
	print("  Emitting upgrade_selected signal...")
	
	upgrade_selected.emit(selected_upgrade)
	print("  Signal emitted")
	hide_upgrades()

func hide_upgrades():
	visible = false
	get_tree().paused = false
