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


# Set the correct navigational layer values
func _ready():
	C.connect("revive", revive)
	C.connect("death", death)
	
	last_move_dir = f.to_vec2(-rig.transform.basis.z)
	move_delay_timer = move_delay
	nav_agent.set_navigation_layer_value(1, true)

var on_floor_last_frame = true
func exclusive_physics(delta):
	
	# Get move_dir and moved
	move_dir = input_vector * var_scale * run_speed
	var moved = (move_dir != Vector2())
	
	# If we did move, then set the mesh angle we want to go to
	if moved:
		
		var change = last_move_dir.normalized().dot(move_dir.normalized())
		
		if change < -0.6:
			if move_delay_reset == true:
				move_delay_timer = 0.0
				move_delay_reset = false
		
		last_move_dir = move_dir
	else:
		move_delay_reset = true
	
	if current_anim == "Run_loop":
		run_anim_pos = anim.current_animation_position/anim.current_animation_length
	
	if move_delay_timer > move_delay or move_delay == 0.0:
		C.mesh_angle_to = -last_move_dir.angle()-deg_to_rad(90)
	else:
		if C.is_on_floor():
			move_delay_timer += delta
		else:
			move_delay_timer = move_delay
	
	# If we are not on the floor, and nothing is playing, then play fallloop and queue land
	# for when we hit the ground.
	if not C.is_on_floor():
		if not anim.is_playing():
			play_anim("Fall_loop", .1)
			queue_anim("Land")
	# If we are on the floor and we have just jumped or we are falling then play Land
	else:
		
		if f.to_vec2(C.char_vel).length_squared() >= run_speed * var_scale * 0.75:
			if current_anim != "Run_loop":
				play_anim("Run_loop", 0.1)
				anim.seek(run_anim_pos, true)
		else:
			if current_anim == "Fall_loop":
				play_anim("Land", 0)
			elif current_anim == "Jump":
				play_anim("Land", .1)
			else:
				if current_anim == "Run_loop" or not anim.is_playing():
					play_anim("Idle_loop", 0.4)
	
	if C.is_on_floor() == true and on_floor_last_frame == false:
		audio.play("Land")
	
	on_floor_last_frame = C.is_on_floor()
	
	# smoothly transition our current movement direction to our desired movement direction
	var weight = .15
	C.char_vel.x = lerp(C.char_vel.x, move_dir.x, weight * delta * 60.0)
	C.char_vel.z = lerp(C.char_vel.z, move_dir.y, weight * delta * 60.0)



func enter():
	super()
	move_delay_reset = true
	last_move_dir = f.to_vec2(-rig.transform.basis.z)


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

func death():
	play_anim("Idle_loop")

func revive():
	play_anim("Idle_loop")
	last_move_dir = f.to_vec2(-rig.transform.basis.z)
