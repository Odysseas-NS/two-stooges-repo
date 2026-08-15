extends Node2D

signal weapons_changed

const MAX_WEAPONS := 6

const WEAPON_ICONS := {
	"projectile": "res://assets/weapons/axe.png",
	"rotating_blade": "res://assets/weapons/blade.png",
	"aoe_burst": "res://assets/weapons/aura.png",
	"missile": "res://assets/weapons/missile.png",
}

var weapons: Array[Weapon] = []
var player: Node2D

@export var rotating_blade_scene: PackedScene = preload("res://scenes/weapons/rotating_blade.tscn")
@export var aoe_burst_scene: PackedScene = preload("res://scenes/weapons/aoe_burst.tscn")
@export var missile_scene: PackedScene = preload("res://scenes/weapons/missile.tscn")


# Weapon data structure
class Weapon:
	var id: String
	var name: String
	var fire_method: String  # Method name to call on player
	var cooldown: float
	var timer: float = 0.0
	var enabled: bool = false
	var weapon_node: Node2D = null  # For persistent weapons like rotating blade
	
	func _init(p_id: String, p_name: String, p_fire_method: String, p_cooldown: float):
		id = p_id
		name = p_name
		fire_method = p_fire_method
		cooldown = p_cooldown
	
	func update(delta: float, player: Node2D):
		if not enabled:
			return
		
		# For persistent weapons (rotating blade, AoE), they handle their own updates
		if weapon_node != null:
			return
		
		# For fire-once weapons (projectiles)
		timer -= delta
		if timer <= 0:
			if player != null and player.has_method(fire_method):
				player.call(fire_method)
			timer = cooldown


func _ready():
	player = get_parent()

func _process(delta):
	for weapon in weapons:
		weapon.update(delta, player)

func add_weapon(weapon: Weapon) -> bool:
	if get_weapon(weapon.id) != null:
		return false
	if weapons.size() >= MAX_WEAPONS:
		push_warning("Cannot add weapon %s: max weapons (%d) reached" % [weapon.name, MAX_WEAPONS])
		return false

	weapons.append(weapon)
	weapon.enabled = true
	print("✅ Weapon unlocked: ", weapon.name)
	weapons_changed.emit()
	return true


func get_weapon_icon(weapon_id: String) -> String:
	return WEAPON_ICONS.get(weapon_id, "")

func unlock_rotating_blade():
	if get_weapon("rotating_blade") != null:
		return  # Already unlocked
	
	var blade_instance = rotating_blade_scene.instantiate()
	add_child(blade_instance)
	
	var weapon = Weapon.new(
		"rotating_blade",
		"Rotating Blade",
		"",  # No fire method, it's always active
		0.0
	)
	weapon.weapon_node = blade_instance
	add_weapon(weapon)

func unlock_aoe_burst():
	if get_weapon("aoe_burst") != null:
		return  # Already unlocked
	
	var aoe_instance = aoe_burst_scene.instantiate()
	add_child(aoe_instance)
	
	var weapon = Weapon.new(
		"aoe_burst",
		"AoE Burst",
		"",  # No fire method, it handles itself
		0.0
	)
	weapon.weapon_node = aoe_instance
	add_weapon(weapon)
	
func unlock_missile():
	if get_weapon("missile") != null:
		return  # Already unlocked
	
	var weapon = Weapon.new(
		"missile",
		"Magic Missile",
		"fire_missile_weapon",
		1.5
	)
	add_weapon(weapon)

func enable_weapon(weapon_id: String):
	for weapon in weapons:
		if weapon.id == weapon_id:
			weapon.enabled = true
			if weapon.weapon_node != null:
				weapon.weapon_node.visible = true
			print("✅ Weapon enabled: ", weapon.name)

func get_weapon(weapon_id: String) -> Weapon:
	for weapon in weapons:
		if weapon.id == weapon_id:
			return weapon
	return null

func has_weapon(weapon_id: String) -> bool:
	return get_weapon(weapon_id) != null
