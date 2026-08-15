extends Node

signal coins_changed(new_total: int)

const SAVE_PATH := "user://player_data.json"

var coins: int = 0


func _ready() -> void:
	load_data()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_data()


func add_coins(amount: int) -> void:
	if amount <= 0:
		return
	coins += amount
	coins_changed.emit(coins)
	save_data()


func spend_coins(amount: int) -> bool:
	if amount <= 0 or coins < amount:
		return false
	coins -= amount
	coins_changed.emit(coins)
	save_data()
	return true


func save_data() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("PlayerData: failed to save to %s" % SAVE_PATH)
		return
	file.store_string(JSON.stringify({"coins": coins}))
	file.close()


func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("PlayerData: failed to load from %s" % SAVE_PATH)
		return

	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK:
		file.close()
		return
	file.close()

	var data = json.data
	if data is Dictionary and data.has("coins"):
		coins = int(data["coins"])
		coins_changed.emit(coins)
