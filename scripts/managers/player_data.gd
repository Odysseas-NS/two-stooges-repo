extends Node

signal coins_changed(new_total: int)
signal upgrades_changed

const SAVE_PATH := "user://player_data.json"

const UPGRADE_IDS: Array[String] = ["damage", "xp", "speed", "hp"]

const UPGRADE_DEFS := {
	"damage": {
		"name": "Damage",
		"description": "Flat bonus to melee and projectile damage",
		"bonuses": [5, 10, 15],
		"costs": [2, 4, 8],
	},
	"xp": {
		"name": "XP Gain",
		"description": "Bonus XP from each gem pickup",
		"bonuses": [5, 10, 15],
		"costs": [2, 4, 8],
	},
	"speed": {
		"name": "Speed",
		"description": "Flat bonus to movement speed",
		"bonuses": [5, 10, 15],
		"costs": [2, 4, 8],
	},
	"hp": {
		"name": "Health",
		"description": "Flat bonus to maximum health",
		"bonuses": [5, 10, 15],
		"costs": [2, 4, 8],
	},
}

var coins: int = 0
var upgrade_levels: Dictionary = {
	"damage": 0,
	"xp": 0,
	"speed": 0,
	"hp": 0,
}


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


func get_upgrade_level(upgrade_id: String) -> int:
	return int(upgrade_levels.get(upgrade_id, 0))


func get_upgrade_bonus(upgrade_id: String) -> int:
	var level := get_upgrade_level(upgrade_id)
	if level <= 0:
		return 0
	return int(UPGRADE_DEFS[upgrade_id]["bonuses"][level - 1])


func get_next_upgrade_cost(upgrade_id: String) -> int:
	var level := get_upgrade_level(upgrade_id)
	var costs: Array = UPGRADE_DEFS[upgrade_id]["costs"]
	if level >= costs.size():
		return -1
	return int(costs[level])


func can_purchase_upgrade(upgrade_id: String) -> bool:
	var cost := get_next_upgrade_cost(upgrade_id)
	return cost >= 0 and coins >= cost


func purchase_upgrade(upgrade_id: String) -> bool:
	var cost := get_next_upgrade_cost(upgrade_id)
	if cost < 0 or not spend_coins(cost):
		return false
	upgrade_levels[upgrade_id] = get_upgrade_level(upgrade_id) + 1
	upgrades_changed.emit()
	save_data()
	return true


func refund_all_upgrades() -> void:
	var refund := 0
	for upgrade_id in UPGRADE_IDS:
		var level := get_upgrade_level(upgrade_id)
		var costs: Array = UPGRADE_DEFS[upgrade_id]["costs"]
		for i in range(level):
			refund += int(costs[i])
		upgrade_levels[upgrade_id] = 0

	if refund > 0:
		coins += refund
		coins_changed.emit(coins)
	upgrades_changed.emit()
	save_data()


func apply_to_player(player: Node) -> void:
	if player == null:
		return

	var damage_bonus := get_upgrade_bonus("damage")
	if "attack_damage" in player:
		player.attack_damage += damage_bonus
	if "projectile_damage" in player:
		player.projectile_damage += damage_bonus
	if "speed" in player:
		player.speed += float(get_upgrade_bonus("speed"))

	var hp_bonus := get_upgrade_bonus("hp")
	if "max_health" in player:
		player.max_health += hp_bonus
	if "health" in player:
		player.health = player.max_health

	if "xp_gain_bonus" in player:
		player.xp_gain_bonus = get_upgrade_bonus("xp")


func save_data() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("PlayerData: failed to save to %s" % SAVE_PATH)
		return
	file.store_string(JSON.stringify({
		"coins": coins,
		"upgrade_levels": upgrade_levels,
	}))
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
	if not data is Dictionary:
		return

	if data.has("coins"):
		coins = int(data["coins"])
		coins_changed.emit(coins)

	if data.has("upgrade_levels") and data["upgrade_levels"] is Dictionary:
		for upgrade_id in UPGRADE_IDS:
			upgrade_levels[upgrade_id] = int(data["upgrade_levels"].get(upgrade_id, 0))
		upgrades_changed.emit()
