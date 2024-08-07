extends "res://Logic/LOGIC.gd"

var current_panel = null
var move_speed = 1

var valid_logics = ["Base"]
var panels_accessed = []

func inclusive_physics(_delta):
	
	if C.key_just_pressed("Special") and C.is_on_floor() and valid_logics.has(C.movement_state):
		# Check for valid panels here
		var panel = find_panel()
		
		# if we have found a panel
		if panel:
			current_panel = panel
			
			C.set_movement_state("Panel")
			current_panel.active = false


func initiate():
	
	C.weapon_prefix = ""
	
	if C.AI:
		var panel = find_panel()
		
		if panel:
			current_panel = panel
	
	anim.play("ActivatePanel", .01)


func exclusive_physics(_delta):
	
	C.mesh_angle_to = current_panel.rotation.y
	
	# if the panel exists continue
	if current_panel:
		
		var diff = current_panel.global_position - C.global_position
		var diff_norm = diff.normalized()*move_speed*C.var_scale*_delta*60
		
		if diff.length() < .04*move_speed:
			diff_norm = diff_norm*diff.length()
		
		C.set_velocity(diff_norm)
		C.move_and_slide()
	
	if current_panel:
		if !anim.current_animation == "ActivatePanel" or anim.current_animation_position >= anim.current_animation_length:
			current_panel.activate()
			base_state.freeze()
			anim.play("Idleloop", .4)
			C.reset_movement_state()
	
	C.mesh_angle_lerp(_delta, 0.3)


func find_panel():
	# the best panel we have found
	var best_panel = null
	
	for local_panel in get_tree().get_nodes_in_group("Panel"):
		if local_panel.active:
			# the distance to the current panel in the loop
			var local_dist = C.global_position.distance_to(local_panel.global_position)
			
			# the maximum distance we can be away from the panel before it is unusable
			var max_dist = local_panel.panel_size
			
			# calculate angle_diff, the difference between our rotations
			var panel_angle = Vector2(0, 1).rotated(local_panel.rotation.y)
			var self_angle = Vector2(0, 1).rotated(C.mesh_angle_to)
			var angle_diff = abs(panel_angle.angle_to(self_angle))
			
			# if we are close enough to the panel
			if angle_diff < 1:
				if local_dist <= max_dist:
					# This is the point where this panel is a valid panel to use
					if best_panel:
						# The distance to the best panel
						var best_dist = best_panel.global_position.distance_to(C.global_position)
						
						# if the local panel is closer than the best panel
						if local_dist < best_dist:
							# set the best panel to the current panel, as it is closer
							best_panel = local_panel
						
					else:
						# if this is the first panel, then set best_panel to it
						best_panel = local_panel
	
	# return the best panel we found
	return best_panel

