extends "res://Logic/LOGIC.gd"

# Logic Type: MOVEMENT STATE
# Contains: Build state

@export var copy_air_gravity = true

# gravity override
@export var override_air_gravity = -6.0

var current_build = null

var valid_logics = ["Base", "Build"]

func initiate():
	C.weapon_prefix = ""

func inclusive_physics(_delta):
	if !C.AI and valid_logics.has(C.movement_state):
		if C.key_press("Special"):
			
			var eligible_build = null
			
			if current_build:
				eligible_build = current_build
			else:
				eligible_build = find_eligible_build()
			
			if eligible_build:
				anim.play("Build", 0.02)
				eligible_build.advance_next()
				
				current_build = eligible_build
				
				C.set_movement_state("Build")


func exclusive_physics(_delta):
	if !C.key_press("Special") or !is_instance_valid(current_build) or current_build.finished or current_build.global_position.distance_to(C.global_position) > current_build.build_range:
		current_build = null
		C.reset_movement_state()
	else:
		if not C.is_on_floor():
			C.char_vel.y += get_air_gravity()*_delta*C.var_scale
		else:
			C.char_vel.y = get_air_gravity()*_delta*C.var_scale
		
		var position_difference = (current_build.global_position-C.global_position)
		var position_differenceVec2 = Vector2(position_difference.x, position_difference.z)
		var optimal_positionVec2 = position_differenceVec2.normalized()*-current_build.build_range
		
		var optimal_differenceVec2 = optimal_positionVec2
		
		var move_dir = Vector3(optimal_differenceVec2.x, 0, optimal_differenceVec2.y)
		
		if C.global_position.distance_to(current_build.global_position) >= current_build.build_range*.9:
			move_dir = Vector3()
		
		C.set_velocity(C.char_vel+C.push_vel+C.knock_vel+move_dir)
		C.move_and_slide()
		
		var angle = Basis.looking_at(C.global_position-current_build.global_position).get_euler()
		
		C.mesh_angle_to = angle.y + PI
		
		C.get_node("Mesh").rotation.y = lerp_angle(C.get_node("Mesh").rotation.y, C.mesh_angle_to, 0.2)
		C.get_node("Mesh").rotation.y -= deg_to_rad(int(rad_to_deg(C.get_node("Mesh").rotation.y)/360)*360)
		
		base_state.freeze()


func find_eligible_build():
	for build in get_tree().get_nodes_in_group("Build"):
		if C.global_position.distance_to(build.global_position) < build.build_range:
			if not build.finished:
				return build
	
	return null


func get_air_gravity():
	if copy_air_gravity and "air_gravity" in base_state:
		return base_state.air_gravity
	else:
		return override_air_gravity
