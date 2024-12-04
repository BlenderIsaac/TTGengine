extends "res://Logic/LOGIC.gd"

var push_speed = 20.0

var push_strength = 200.0
var push_left = 200.0

var og_opponent_position = Vector3()

var landed = false

func can_switch():return false

func initiate():
	push_left = push_strength
	landed = false
	anim_play("PushedFall")

func anim_play(anim_name):
	if anim.has_animation(C.weapon_prefix+anim_name):
		anim.play(C.weapon_prefix+anim_name, .2)
	else:
		C.weapon_prefix = ""
		anim.play(anim_name, .2)


func exclusive_physics(_delta):
	#Engine.time_scale = 0.3
	
	if not C.is_on_floor():
		C.char_vel.y += base_state.air_gravity*_delta*C.var_scale
	else:
		C.char_vel.y = base_state.air_gravity*_delta*C.var_scale
	
	if not landed:
		push_left -= f.to_vec2(C.velocity).length()
		
		var diff = C.global_position-og_opponent_position
		
		var push_vel = diff.normalized()*push_speed
		
		C.set_velocity(push_vel+C.knock_vel+C.push_vel+C.char_vel)
		C.move_and_slide()
		
		var rot_to_force = Basis.looking_at(C.global_position-og_opponent_position).get_euler().y+PI
		C.mesh_angle_to = rot_to_force
		C.mesh_angle_lerp(_delta, 0.3)
		
		anim_play("PushedFall")
		
		if C.is_on_wall():
			anim_play("Pushed")
			landed = true
		
		if push_left < 0.0:
			if C.is_on_floor():
				anim_play("Pushed")
				landed = true
	else:
		
		var root_vel = C.get_root_vel(0.0, 0.95)/_delta
		
		C.set_velocity(root_vel+C.knock_vel+C.push_vel+C.char_vel)
		C.move_and_slide()
		
		if anim.current_animation == "":
			anim.play(C.weapon_prefix+"Idleloop", .2)
			C.reset_movement_state()
