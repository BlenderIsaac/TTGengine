extends Node
class_name Weapon

var online := false
var triggering := false

var effects := {} # mesh, trail, muzzle flash?

func trigger():
	for effect in effects.values():
		effect.trigger()

func _process(delta):
	for effect in effects.values():
		effect.triggering = triggering and online


class LoadDetails:
	var effects := {}
	
	func gen():
		var weapon := Weapon.new()
		
		for key : String in effects.keys():
			var fx = effects[key].gen()
			weapon.effects[key] = fx
			fx.weapon = Weapon
			weapon.add_child(fx)
		
		return weapon
