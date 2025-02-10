extends "res://Logic/LOGIC.gd"

# Logic Type: Movement State
# Contains: Sliding switch and movement

var slide_speed = 14.0
var effect_speed = 2.0
var jump_logic = "Jump"
var last_slide_collision = null
var last_slide_normal = Vector3()

func inclusive_physics(_delta):
	slide_idx += _delta*60
	
	if should_slide():
		C.set_movement_state("Slide")
		C.char_vel.y = -5
		freeze_jump()


func freeze_jump():
	if jump_logic != "" and jump_logic != null:
		if C.logic_exists(jump_logic):
			var logic = C.get_logic(jump_logic)
			logic.air_time = 100
			logic.jumped = logic.jump_types.size()+1

var slide_vel = Vector3()
func exclusive_physics(_delta):
	
	freeze_jump()
	
#	var keep_sliding = false
#
#	if should_slide():
#		keep_sliding = true
	
	if not should_slide():#keep_sliding == false:
		
		anim.play(C.weapon_prefix+"Idleloop", .2)
		#C.take_knockback(slide_vel)
		
		C.reset_movement_state()
	else:
		
		if last_slide_normal:
			
			var new_vel = Vector3(0, 1, 0).slide(last_slide_normal).normalized()*-slide_speed
			new_vel.y -= 10
			
			
			var move = C.get_move_dir()
			new_vel += move*C.var_scale*effect_speed
			
			slide_vel.x = lerp(C.velocity.x, new_vel.x, .03)
			slide_vel.y = lerp(C.velocity.y, new_vel.y, .03)
			slide_vel.z = lerp(C.velocity.z, new_vel.z, .03)
			
			# add weapon prefix here eventually
			anim.play(C.weapon_prefix+"Slideloop", .2)
	
	
	var vel = slide_vel+C.char_vel+C.push_vel+C.knock_vel
	
	C.mesh_angle_to = Vector2(-vel.x, vel.z).angle()+deg_to_rad(90)
	
	C.set_velocity(vel)
	C.move_and_slide()
	
	C.mesh_angle_lerp(_delta, 0.2)


func align_mesh_with_y(xform, new_y):
	xform.basis.y = new_y
	xform.basis.x = xform.basis.z.cross(new_y)
	xform.basis = xform.basis.orthonormalized()
	
	return xform


func get_slide_normal():
	if C.get_node("Tail").is_colliding():
		
		#var col_point = C.get_node("Tail").get_collision_point()
		
		#print(C.get_node("Tail").get_collision_normal())
		
		return C.get_node("Tail").get_collision_normal()
	return null

func die(_variables=[]):
	slide_idx = max_slide

#func get_current_normal():
#	return get_slide_normal(last_slide_collision)
#
#
#func get_slide_normal(collision):
#	var normal = collision.get_normal()
#	return normal

var max_slide = 5
var slide_idx = 50
func should_slide():
	
	#CharacterBody3D.new().get_last_slide_collision()
	
	var ray = false
	var tail = C.get_node("Tail")
	var tail_range = 2
	
	tail.force_raycast_update()
	
	if tail.is_colliding():
		if C.standing_on("Slide"):
			if tail.get_collision_point().distance_to(tail.global_position) < tail_range:
				ray = true
	
	if C.is_on_floor():
		
		var slide_col = C.get_last_slide_collision()
		if slide_col:
			var collider = slide_col.get_collider()
			if collider and C.standing_on("Slide"):
				var normal = slide_col.get_normal()
				#var deg = rad_to_deg(normal.angle_to(Vector3.UP))
				
				if true:#deg < 90:
					last_slide_normal = normal
					last_slide_collision = slide_col
					slide_idx = 0
					return true
		
		if slide_idx < max_slide:
			return true
		
		if ray:
			return true
	
	
	return false
