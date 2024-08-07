extends "res://Logic/LOGIC.gd"

var current_shortie = null
var crawl_speed = 0.33
var snap_speed = 1

var valid_logics = ["Base"]

var state = "snap_to"

var crawl_progress = 0.0


func _ready():
	nav_agent.set_navigation_layer_value(6, true)


func inclusive_physics(_delta):
	
	if C.key_just_pressed("Special") and C.is_on_floor() and valid_logics.has(C.movement_state):
		# Check for valid shortie spots here
		var shortie = find_shortie()
		
		# if we have found a shortie
		if shortie:
			current_shortie = shortie
			
			C.set_movement_state("Shortie")


func initiate():
	
	crawl_progress = 0.0
	base_state.freeze()
	C.weapon_prefix = ""
	
	if C.AI:
		var shortie = find_shortie()
		
		if shortie:
			current_shortie = shortie
		else:
			C.reset_movement_state()
	
	state = "snap_to"
	anim.play("CrawlIn", .4)
	
#	if current_shortie:
#		current_shortie.open()


func exclusive_physics(_delta):
	
	
	if state == "snap_to":
		
		C.mesh_angle_to = current_shortie.rotation.y
		# if the shortie exists continue
		if current_shortie:
			
			var diff = current_shortie.global_position - C.global_position
			var diff_norm = diff.normalized()*snap_speed*C.var_scale*_delta*60
			
			if diff.length() < .04*snap_speed:
				diff_norm = diff_norm*diff.length()
				state = "crawlin"
			
			
			C.set_velocity(diff_norm)
			C.move_and_slide()
	elif state == "crawlin":
		var root_vel = C.get_root_vel(.1, .9)
		
		C.global_position += root_vel
		
		if !anim.current_animation == "CrawlIn":
			state = "traveling"
	elif state == "traveling":
		
		var from = current_shortie.global_position
		var to = current_shortie.get_node(current_shortie.other_side).global_position
		
		C.global_position.x = lerp(from.x, to.x, crawl_progress)
		C.global_position.y = lerp(from.y, to.y, crawl_progress)
		C.global_position.z = lerp(from.z, to.z, crawl_progress)
		
		crawl_progress += _delta*crawl_speed
		
		if crawl_progress > 1:
			state = "crawlout"
	elif state == "crawlout":
		
		C.global_position = current_shortie.get_node(current_shortie.other_side).global_position
		current_shortie = null
		C.reset_movement_state()
	
	
#	if current_shortie:
#		if current_shortie.get_node("AnimationPlayer").current_animation == "":
#			base_state.freeze()
#			anim.play("Idleloop", .4)
#			C.reset_movement_state()
	
	C.mesh_angle_lerp()


func find_shortie():
	# the best shortie we have found
	var best_shortie = null
	for local_shortie in get_tree().get_nodes_in_group("Shortie"):
		
		# the distance to the current shortie in the loop
		var local_dist = C.global_position.distance_to(local_shortie.global_position)
		
		# the maximum distance we can be away from the shortie before it is unusable
		var max_dist = local_shortie.shortie_size
		
		# calculate angle_diff, the difference between our rotations
		var shortie_angle = Vector2(0, 1).rotated(local_shortie.rotation.y)
		var self_angle = Vector2(0, 1).rotated(C.mesh_angle_to)
		var angle_diff = abs(shortie_angle.angle_to(self_angle))
		
		# if we are close enough to the shortie
		if angle_diff < 1:
			if local_dist <= max_dist:
				# This is the point where this shortie is a valid shortie to use
				if best_shortie:
					# The distance to the best shortie
					var best_dist = best_shortie.global_position.distance_to(C.global_position)
					
					# if the local shortie is closer than the best shortie
					if local_dist < best_dist:
						# set the best shortie to the current shortie, as it is closer
						best_shortie = local_shortie
					
				else:
					# if this is the first shortie, then set best_shortie to it
					best_shortie = local_shortie
	
	# return the best shortie we found
	return best_shortie


func has_nav(details):
	var link = details.owner
	
	if link.is_in_group("LinkShortie"):
		return true
	
	return false




