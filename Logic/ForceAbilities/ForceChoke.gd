extends "res://Logic/LOGIC.gd"

var force_target = null
var needs_rig = true

var valid_rigs = ["GenRig.glb", "ShortRig.hlb"]

var target_anims = {
	"Required" : 
		[
			{
				"Name" : "Choked", 
				"Path" : "Choked.res"
			}
		],
	"Other" : 
		[
			{
				"Name" : "SwordChoked", 
				"Path" : "GunChoked.res"
			}
		]
}

func exclusive_physics(_delta):
	var ForceSensitive = C.get_logic("ForceSensitive")
	if ForceSensitive.generic_check_force_validity(force_target):
		
		ForceSensitive.generic_force_stuff(force_target, _delta)
		
		var TargetLogic = "ForceChoked"
		if !force_target.movement_state == TargetLogic:
			force_target.get_logic(TargetLogic).opponent = C
			force_target.set_movement_state(TargetLogic)
	else:
		
		force_target = null
		C.reset_movement_state()


func exclusive_damage(_amount, _who_from=null):
	C.get_logic("ForceSensitive").force_target = null
	C.get_logic("ForceSensitive").force_delay = 0.0
	
	C.reset_movement_state()
	C.generic_damage(_amount)


func initiate():
	anim.play("ForceUse", .1)
