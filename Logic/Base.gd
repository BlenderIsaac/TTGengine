extends "res://Logic/LOGIC.gd"

# Logic Type: BASE MOVEMENT STATE
# Contains: Running, Jumping, Double Jumping, Back Jumping

# Gravity
@export var air_gravity = -6.0

# Jump variables
var jump_2_speed = 1.2

var walk_speed = 0.6
var run_speed = 1.2
var move_delay = 0.0#0.2

# move delay time left
var move_delay_timer = 0.0
var move_delay_reset = false
#var moved_since_online = true

var move_dir_to = Vector3()
var move_dir = Vector3()
var last_move_dir = Vector3()

#var facing_move_dir = Vector3()

var not_air_anims = ["Idleloop", "Runloop"]

var footstep_at_times = [0.1, 0.4]
var footsteps_played = 0

# Set the correct navigational layer values
func _ready():
	last_move_dir = mesh.transform.basis.z
	#facing_move_dir = mesh.transform.basis.z
	
	move_delay_timer = move_delay
	nav_agent.set_navigation_layer_value(1, true)

func anim_started(vars):
	var anim_name = vars[0]
	
	#print(anim_name)
	
	if anim_name.ends_with("Runloop"):
		footsteps_played = 0

var on_floor_last_frame = true

#func inclusive_physics(_delta):
	#DebugDraw3D.draw_arrow(C.position, C.position+last_move_dir, Color.RED)
	#DebugDraw3D.draw_arrow(C.position, C.position-mesh.transform.basis.z, Color.GREEN)
	##DebugDraw3D.draw_arrow(C.position, C.position-mesh.basis.z, Color.GREEN_YELLOW)
	#
	##DebugDraw3D.draw_arrow(C.position, C.position+move_dir_to, Color.YELLOW)
	#DebugDraw3D.draw_arrow(C.position, C.position+move_dir, Color.BLUE)


func exclusive_physics(_delta):
	
	# footsteps
	if anim.current_animation.ends_with("Runloop"):
		if footstep_at_times.size() > footsteps_played:
			var next_footstep_time = footstep_at_times[footsteps_played]
			if anim.current_animation_position > next_footstep_time:
				footsteps_played += 1
				audio_player.play("Run")
	
	gen_gravity(_delta, true)
	
	
	# reset our movement direction
	#move_dir = Vector3()
	
	# Reset movement
	if C.is_on_ceiling():
		C.char_vel.y = -1
	if C.is_on_wall():
		C.char_vel.x = 0
		C.char_vel.z = 0
	
	# Get move_dir and moved
	move_dir = get_move_dir(_delta)
	var moved = (move_dir != Vector3())
	
	# Animations and mesh_angle_to
	var prefix = C.weapon_prefix
	
	# If we did move, then set the mesh angle we want to go to
	if moved:
		
		var change = last_move_dir.normalized().dot(move_dir.normalized())
		
		DebugDraw2D.set_text("change "+C.char_name, change)
		
		if change < -0.6:
			if move_delay_reset == true:
				move_delay_timer = 0.0
				move_delay_reset = false
		
		last_move_dir = move_dir
		
		# If we are on the floor and we have moved play the running animation
		if C.is_on_floor():
			anim.play(prefix+"Runloop", .2)
	else:
		move_delay_reset = true
		# If we have not moved
		# and we are running then go to idle.
		if anim.current_animation.ends_with("Runloop"):
			anim.play(prefix+"Idleloop", .4)
			#anim.play("NULL", .04) # solution for other things
		# If we are on the floor and nothing is playing then play idle
		if C.is_on_floor():
			if not anim.is_playing():
				anim.play(prefix+"Idleloop", .04)
	
	
	if move_delay_timer > move_delay:# and moved_since_online:
		C.mesh_angle_to = Vector2(-last_move_dir.x, last_move_dir.z).angle()+deg_to_rad(90)
		#facing_move_dir = last_move_dir
	else:
		move_delay_timer += _delta
	
	# If we are not on the floor, and nothing is playing, then play fallloop and queue land
	# for when we hit the ground.
	if not C.is_on_floor():
		if not anim.is_playing():
			anim.play(prefix+"Fallloop", .1)
			anim.queue(prefix+"Land")
	# If we are on the floor and we have just jumped or we are falling then play Land
	else:
		if anim.current_animation.ends_with("Fallloop"):
			anim.play(prefix+"Land", 0)
		
		elif anim.current_animation.ends_with("Jump"):
			anim.play(prefix+"Land", .1)
	
	if C.is_on_floor() == true and on_floor_last_frame == false:
		audio_player.play("Land")
	
	on_floor_last_frame = C.is_on_floor()
	
	# smoothly transition our current movement direction to our desired movement direction
	var weight = .15
	move_dir_to.x = lerp(move_dir_to.x, move_dir.x, weight*_delta*60)
	move_dir_to.z = lerp(move_dir_to.z, move_dir.z, weight*_delta*60)
	
	# Set the velocity to our current movement direction as well as a bunch of other factors
	C.set_velocity(C.char_vel+move_dir_to+C.push_vel+C.knock_vel)
	# Update our position based on CharacterBody physics using move_and_slide
	C.move_and_slide()
	
	#if move_delay_time_left > move_delay:
	# Smoothly change our rotation to our desired rotation
	C.mesh_angle_lerp(_delta, 0.2)

