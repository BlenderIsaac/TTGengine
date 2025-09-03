extends Node3D
class_name Weapon

var C : Character

var force_visibility = 0 :# -1 for forced invisibility, 1 for forced visibiliy
	set(value):
		force_visibility = value
		update_visibility()

signal set_visible(new_value : bool)
var active := false :
	set(value):
		active = value
		update_visibility()
var triggering := false

var effects := {} # mesh, trail, muzzle flash

func _ready():
	top_level = true

func update_visibility():
	match force_visibility:
		-1:
			emit_signal("set_visible", false)
		1:
			emit_signal("set_visible", true)
		0:
			emit_signal("set_visible", active)


func trigger(target = null):
	for effect in effects.values():
		effect.trigger(target)

func _process(_delta):
	for effect in effects.values():
		effect.triggering = triggering and active

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
