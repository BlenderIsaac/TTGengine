extends "res://Logic/LOGIC.gd"

var force_target = null
var needs_rig = true

var push_range = 8.0

var push_strength = 200.0

var valid_rigs = ["GenRig.glb"]

var target_anims = {
	"Required" : 
		[
			{
				"Name" : "Pushed",
				"Path" : "ForcePushed.res"
			},
			{
				"Name" : "PushedFall",
				"Path" : "PushedFallloop.res"
			},
		],
	"Other" : 
		[]
}

func exclusive_physics(_delta):
	var ForceSensitive = C.get_logic("ForceSensitive")
	if ForceSensitive.generic_check_force_validity(force_target):
		
		ForceSensitive.generic_force_stuff(force_target, _delta)
		
		var TargetLogic = "ForcePushed"
		
		force_target.get_logic(TargetLogic).push_strength = push_strength
		force_target.get_logic(TargetLogic).og_opponent_position = C.global_position
		force_target.set_movement_state(TargetLogic)
		
		if force_target.global_position.distance_to(C.global_position) >= push_range:
			C.reset_movement_state()
	else:
		C.reset_movement_state()

func target_viable(target):
	if target.global_position.distance_to(C.global_position) < push_range-1:
		return true
	return false

func exclusive_damage(_amount, _who_from=null):
	C.get_logic("ForceSensitive").force_target = null
	C.get_logic("ForceSensitive").force_delay = 0.0
	
	C.reset_movement_state()
	C.generic_damage(_amount)

func initiate():
	anim.play("ForceUse", .1)