func initiate():
	#moved_since_online = false
	move_delay_reset = true
	#last_move_dir = mesh.transform.basis.z#facing_move_dir
	#move_delay_timer = move_delay + 0.1
	#last_move_dir = facing_move_dir
	#move_dir = facing_move_dir
	#move_delay_timer = 0.0#move_delay+0.0

func gen_gravity(_delta, animate=false):
	if not C.is_on_floor():
		C.char_vel.y += air_gravity*_delta*C.var_scale
		
		if animate:
			# If we are in the air and we are playing one of the animations in not_air_anims
			# Then make us be falling instead
			for an in not_air_anims:
				if anim.current_animation.ends_with(an):
					# Play fallloop with a blend of .5
					anim.play(C.weapon_prefix+"Fallloop", .5)
					break
	else:
		# If we are not falling set char_vel.y to just slightly negative
		C.char_vel.y = air_gravity*_delta*C.var_scale

# This is so we can copy some variables across switches
var vars_copied_on_switch = ["move_dir_to", "move_dir"]
func get_switched_var():
	var vars = {}
	
	for prop_name in vars_copied_on_switch:
		
		vars[prop_name] = get(prop_name)
	
	return vars

func set_switched_var(vars):
	
	for v in vars.keys():
		set(v, vars.get(v))


func get_switch_anim():
	
	if C.is_on_floor():
		if move_dir.length() > .1:
			return "Runloop"
		else:
			return "Idleloop"
	else:
		return "Fallloop"


# This logic has pathfinding data so let it be found by character.gd
func has_nav(details):
	
	var location = details.link_entry_position
	var location_to = details.link_exit_position
	
	if details.owner.is_in_group("LinkFall") and location.y > location_to.y:
		return true
	
	return false

# A function called apon death
func freeze():
	move_dir = Vector3()
	move_dir_to = Vector3()

func revive(_args):
	last_move_dir = -mesh.transform.basis.z

func get_move_dir(_delta):
	var new_move_dir = Vector3()
	
	if C.AI:
		new_move_dir = ai(_delta)
	else:
		new_move_dir = C.get_move_dir()
	
	return new_move_dir*C.var_scale*run_speed


func vector3to2(vector3):
	return Vector2(vector3.x, vector3.z)


var chilling = true

var last_location = Vector3()
var next_location = Vector3()
func ai(_delta):
	
	var max_distance = C.AI_max_distance
	
	if chilling == false:
		max_distance = C.AI_desired_distance
	
	if C.target != null and C.get_distance_to_target() > max_distance:
		
		var direction = Vector3()
		
		if nav_agent.is_target_reachable() and not nav_agent.is_target_reached():
			
			if not next_location == nav_agent.get_next_path_position():
				last_location = next_location
			
			next_location = nav_agent.get_next_path_position()
			
			direction = vector3to2(C.global_position).direction_to(vector3to2(next_location))
		
		var movement = direction.normalized()
		
		var global_pos2 = vector3to2(C.global_position)
		var target_pos2 = vector3to2(next_location)
		var amount_moved_each_frame = 1
		var dist_to_target = (global_pos2.distance_to(target_pos2)/_delta)/amount_moved_each_frame
		
		if dist_to_target <= 1:
			movement *= dist_to_target
		
		chilling = false
		return Vector3(movement.x, 0, movement.y)
	else:
		chilling = true
	
	
	return Vector3()
