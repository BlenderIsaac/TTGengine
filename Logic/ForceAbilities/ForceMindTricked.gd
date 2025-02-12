extends "res://Logic/LOGIC.gd"

var opponent = null
var push_speed = 20.0

var mind_trick_length = 3.0
var current_length = 0.0

func can_switch():return false

func initiate():
	C.weapon_prefix = ""
	current_length = 0.0
	base_state.freeze()

func exclusive_damage(damage:f.Damage):
	anim.play(C.weapon_prefix+"Idleloop", 0.2)
	C.reset_movement_state()
	C.generic_damage(damage.amount)

func exclusive_physics(_delta):
	if opponent and !opponent.dead and is_instance_valid(opponent):
		
		if not C.is_on_floor():
			C.char_vel.y += base_state.air_gravity*_delta*C.var_scale
		else:
			C.char_vel.y = base_state.air_gravity*_delta*C.var_scale
		
		C.set_velocity(C.char_vel+C.knock_vel+C.push_vel)
		C.move_and_slide()
		
		C.mesh_angle_lerp(_delta, 0.3)
		
		if current_length > mind_trick_length:
			opponent = null
		
		current_length += _delta
		
		# play anim
		anim.play("MindTricked")
		
	else:
		opponent = null
		anim.play("Idleloop", .3)
		C.reset_movement_state()
