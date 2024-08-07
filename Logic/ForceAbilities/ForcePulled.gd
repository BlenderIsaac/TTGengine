extends "res://Logic/LOGIC.gd"

var opponent = null
var pull_speed = -20.0

func can_switch():return false

func exclusive_physics(_delta):
	if opponent and !opponent.dead and is_instance_valid(opponent):
		var diff = C.global_position-opponent.global_position
		
		var push_vel = diff.normalized()*pull_speed
		
		C.set_velocity(push_vel+C.knock_vel+C.push_vel)
		C.move_and_slide()
		
		# face toward player
		var rot_to_force = Basis.looking_at(C.global_position-opponent.global_position).get_euler().y+PI
		C.mesh_angle_to = rot_to_force
		
		C.mesh_angle_lerp(_delta, 0.3)
		
		# play anim
		if anim.has_animation(C.weapon_prefix+"Pulled"):
			anim.play(C.weapon_prefix+"Pulled", .2)
		else:
			C.weapon_prefix = ""
			anim.play("Pulled", .2)
		
		if !opponent.movement_state == "ForcePull":
			opponent = null
		else:
			# if they are pushing
			if !opponent.get_node("Logic/ForcePull").force_target == C:
				opponent = null
	else:
		opponent = null
		anim.play(C.weapon_prefix+"Idleloop", .2)
		C.reset_movement_state()
