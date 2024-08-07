extends "res://Logic/LOGIC.gd"

var opponent = null
var push_speed = 20.0

var freeze_length = 6.0
var current_length = 0.0

var anim_nm = "BASE"
var anim_ps = 0.0

func can_switch():return false

func exclusive_damage(value, _who_from=null):
	anim.play(C.weapon_prefix+"Idleloop", 0.2)
	C.reset_movement_state()
	C.generic_damage(value)

func initiate():
	C.weapon_prefix = ""
	current_length = 0.0
	base_state.freeze()
	
	anim_nm = anim.current_animation
	anim_ps = anim.current_animation_position

func exclusive_physics(_delta):
	if opponent and !opponent.dead and is_instance_valid(opponent):
		
#		if not C.is_on_floor():
#			C.char_vel.y += base_state.air_gravity*_delta*C.var_scale
#		else:
#			C.char_vel.y = base_state.air_gravity*_delta*C.var_scale
#
#		C.set_velocity(C.char_vel+C.knock_vel+C.push_vel)
#		C.move_and_slide()
#
#		C.mesh_angle_lerp()
		
		if current_length > freeze_length:
			opponent = null
		
		current_length += _delta
		
		anim.play(anim_nm)
		anim.seek(anim_ps)
		
	else:
		opponent = null
		anim.play("Idleloop", .3)
		C.reset_movement_state()
