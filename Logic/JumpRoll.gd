extends "res://Logic/LOGIC.gd"

@export var copy_run_speed = true
@export var copy_air_gravity = true

# gravity override
@export var override_air_gravity = -6.0

var jump_roll_speed = 2.1
var max_attacks = 3
var attacks = 0

var has_attacked = false

var jump_recovery_max = .03
var jump_recovery = 0

var quick_attack_logic = "ProjectileWeapon"

var is_jump_state


func initiate_jump():
	base_state.freeze()
	un_attack = 0
	attacks = 0
	jump_recovery = 0
	attacking = false
	has_attacked = false
	ending = false
	anim.play(C.weapon_prefix+"RollInitiate")
	anim.queue(C.weapon_prefix+"Rollloop")

var ending = false
var un_attack = 0

func jumping_physics(_delta):
	
	if not C.is_on_floor():
		C.char_vel.y += get_air_gravity()*_delta*C.var_scale
	else:
		C.char_vel.y = get_air_gravity()*_delta*C.var_scale
	
	if ending == false:
		if not C.is_on_floor():
			
			# Reset movement
			if C.is_on_ceiling():
				C.char_vel.y = -1
			
			var moved = (base_state.move_dir != Vector3())
			if moved:
				C.mesh_angle_to = Vector2(-base_state.move_dir.x, base_state.move_dir.z).angle()+deg_to_rad(90)
			
			var move_dir = Vector3(0, 0, -1).rotated(Vector3.UP, C.mesh_angle_to)*C.var_scale*jump_roll_speed
			
			C.set_velocity(C.char_vel+move_dir+C.push_vel+C.knock_vel)
			C.move_and_slide()
			
			C.mesh_angle_lerp(_delta, 0.2)
		else:
			anim.play(C.weapon_prefix+"RollEnd")
			ending = true
	else:
		var root_vel = Vector3()
		
		jump_recovery += _delta
		
		if !anim.current_animation == C.weapon_prefix+"RollEnd":
			if attacks == 0:
				reset_jump()
		
		if !jump_recovery > 1:
			pass
		
		if anim.current_animation.ends_with("RollEnd"):
			root_vel = C.get_root_vel(0, 1)/_delta
		
		C.set_velocity(C.char_vel+C.push_vel+C.knock_vel+root_vel)
		C.move_and_slide()
		
		if attacking == true:
			get_quick_attack_logic().test_shoot()
			attacking = false
		
		un_attack += _delta
		
		if max_attacks-1 >= attacks:
			if C.key_just_pressed("Fight") and !C.AI:
				C.weapon_prefix = get_our_prefix()
				
				quick_attack()
				un_attack = 0
				attacks += 1
		else:
			if has_attacked:
				reset_jump()
		
		if un_attack > .3 and attacks > 0:
			reset_jump()


func reset_jump():
	anim.play(C.weapon_prefix+"Idleloop", .1)
	base_state.freeze()
	C.reset_movement_state()


var attacking = false
func quick_attack():
	anim.play("GunRollShoot", 0)
	has_attacked = true
	attacking = true


func get_quick_attack_logic():
	return get_parent().get_node(quick_attack_logic)


func get_our_prefix():
	return get_quick_attack_logic().our_prefix


func has_jump_nav(details):
	var link = details.owner
	if link.is_in_group("LinkJumpRoll"):
		return true
	return false


func get_air_gravity():
	if copy_air_gravity and "air_gravity" in base_state:
		return base_state.air_gravity
	else:
		return override_air_gravity


#func ai(_delta):
#
#	var base = C.get_base_movement_state()
#
#	var global_pos2 = base.vector3to2(C.global_position)
#	#var ai_from2 = base.vector3to2(C.ai_from)
#	var ai_to2 = base.vector3to2(C.ai_to)
#
#	var direction = Vector2()
#
#
#	if ai_to2.distance_to(global_pos2) <= .4 and C.is_on_floor():
#		C.reset_movement_state()
#	else:
#		if air_time > 1 or (C.current_link and C.current_link.is_in_group("LinkFall")):
#			if can_jump():
#				click_jump()
#
#	direction = ai_to2 - global_pos2
#
#	var movement = direction.normalized()*C.var_scale*get_run_speed()
#
#	var amount_moved_each_frame = C.var_scale*get_run_speed()
#	var dist_to_target = (global_pos2.distance_to(ai_to2)/_delta)/amount_moved_each_frame
#
#	if dist_to_target <= 1:
#		movement = (ai_to2 - global_pos2)
#
#	if dist_to_target <= 5: # hmmm 5 should be something more procedural
#		movement = Vector2()
#
#	return Vector3(movement.x, 0, movement.y)
