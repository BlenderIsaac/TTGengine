extends "res://Logic/LOGIC.gd"

var current_lever = null
var move_speed = 1

var valid_logics = ["Base"]


func inclusive_physics(_delta):
	
	if C.key_just_pressed("Special") and C.is_on_floor() and valid_logics.has(C.movement_state):
		# Check for valid lever spots here
		var lever = find_lever()
		
		# if we have found a lever
		if lever:
			current_lever = lever
			
			C.set_movement_state("Lever")


func initiate():
	
	C.weapon_prefix = ""
	
	if C.AI:
		var lever = find_lever()
		
		if lever:
			current_lever = lever
	
	anim.play("PullLever", .01)
	
	if current_lever:
		current_lever.pull()


func exclusive_physics(_delta):
	
	C.mesh_angle_to = current_lever.rotation.y
	
	# if the lever exists continue
	if current_lever:
		
		var diff = current_lever.global_position - C.global_position
		var diff_norm = diff.normalized()*move_speed*C.var_scale*_delta*60
		
		if diff.length() < .04*move_speed:
			diff_norm = diff_norm*diff.length()
		
		C.set_velocity(diff_norm)
		C.move_and_slide()
	
	if current_lever:
		if !anim.current_animation == "PullLever" or anim.current_animation_position >= anim.current_animation_length:
			base_state.freeze()
			anim.play("Idleloop", .4)
			C.reset_movement_state()
	
	C.mesh_angle_lerp(_delta, 0.3)


func find_lever():
	# the best lever we have found
	var best_lever = null
	
	for local_lever in get_tree().get_nodes_in_group("Lever"):
		if local_lever.active:
			# the distance to the current lever in the loop
			var local_dist = C.global_position.distance_to(local_lever.global_position)
			
			# the maximum distance we can be away from the lever before it is unusable
			var max_dist = local_lever.lever_size
			
			# calculate angle_diff, the difference between our rotations
			var lever_angle = Vector2(0, 1).rotated(local_lever.rotation.y)
			var self_angle = Vector2(0, 1).rotated(C.mesh_angle_to)
			var angle_diff = abs(lever_angle.angle_to(self_angle))
			
			# if we are close enough to the lever
			if angle_diff < 1:
				if local_dist <= max_dist:
					# This is the point where this lever is a valid lever to use
					if best_lever:
						# The distance to the best lever
						var best_dist = best_lever.global_position.distance_to(C.global_position)
						
						# if the local lever is closer than the best lever
						if local_dist < best_dist:
							# set the best lever to the current lever, as it is closer
							best_lever = local_lever
						
					else:
						# if this is the first lever, then set best_lever to it
						best_lever = local_lever
	
	# return the best lever we found
	return best_lever

