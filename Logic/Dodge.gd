extends "res://Logic/LOGIC.gd"

var dodge = []
var our_prefix = "Gun"
var prev_pose = Vector3()

func exclusive_damage(amount, _who_from):
	if not dodge.has(_who_from):
		C.generic_damage(amount)


func initiate():
	var direction = ["Left", "Right"].pick_random()
	anim.play(our_prefix+"Dodge"+direction, .1)
	anim.queue("BASE")


func exclusive_physics(_delta):
	
	if anim.current_animation == "BASE":
		C.reset_movement_state()
	
	if not C.is_on_floor():
		C.char_vel.y += C.get_base_movement_state().air_gravity*_delta*C.var_scale
	else:
		C.char_vel.y = C.get_base_movement_state().air_gravity*_delta*C.var_scale
	
	var root_vel = Vector3()
	var bone_pos = $"../../Mesh/Armature/Skeleton3D".get_bone_pose_position(0)-prev_pose
	var anim_progress = anim.current_animation_position/anim.current_animation_length
	
	if anim_progress >= .1 and anim_progress <= .9:
		root_vel = bone_pos.rotated(Vector3.UP, $"../../Mesh".rotation.y)
	
	C.set_velocity((C.char_vel+root_vel/_delta)+C.push_vel)
	C.move_and_slide()
	
	C.mesh_angle_lerp(_delta, 0.2)
	
	# setup this for the next frame
	prev_pose = $"../../Mesh/Armature/Skeleton3D".get_bone_pose_position(0)



func inclusive_physics(_delta):
	if C.is_in_base_movement_state() or C.movement_state == "Dodge":
		if C.is_on_floor():
			if C.key_just_pressed("Fight"):
				if C.weapon_prefix == our_prefix:
					
					# get the dangerous bullets
					var bullets = get_dangerous_bullets()
					
					# if there is at least one bullet then dodge it
					if bullets.size() > 0:
						
						C.mesh_angle_to = bullets[0].rotation.y
						
						dodge.append_array(bullets)
						C.set_movement_state("Dodge")


func get_dangerous_bullets():
	var bullets = []
	for p in get_tree().get_nodes_in_group("projectile"):
		if p.target == C:
			if bullet_will_reach_us(p):
				bullets.append(p)
	
	return bullets

func bullet_will_reach_us(bullet):
	if bullet.global_position.distance_to(C.global_position+C.aim_pos) < 4:
		
		var look_toward = Basis.looking_at(bullet.position-(C.position+C.aim_pos)).get_euler()
		
		var current_rotation = bullet.rotation
		
		var difference = abs(f.angle_to_angle(look_toward.y, current_rotation.y)/PI)
		
		if difference < 0.55:
			return true
	
	return false
