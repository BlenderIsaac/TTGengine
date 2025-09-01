extends Node
class_name Weapon

var C : Character

var online := false
var triggering := false

var effects := {} # mesh, trail, muzzle flash?

func trigger(target = null):
	for effect in effects.values():
		effect.trigger(target)

func _process(_delta):
	for effect in effects.values():
		effect.triggering = triggering and online

func adapt_anim(anim_name):
	return name + anim_name

class LoadDetails:
	var effects := {}
	
	func gen():
		var weapon := Weapon.new()
		
		for key : String in effects.keys():
			var fx : WeaponEffect = effects[key].gen()
			weapon.effects[key] = fx
			fx.weapon = weapon
			
			fx.set_external_skeleton(NodePath("../../../Mesh/Armature/Skeleton3D"))
			fx.set_use_external_skeleton(true)
			
			weapon.add_child(fx)
		
		return weapon
