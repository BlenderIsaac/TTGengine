extends "res://Logic/LOGIC.gd"

var spawn_logic = "ThrowObject"
var our_jump_state = "Jetpack"
var jump_logic = "Jump"

var time_thrown = .44

func initiate():
	
	base_state.freeze()
	thrown = false
	anim.play(C.weapon_prefix+"FlyThrowObject", .2)

func inclusive_physics(_delta):
	
	if C.key_just_pressed("Special"):
		
		var throw_object = get_parent().get_node(spawn_logic)
		
		if !C.AI and C.movement_state == jump_logic and get_parent().get_node(jump_logic).current_jumping_logic == our_jump_state:
			
			# if we have thrown something or that thing we have thrown is valid
			if throw_object.last_thrown == null or !is_instance_valid(throw_object.last_thrown):
				C.set_movement_state("JetpackThrowObject")

var thrown = false
func exclusive_physics(_delta):
	
	# Reset movement
	if C.is_on_ceiling():
		C.char_vel.y = -1
	
	var root_vel = C.get_root_vel(.1, .9)
	
	C.set_velocity(C.char_vel+C.push_vel+C.knock_vel+root_vel)
	
	C.velocity.y = 0
	C.char_vel.y = 0
	
	C.move_and_slide()
	
	var vel = C.velocity
	vel.y = 0
	
	get_parent().get_node(our_jump_state).jetpack_left -= vel.length()
	
	if !anim.current_animation.ends_with("FlyThrowObject"):
		get_parent().get_node("Jump").current_jumping_logic = "Jetpack"
		C.set_movement_state("Jump")
	
	# handle creating the detonator/object
	var throw_object = get_parent().get_node(spawn_logic)
	var pos = anim.current_animation_position
	
	if pos >= time_thrown and thrown == false:
		throw_object.last_thrown = throw_object.throw_object()
		throw_object.thrown = true
		throw_object.special_held = true
		thrown = true
	
	#C.mesh_angle_lerp(0.2)

