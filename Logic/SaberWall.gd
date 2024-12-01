extends "res://Logic/LOGIC.gd"

var saber_logic = "Sword"
var our_prefix = "Sword"

var valid_logics = ["Base"]

var current_wall = null


func inclusive_physics(_delta):
	
	if C.key_press("Special") and C.is_on_floor() and valid_logics.has(C.movement_state) and !C.AI:
		# Check for valid wall spots here
		var wall = find_wall()
		
		# if we have found a wall
		if wall:
			current_wall = wall
			
			C.set_movement_state("SaberWall")


func initiate():
	
	if C.weapon_prefix != our_prefix:
		C.get_logic(saber_logic).draw_weapon()
	
	anim.play("SaberWall")
	
	
	base_state.freeze()
	if C.AI:
		var wall = find_wall()
		
		# if we have found a wall
		if wall:
			current_wall = wall


func exclusive_physics(_delta):
	
	# if the wall exists continue
	if current_wall:
		
		C.mesh_angle_to = current_wall.rotation.y
		
		var pos_change = (current_wall.global_position-C.global_position)*10
		
		pos_change.y = 0
		
		C.set_velocity(pos_change)
		C.move_and_slide()
		
		if anim.current_animation_length == anim.current_animation_position:
			
			current_wall.destroy()
			C.reset_movement_state()
	
	
	C.mesh_angle_lerp(_delta, 0.3)


func find_wall():
	# the best wall we have found
	var best_wall = null
	for local_wall in get_tree().get_nodes_in_group("SaberWall"):
		if local_wall.active:
			
			# the distance to the current wall in the loop
			var local_dist = C.global_position.distance_to(local_wall.global_position)
			
			# the maximum distance we can be away from the wall before it is unusable
			var max_dist = local_wall.max_dist
			
			# if we are close enough to the wall
			if local_dist <= max_dist:
				# This is the point where this wall is a valid wall to use
				if best_wall:
					# The distance to the best wall
					var best_dist = best_wall.global_position.distance_to(C.global_position)
					
					# if the local wall is closer than the best wall
					if local_dist < best_dist:
						# set the best wall to the current wall, as it is closer
						best_wall = local_wall
					
				else:
					# if this is the first wall, then set best_wall to it
					best_wall = local_wall
	
	# return the best wall we found
	return best_wall
