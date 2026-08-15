extends Node

# Upgrade data structure
class Upgrade:
	var id: String
	var name: String
	var description: String
	var icon: String = ""  # For future use
	var apply_func: Callable
	
	func _init(p_id: String, p_name: String, p_description: String, p_apply_func: Callable):
		id = p_id
		name = p_name
		description = p_description
		apply_func = p_apply_func

# Available upgrades registry
var available_upgrades: Array[Upgrade] = []

func _ready():
	register_upgrades()

func register_upgrades():
	# Damage upgrades
	available_upgrades.append(Upgrade.new(
		"damage_boost",
		"Damage Boost",
		"Increase projectile damage by 1",
		func(player): player.projectile_damage += 1
	))
	
	available_upgrades.append(Upgrade.new(
		"damage_boost_2",
		"Power Strike",
		"Increase projectile damage by 2",
		func(player): player.projectile_damage += 2
	))
	
	# Fire rate upgrades
	available_upgrades.append(Upgrade.new(
		"fire_rate",
		"Rapid Fire",
		"Reduce fire rate by 0.1 seconds",
		func(player): player.fire_rate = max(0.1, player.fire_rate - 0.1)
	))
	
	available_upgrades.append(Upgrade.new(
		"fire_rate_2",
		"Machine Gun",
		"Reduce fire rate by 0.2 seconds",
		func(player): player.fire_rate = max(0.1, player.fire_rate - 0.2)
	))
	
	# Speed upgrades
	available_upgrades.append(Upgrade.new(
		"speed_boost",
		"Swift Feet",
		"Increase movement speed by 50",
		func(player): player.speed += 50.0
	))
	
	available_upgrades.append(Upgrade.new(
		"speed_boost_2",
		"Lightning Dash",
		"Increase movement speed by 100",
		func(player): player.speed += 100.0
	))
	
	# Health upgrades
	available_upgrades.append(Upgrade.new(
		"max_health",
		"Vitality",
		"Increase max health by 5",
		func(player): 
			player.max_health += 5
			player.health += 5
	))
	
	available_upgrades.append(Upgrade.new(
		"max_health_2",
		"Fortress",
		"Increase max health by 10",
		func(player): 
			player.max_health += 10
			player.health += 10
	))
	
	# Axe upgrades
	available_upgrades.append(Upgrade.new(
		"axe_speed",
		"Swift Axe",
		"Increase axe throw speed by 200",
		func(player): player.axe_speed_boost += 200.0
	))
	
	# Weapon unlocks (these have priority in upgrade selection)
	available_upgrades.append(Upgrade.new(
		"unlock_rotating_blade",
		"Rotating Blade",
		"A blade that continuously orbits around you, damaging nearby enemies",
		func(player): 
			if player.weapon_manager != null:
				player.weapon_manager.unlock_rotating_blade()
	))
	
	available_upgrades.append(Upgrade.new(
		"unlock_aoe_burst",
		"AoE Burst",
		"Periodic explosion that damages all enemies within range",
		func(player): 
			if player.weapon_manager != null:
				player.weapon_manager.unlock_aoe_burst()
	))
	
	available_upgrades.append(Upgrade.new(
		"unlock_magic_missile",
		"Magic Missile",
		"Periodic homing bolt that targets the closest enemy and deals high damage.",
		func(player): 
			if player.weapon_manager != null:
				player.weapon_manager.unlock_magic_missile()
	))

func get_random_upgrades(count: int = 3, player: Node = null) -> Array[Upgrade]:
	var weapon_upgrades: Array[Upgrade] = []
	var regular_upgrades: Array[Upgrade] = []
	
	for upgrade in available_upgrades:
		if upgrade.id.begins_with("unlock_"):
			var weapon_id = upgrade.id.replace("unlock_", "")
			if player != null and player.has_method("has_weapon"):
				if not player.has_weapon(weapon_id):
					if _can_unlock_more_weapons(player):
						weapon_upgrades.append(upgrade)
			else:
				push_warning(
					"UpgradeManager: player not provided; weapon unlock '%s' cannot be filtered"
					% weapon_id
				)
				weapon_upgrades.append(upgrade)
		else:
			regular_upgrades.append(upgrade)
	
	var result: Array[Upgrade] = []
	
	weapon_upgrades.shuffle()
	for weapon_upgrade in weapon_upgrades:
		if result.size() >= count:
			break
		result.append(weapon_upgrade)
	
	if result.size() < count:
		regular_upgrades.shuffle()
		for upgrade in regular_upgrades:
			if result.size() >= count:
				break
			result.append(upgrade)
	
	return result

func _can_unlock_more_weapons(player: Node) -> bool:
	if player.weapon_manager == null:
		return true
	return player.weapon_manager.weapons.size() < player.weapon_manager.MAX_WEAPONS

func apply_upgrade(upgrade: Upgrade, player: Node):
	if upgrade.apply_func.is_valid():
		upgrade.apply_func.call(player)
		print("✅ Applied upgrade: ", upgrade.name)
