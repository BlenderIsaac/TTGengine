extends Node
class_name Weapon

var online := false
var triggering := false

var visual_effects := [] # mesh, trail, muzzle flash?
var damage_effects := [] # projectile, hitbox

func trigger():
	for effect in damage_effects:
		effect.trigger()

func _process(delta):
	for effect in damage_effects:
		effect.triggering = triggering and online


class LoadDetails:
	var visual_effects := []
	var damage_effects := []
	
	func gen():
		var weapon = Weapon.new()
		
		weapon.visual_effects = visual_effects
		weapon.damage_effects = damage_effects
