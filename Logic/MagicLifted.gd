extends "res://Logic/LOGIC.gd"

var lift_release_time = 6.0
var lift_release_time_player = 1.0

var lift_release_delay = 0.0

var lift_height = 1.5

var initial_position = 0.0

func can_switch():return false

func initiate():
	if C.player and !C.AI:
		lift_release_delay = lift_release_time_player
	else:
		lift_release_delay = lift_release_time
	anim.play("MagicLifted", 0.2)
	
	
	initial_position = C.position


func exclusive_physics(_delta):
	
	base_state.freeze()
	
	var root_vel = C.get_root_vel(0.01, 0.99)/_delta
	
	var pos_to = initial_position.y+lift_height
	var up_vely = (pos_to-C.position.y)*5
	var vel_x = (initial_position.x-C.position.x)*10
	var vel_z = (initial_position.z-C.position.z)*10
	var up_vel = Vector3(vel_x, up_vely, vel_z)+Vector3(0, 1, 0)
	
	C.set_velocity(up_vel+C.knock_vel+C.push_vel+root_vel)
	C.move_and_slide()
	
	C.mesh_angle_lerp(_delta, 0.3)
	
	# play anim
	C.weapon_prefix = ""
	
	if lift_release_delay <= 0:
		anim.play("Fallloop", 0.1)
		C.reset_movement_state()
	
	lift_release_delay -= _delta
