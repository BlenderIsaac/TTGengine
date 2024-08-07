extends "res://Logic/LOGIC.gd"

var opponent = null
var push_speed = 20.0

var choke_height = 1.5

var damage_delay = 1.0

var current_delay = 0.0

func can_switch():return false

func initiate():
	current_delay = 0.0

func exclusive_physics(_delta):
	if opponent and !opponent.dead and is_instance_valid(opponent):
		
		if current_delay >= damage_delay:
			current_delay = 0.0
			
			C.take_damage(1)
		
		base_state.freeze()
		
		var pos_to = opponent.global_position.y+choke_height
		var up_vel_y = (pos_to-C.global_position.y)*5
		var up_vel = Vector3(0, up_vel_y, 0)
		
		C.set_velocity(up_vel+C.knock_vel+C.push_vel)
		C.move_and_slide()
		
		# face toward player
		var rot_to_force = Basis.looking_at(C.global_position-opponent.global_position).get_euler().y+PI
		C.mesh_angle_to = rot_to_force
		
		C.mesh_angle_lerp(_delta, 0.3)
		
		# play anim
		C.weapon_prefix = ""
		anim.play("Choked", 0.1)
		
		if !opponent.movement_state == "ForceChoke":
			opponent = null
		else:
			# if they are pushing
			if !opponent.get_node("Logic/ForceChoke").force_target == C:
				opponent = null
		
		current_delay += _delta
	else:
		opponent = null
		C.reset_movement_state()
