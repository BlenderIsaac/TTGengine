extends "res://Logic/LOGIC.gd"

# number of jumps
@export var number_of_jumps = 2

@export var jumped = 0
@export var jump_speeds = [2.3, 2.3]
@export var jump_types = ["Jump", "Jump"]
@export var jump_attacks = ["SwordLunge", "SwordSlam"]
@export var jump_anims = ["Jump", "DoubleJump"]
@export var jump_sounds = ["Jump", "DoubleJump"]

@export var copy_run_speed = true
@export var copy_air_gravity = true

# gravity override
@export var override_air_gravity = -6.0

# running override
@export var override_run_speed = 1.2

# Jump variables
var jump_2_speed = 3.0 # I don't know what this does

var current_jumping_logic = "Jump"
var jump_ai_logic = "Jump"


func _ready():
	
	current_jumping_logic = jump_types[0]
	
	nav_agent.set_navigation_layer_value(2, true)
	if jump_types.count("Jump") >= 2:
		nav_agent.set_navigation_layer_value(3, true)
	
	jumped = number_of_jumps

var air_time = 0
func inclusive_physics(_delta):
	
	air_time += _delta*60
	
	if C.is_on_floor():
		jumped = 0
		air_time = 0
	
	if (C.is_in_base_movement_state() or C.movement_state == "Jump") and not C.AI:
		if can_start_jump() and C.key_press("Jump"):
			C.set_movement_state("Jump")
		elif can_continue_jumping() and C.PHYSkey_just_pressed("Jump"):
			jumped = 1
			C.set_movement_state("Jump")


var just_jumped = 0
func exclusive_physics(_delta):
	
	# Putting this line here instead of after the move_dir might be incorrect
	
	just_jumped += 1
	if not C.AI:
		if can_start_jump() and C.key_press("Jump"):
			click_jump()
		elif can_continue_jumping() and C.PHYSkey_just_pressed("Jump"):
			click_jump()
		
		base_state.move_dir = base_state.get_move_dir(_delta)
		
		C.get_logic(current_jumping_logic).jumping_physics(_delta)
	else:
		if C.get_logic(jump_ai_logic).has_method("ai"):
			C.get_logic(jump_ai_logic).ai(_delta)
		else:
			C.get_logic(current_jumping_logic).jumping_physics(_delta)
	
	
	# If we have hit the ground and we aren't pressing jump then switch back to the base movement state
	if not C.AI:
		if !C.is_on_floor():
			if C.PHYSkey_just_pressed("Fight"):
				if jump_attacks[jumped-1] != null:
					
					if C.get_logic(current_jumping_logic).has_method("end_jump"):
						C.get_logic(current_jumping_logic).end_jump()
					
					C.set_movement_state(jump_attacks[jumped-1])


func jumping_physics(_delta):
	
	# Reset movement
	if C.is_on_ceiling():
		C.char_vel.y = -1
	
	if not C.is_on_floor():
		C.char_vel.y += get_air_gravity()*_delta*C.var_scale
	else:
		if just_jumped > 5.0:
			C.char_vel.y = get_air_gravity()*_delta*C.var_scale
	
	var moved = (base_state.move_dir != Vector3())
	
	if moved:
		C.mesh_angle_to = Vector2(-base_state.move_dir.x, base_state.move_dir.z).angle()+deg_to_rad(90)
	
	base_state.move_dir_to.x = lerp(base_state.move_dir_to.x, base_state.move_dir.x, .15)
	base_state.move_dir_to.z = lerp(base_state.move_dir_to.z, base_state.move_dir.z, .15)
	
	C.set_velocity(C.char_vel+base_state.move_dir_to+C.push_vel+C.knock_vel)
	C.move_and_slide()
	
	C.mesh_angle_lerp(_delta, 0.2)
	
	if C.is_on_floor() and moved:
		anim.play(C.weapon_prefix+"Runloop", .4)
	
	if not C.AI:
		if C.is_on_floor():
			if not C.key_press("Jump"):
				C.reset_movement_state()


func has_nav(details):
	var link = details.owner
	
	if link.is_in_group("LinkJump") or (link.is_in_group("LinkDoubleJump") and jump_types.count("Jump") >= 2):
		
		if jump_types[0] == "Jump":
			jump_ai_logic = "Jump"
			return true
	
	for logic in C.get_logics():
		if "is_jump_state" in logic:
			jump_ai_logic = logic.logic_name()
			return true
	
	return false


func can_continue_jumping():
	if jumped < number_of_jumps:
		return true
	return false

func can_start_jump():
	if C.is_on_floor() or air_time <= 10:
		if jumped == 0:
			return true
	return false


func click_jump():
	get_parent().get_node(jump_types[jumped]).initiate_jump()
	current_jumping_logic = jump_types[jumped]
	
	jumped += 1
	
	just_jumped = 0


func initiate_jump():
	
	var prefix = C.weapon_prefix
	
	C.char_vel.y = jump_speeds[jumped]*C.var_scale
	
	anim.clear_queue()
	
	anim.play("NULL", .04)
	audio_player.play(jump_sounds[jumped])
	anim.play(prefix+jump_anims[jumped])
	anim.queue(prefix+"Fallloop")
	anim.queue(prefix+"Land")


func get_run_speed():
	if copy_run_speed and "run_speed" in base_state:
		return base_state.run_speed
	else:
		return override_run_speed

func get_air_gravity():
	if copy_air_gravity and "air_gravity" in base_state:
		return base_state.air_gravity
	else:
		return override_air_gravity


func die(_var):
	current_jumping_logic = "Jump"
	jumped = 0


func get_next_jump_state():
	
	
	if jump_types.size()-1 <= jumped:
		return jump_types[jumped]
	
	return null


func ai(_delta):
	
	var base = C.get_base_movement_state()
	
	var global_pos2 = base.vector3to2(C.global_position)
	var ai_to2 = base.vector3to2(C.ai_to)
	var ai_from2 = base.vector3to2(C.ai_from)
	
	var total_dist = ai_to2.distance_to(ai_from2)
	var current_dist = global_pos2.distance_to(ai_to2)
	
	var progress = -((total_dist-current_dist)/total_dist)+1
	
	if can_continue_jumping() and !ai_to2.distance_to(global_pos2) <= .4:
		
		if jump_types.size() >= jumped+1:
			
			if jump_types[jumped] == "Jump":
				
				if C.char_vel.y < get_air_gravity():
					
					if progress > .3:
						click_jump()
					
					elif C.ai_to.y < C.global_position.y:
						
						if not C.is_on_floor():
							click_jump()
	
	var direction = Vector2()
	
	if ai_to2.distance_to(global_pos2) <= .4 and C.is_on_floor():
		C.reset_movement_state()
	else:
		
		if air_time > 1 or (C.current_link and C.current_link.is_in_group("LinkFall")):
			if can_start_jump():
				click_jump()
	
	direction = ai_to2 - global_pos2
	
	var movement = direction.normalized()*C.var_scale*get_run_speed()
	
	var amount_moved_each_frame = C.var_scale*get_run_speed()
	var dist_to_target = (global_pos2.distance_to(ai_to2)/_delta)/amount_moved_each_frame
	
	if dist_to_target <= 1:
		movement = (ai_to2 - global_pos2)
	
	if dist_to_target <= 5: # hmmm 5 should be something more procedural
		movement = Vector2()
	
	base_state.move_dir = Vector3(movement.x, 0, movement.y)
	
	jumping_physics(_delta)
