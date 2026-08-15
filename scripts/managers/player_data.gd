extends Node

signal coins_changed(new_total: int)
signal upgrades_changed

const SAVE_PATH := "user://player_data.json"

const UPGRADE_IDS: Array[String] = [
	"damage",
	"xp",
	"speed",
	"hp",
	"gold",
	"cooldown",
	"difficulty",
	"pickup_range",
	"armor",
	"regen",
	"projectile_count",
	"revive",
]

const UPGRADE_DEFS := {
	"damage": {
		"name": "Damage",
		"description": "Flat bonus to melee and projectile damage",
		"bonuses": [1, 2, 3, 4, 5],
		"costs": [3, 6, 10, 15, 22],
	},
	"xp": {
		"name": "XP Gain",
		"description": "Bonus XP from each gem pickup",
		"bonuses": [1, 2, 3, 4, 5],
		"costs": [3, 6, 10, 15, 22],
	},
	"speed": {
		"name": "Speed",
		"description": "Flat bonus to movement speed",
		"bonuses": [10, 20, 30, 40, 50],
		"costs": [3, 6, 10, 15, 22],
	},
	"hp": {
		"name": "Health",
		"description": "Flat bonus to maximum health",
		"bonuses": [2, 4, 6, 8, 10],
		"costs": [3, 6, 10, 15, 22],
	},
	"gold": {
		"name": "Gold Gain",
		"description": "Each coin pickup is worth more gold",
		"bonuses": [1, 2, 3, 4, 5],
		"costs": [4, 8, 12, 18, 26],
	},
	"cooldown": {
		"name": "Cooldown",
		"description": "Weapons fire and trigger faster",
		"bonuses": [5, 10, 15, 20, 25],
		"costs": [4, 8, 12, 18, 26],
	},
	"difficulty": {
		"name": "Difficulty",
		"description": "Enemies start tougher with more HP, damage, and spawn pressure",
		"bonuses": [0.15, 0.3, 0.45, 0.6, 0.75],
		"costs": [4, 8, 12, 18, 26],
	},
	"pickup_range": {
		"name": "Pickup Range",
		"description": "Pull XP gems and coins toward you from farther away",
		"bonuses": [24, 48, 72, 96, 120],
		"costs": [3, 6, 10, 15, 22],
	},
	"armor": {
		"name": "Armor",
		"description": "Reduce incoming damage",
		"bonuses": [1, 2, 3, 4, 5],
		"costs": [4, 8, 12, 18, 26],
	},
	"regen": {
		"name": "Regen",
		"description": "Slowly regenerate health over time",
		"bonuses": [0.25, 0.5, 0.75, 1.0, 1.25],
		"costs": [4, 8, 12, 18, 26],
	},
	"projectile_count": {
		"name": "Projectile Count",
		"description": "Fire more projectiles with projectile weapons",
		"bonuses": [2, 3, 4, 5, 6],
		"costs": [5, 10, 16, 24, 35],
	},
	"revive": {
		"name": "Revive",
		"description": "Revive once per run from the game over screen",
		"bonuses": [1],
		"costs": [40],
	},
}

var coins: int = 0
var upgrade_levels: Dictionary = {}


func _ready() -> void:
	_reset_upgrade_levels()
	load_data()


func _reset_upgrade_levels() -> void:
	upgrade_levels.clear()
	for upgrade_id in UPGRADE_IDS:
		upgrade_levels[upgrade_id] = 0


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


func get_max_upgrade_level(upgrade_id: String) -> int:
	return UPGRADE_DEFS[upgrade_id]["costs"].size()


func get_upgrade_bonus(upgrade_id: String) -> float:
	var level := get_upgrade_level(upgrade_id)
	if level <= 0:
		return 0.0
	return float(UPGRADE_DEFS[upgrade_id]["bonuses"][level - 1])


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


func format_upgrade_bonus(upgrade_id: String, bonus: float, _is_next: bool = false) -> String:
	match upgrade_id:
		"revive":
			return "Revive once per run" if bonus > 0.0 else "Not purchased"
		"cooldown":
			return "%d%% faster weapons" % int(bonus)
		"difficulty":
			return "+%.0f%% enemy scaling" % (bonus * 100.0)
		"pickup_range":
			return "+%d px pickup range" % int(bonus)
		"regen":
			return "+%.2f HP/sec" % bonus
		"projectile_count":
			return "%d projectiles per shot" % int(bonus)
		"gold":
			return "+%d gold per coin" % int(bonus)
		"armor":
			return "-%d damage taken" % int(bonus)
		"speed":
			return "+%d move speed" % int(bonus)
		"hp":
			return "+%d max HP" % int(bonus)
		"xp", "damage":
			return "+%d" % int(bonus)
		_:
			return "+%d" % int(bonus)


func apply_to_player(player: Node) -> void:
	if player == null:
		return

	var damage_bonus := int(get_upgrade_bonus("damage"))
	if "attack_damage" in player:
		player.attack_damage += damage_bonus
	if "projectile_damage" in player:
		player.projectile_damage += damage_bonus
	if "speed" in player:
		player.speed += get_upgrade_bonus("speed")

	var hp_bonus := int(get_upgrade_bonus("hp"))
	if "max_health" in player:
		player.max_health += hp_bonus
	if "health" in player:
		player.health = player.max_health

	if "xp_gain_bonus" in player:
		player.xp_gain_bonus = int(get_upgrade_bonus("xp"))
	if "gold_gain_bonus" in player:
		player.gold_gain_bonus = int(get_upgrade_bonus("gold"))
	if "cooldown_reduction" in player:
		player.cooldown_reduction = get_upgrade_bonus("cooldown") / 100.0
	if "difficulty_bonus" in player:
		player.difficulty_bonus = get_upgrade_bonus("difficulty")
	if "pickup_range" in player:
		player.pickup_range = get_upgrade_bonus("pickup_range")
	if "armor" in player:
		player.armor = int(get_upgrade_bonus("armor"))
	if "health_regen" in player:
		player.health_regen = get_upgrade_bonus("regen")
	if "projectile_count" in player:
		player.projectile_count = maxi(1, int(get_upgrade_bonus("projectile_count")))
	if "revives_remaining" in player:
		player.revives_remaining = 1 if get_upgrade_level("revive") > 0 else 0


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
