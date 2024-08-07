extends "res://Logic/LOGIC.gd"

@export var copy_run_speed = true
@export var copy_air_gravity = true

# gravity override
@export var override_air_gravity = -6.0

# running override
@export var override_run_speed = 1.2

var jetpack_height = 0
var jetpack_duration = 590.4
var jetpack_left = 0

var jetpack_particles = true
var jetpack_particles_path = "JetpackParticles.tscn"

# Jump variables
var jump_2_speed = 3.0 # I don't know what this does

var is_jump_state

var needs_weapon = false
var weapon_logic = "Sword"


@onready var jetpack_part = null
func _ready():
	nav_agent.set_navigation_layer_value(4, true)
	
	if jetpack_particles:
		jetpack_part = l.get_load(SETTINGS.mod_path+"/"+C.origin_mod+"/characters/scenes/"+jetpack_particles_path).instantiate()
		
		C.get_node("Mesh/Armature/Skeleton3D").add_child(jetpack_part)
		jetpack_part.bone_idx = 9
		
		set_emitting(false)


func _process(_delta):
	if C.has_logic("BaseSwordAI"):
		var BaseSwordAI = C.get_logic("BaseSwordAI")
		
		if BaseSwordAI.force_weapon_out.has("Jetpack"):
			BaseSwordAI.force_weapon_out.erase("Jetpack")
		
		if needs_weapon:
			if jetpack_left > 0 and !C.is_on_floor():
				if !BaseSwordAI.force_weapon_out.has("Jetpack"):
					BaseSwordAI.force_weapon_out.append("Jetpack")
	
	if should_stop_jetpack():
		audio_player.end_loop("Jetpack")
		if jetpack_particles:set_emitting(false)
	
	if C.is_on_floor():
		jetpack_left = jetpack_duration


func should_stop_jetpack():
	
	if C.movement_state == "Jump":
		if C.get_logic("Jump").current_jumping_logic == "Jetpack":
			return false
	
	return true


var jetpack_boost = 0
var just_jetpacked = false
func initiate_jump():
	
	if needs_weapon:
		C.get_logic(weapon_logic).draw_weapon()
	
	if jetpack_particles:set_emitting(true)
	audio_player.start_loop("Jetpack")
	C.char_vel.y = -get_air_gravity()
	jetpack_left = jetpack_duration
	jetpack_height = C.global_position.y+jetpack_boost
	just_jetpacked = true


func jumping_physics(_delta):
	
	# Reset movement
	if C.is_on_ceiling():
		C.char_vel.y = -1
	
	var moved = (base_state.move_dir != Vector3())
	
	if moved:
		C.mesh_angle_to = Vector2(-base_state.move_dir.x, base_state.move_dir.z).angle()+deg_to_rad(90)
		
		if not C.is_on_floor():
			var anim_pos = anim.current_animation_position
			anim.play(C.weapon_prefix+"Flyloop", 0.4)
			anim.seek(anim_pos)
	else:
		
		if not C.is_on_floor():
			var anim_pos = anim.current_animation_position
			anim.play(C.weapon_prefix+"FlyIdleloop", 0.4)
			anim.seek(anim_pos)
	
	base_state.move_dir_to.x = lerp(base_state.move_dir_to.x, base_state.move_dir.x, .15)
	base_state.move_dir_to.z = lerp(base_state.move_dir_to.z, base_state.move_dir.z, .15)
	
	if jetpack_boost == 0.0:
		C.char_vel.y = 0.0
	else:
		C.char_vel.y = (C.global_position.y-jetpack_height)*-10
	C.velocity.y = 0.0
	
	C.set_velocity(C.char_vel+base_state.move_dir_to+C.push_vel+C.knock_vel)
	
	C.move_and_slide()
	
	var vel = C.velocity
	vel.y = 0
	
	jetpack_left -= vel.length()
	
	if jetpack_left <= 0:
		#print("run out")
		cancel_jetpack()
	
	if (C.PHYSkey_just_pressed("Jump") and !just_jetpacked == true and !C.AI):
		cancel_jetpack()
	
	just_jetpacked = false
	
	C.mesh_angle_lerp(_delta, 0.2)
	
	if C.is_on_floor() and moved:
		anim.play(C.weapon_prefix+"Runloop", .4)
	
	if C.is_on_floor():
		if C.AI:
			cancel_jetpack()
		elif not C.key_press("Jump"):
			cancel_jetpack()


func set_emitting(value):
	for child in jetpack_part.get_children():
		child.emitting = value


func has_jump_nav(details):
	var link = details.owner
	if link.is_in_group("LinkJetpack") or link.is_in_group("LinkJump"):
		return true
	return false


func cancel_jetpack():
	C.char_vel.y = 0
	
	anim.play(C.weapon_prefix+"Fallloop", .3)
	anim.queue(C.weapon_prefix+"Land")
	
	C.get_logic("Jump").current_jumping_logic = C.get_logic("Jump").jump_types[0]
	end_jump()
	C.reset_movement_state()


func end_jump():
	audio_player.end_loop("Jetpack")
	if jetpack_particles:set_emitting(false)


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
	if jetpack_particles:
		for child in jetpack_part.get_children():
			child.restart()
		
		set_emitting(false)
	
	jetpack_left = jetpack_duration


func ai(_delta):
	
	var jump_logic = C.get_logic("Jump")
	var base = C.get_base_movement_state()
	
	var global_pos2 = base.vector3to2(C.global_position)
	var ai_to2 = base.vector3to2(C.ai_to)
	
	var direction = Vector2()
	
	if ai_to2.distance_to(global_pos2) <= .4 and C.is_on_floor():
		C.reset_movement_state()
	else:
		if jump_logic.air_time > 1:
			if jump_logic.jumped == 0:
				if jump_logic.jump_types[0] == "Jump":
					if jump_logic.can_start_jump():
						jump_logic.jumped = 0
						jump_logic.click_jump()
	
	direction = ai_to2 - global_pos2
	
	var movement = direction.normalized()*C.var_scale*get_run_speed()
	
	var amount_moved_each_frame = C.var_scale*get_run_speed()
	var dist_to_target = (global_pos2.distance_to(ai_to2)/_delta)/amount_moved_each_frame
	
	if dist_to_target <= 1:
		movement = (ai_to2 - global_pos2)
	
	if dist_to_target <= 5: # hmmm 5 should be something more procedural
		movement = Vector2()
	
	base_state.move_dir = Vector3(movement.x, 0, movement.y)
	
	# TEMP
	C.respawn_wait = 0.1
	
	if jump_logic.jump_types[0] == "Jump" and jump_logic.jumped <= 1:
		jump_logic.jumping_physics(_delta)
	else:
		jumping_physics(_delta)
	
	if C.char_vel.y < -3:
		
		if jump_logic.can_continue_jumping():
			if jump_logic.get_next_jump_state() == "Jetpack":
				jump_logic.click_jump()
	
	if jump_logic.jumped == jump_logic.jump_types.find("Jetpack") and ai_to2.distance_to(global_pos2) <= .4:
		cancel_jetpack()

