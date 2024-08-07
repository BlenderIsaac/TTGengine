extends "res://Logic/LOGIC.gd"

var force_target = null
var needs_rig = true

var pull_range = 16.0
var close_range = 1.5

var valid_rigs = ["GenRig.tscn", "ShortRig.tscn"]

var target_anims = {
	"Required" : 
		[
			{
				"Name" : "Pulled", 
				"Path" : "Pulled.res"
			}
		],
	"Other" : 
		[
			{
				"Name" : "SwordPulled", 
				"Path" : "GunPulled.res"
			}
		]
}

func exclusive_physics(_delta):
	if force_target and is_instance_valid(force_target):
		var ForceSensitive = C.get_logic("ForceSensitive")
		ForceSensitive.generic_force_stuff(force_target, _delta)
		
		var TargetLogic = "ForcePulled"
		if !force_target.movement_state == TargetLogic:
			force_target.get_logic(TargetLogic).opponent = C
			force_target.set_movement_state(TargetLogic)
		
		if force_target.global_position.distance_to(C.global_position) >= pull_range or force_target.global_position.distance_to(C.global_position) <= close_range:
			C.reset_movement_state()
	else:
		C.reset_movement_state()

func target_viable(target):
	if target.global_position.distance_to(C.global_position) < pull_range and target.global_position.distance_to(C.global_position) > close_range:
		return true
	
	return false

func exclusive_damage(_amount, _who_from=null):
	C.get_logic("ForceSensitive").force_target = null
	C.get_logic("ForceSensitive").force_delay = 0.0
	
	C.reset_movement_state()
	C.generic_damage(_amount)

func initiate():
	anim.play("ForceUse", .1)

