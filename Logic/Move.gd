extends Logic

var walk_speed = 0.6
var run_speed = 1.2
var move_delay = 0.0

# move delay time left
var move_delay_timer = 0.0
var move_delay_reset = false
#var moved_since_online = true

var move_dir = Vector2()
var last_move_dir = Vector2()

var not_air_anims = ["Idleloop", "Runloop"]

var footsteps_played = 0

# Set the correct navigational layer values
func _ready():
	anim.connect("animation_started", anim_started)
	C.connect("revive", revive)
	
	last_move_dir = f.to_vec2(-rig.transform.basis.z)
	move_delay_timer = move_delay
	nav_agent.set_navigation_layer_value(1, true)

func anim_started(anim_name):
	if anim_name.ends_with("Runloop"):
		footsteps_played = 0

var on_floor_last_frame = true

func exclusive_physics(delta):
	
	# footsteps
	if anim.current_animation.ends_with("Runloop"):
		var footsteps_times = C.details.animations[anim.current_animation].key_frames.footsteps
		if footsteps_times.size() > footsteps_played:
			var next_footstep_time = footsteps_times[footsteps_played]
			if anim.current_animation_position > next_footstep_time:
				footsteps_played += 1
				audio.play("Run")
	
	# If we are in the air and we are playing one of the animations in not_air_anims
	# Then make us be falling instead
	if not C.is_on_floor():
		for an in not_air_anims:
			if anim.current_animation.ends_with(an):
				# Play fallloop with a blend of .5
				anim.play(C.weapon_prefix+"Fallloop", .5)
				break
	
	# Get move_dir and moved
	move_dir = input_vector * var_scale
	var moved = (move_dir != Vector2())
	
	# If we did move, then set the mesh angle we want to go to
	if moved:
		
		var change = last_move_dir.normalized().dot(move_dir.normalized())
		
		if change < -0.6:
			if move_delay_reset == true:
				move_delay_timer = 0.0
				move_delay_reset = false
		
		last_move_dir = move_dir
		
		# If we are on the floor and we have moved play the running animation
		if C.is_on_floor():
			anim.play("Runloop", .2)
	else:
		move_delay_reset = true
		# If we have not moved
		# and we are running then go to idle.
		if anim.current_animation.ends_with("Runloop"):
			anim.play("Idleloop", .4)
			#anim.play("NULL", .04) # solution for other things
		# If we are on the floor and nothing is playing then play idle
		if C.is_on_floor():
			if not anim.is_playing():
				anim.play("Idleloop", .04)
	
	if anim.current_animation.ends_with("Runloop"):
		run_anim_pos = anim.current_animation_position/anim.current_animation_length
	else:
		run_anim_pos = -1.0
	
	if move_delay_timer > move_delay:# and moved_since_online:
		C.mesh_angle_to = -last_move_dir.angle()-deg_to_rad(90)
		#facing_move_dir = last_move_dir
	else:
		move_delay_timer += delta
	
	# If we are not on the floor, and nothing is playing, then play fallloop and queue land
	# for when we hit the ground.
	if not C.is_on_floor():
		if not anim.is_playing():
			anim.play("Fallloop", .1)
			anim.queue("Land")
	# If we are on the floor and we have just jumped or we are falling then play Land
	else:
		if anim.current_animation.ends_with("Fallloop"):
			anim.play("Land", 0)
		
		elif anim.current_animation.ends_with("Jump"):
			anim.play("Land", .1)
	
	if C.is_on_floor() == true and on_floor_last_frame == false:
		audio.play("Land")
	
	on_floor_last_frame = C.is_on_floor()
	
	# smoothly transition our current movement direction to our desired movement direction
	var weight = .15
	C.char_vel.x = lerp(C.char_vel.x, move_dir.x, weight * delta * 60)
	C.char_vel.z = lerp(C.char_vel.z, move_dir.y, weight * delta * 60)
	
	# Set the velocity to our current movement direction as well as a bunch of other factors
	#C.set_velocity(C.char_vel + C.push_vel + C.knock_vel)
	# Update our position based on CharacterBody physics using move_and_slide
	#C.move_and_slide()
	
	#if move_delay_time_left > move_delay:
	# Smoothly change our rotation to our desired rotation
	#C.mesh_angle_lerp(delta, 0.2)


func enter():
	super()
	#moved_since_online = false
	move_delay_reset = true
	last_move_dir = f.to_vec2(-rig.transform.basis.z)
	#last_move_dir = mesh.transform.basis.z#facing_move_dir
	#move_delay_timer = move_delay + 0.1
	#last_move_dir = facing_move_dir
	#move_dir = facing_move_dir
	#move_delay_timer = 0.0#move_delay+0.0


var run_anim_pos:float = -1

# This is so we can copy some variables across switches
var vars_copied_on_switch = ["run_anim_pos"]
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
			return ["Runloop", run_anim_pos]
		else:
			return ["Idleloop", 0.0]
	else:
		return ["Fallloop", 0.0]


# This logic has pathfinding data so let it be found by character.gd
func has_nav(details):
	
	var location = details.link_entry_position
	var location_to = details.link_exit_position
	
	if details.owner.is_in_group("LinkFall") and location.y > location_to.y:
		return true
	
	return false


func revive():
	last_move_dir = f.to_vec2(-rig.transform.basis.z)
