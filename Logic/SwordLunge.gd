extends "res://Logic/LOGIC.gd"

# Logic Type: MOVEMENT STATE
# Contains: Lunge movement state

# lunge variables
var lunge_speed = 1.5
var lunge_jumpspeed = 0.75
var lunge_gravity = -10

var lunge_target = null

var move_dir = Vector3()

var knockback = 7.0

func exclusive_physics(_delta):
	C.get_base_movement_state().freeze()
	
	if lunge_target and is_instance_valid(lunge_target) and lunge_target.dead != true:
		var target_pos2 = lunge_target.global_position
		var self_pos2 = C.global_position
		
		var rot_dir = Basis.looking_at(target_pos2-self_pos2, Vector3.UP).get_euler().y
		
		C.mesh_angle_to = rot_dir
	
	C.mesh_angle_lerp(_delta, 0.1)
	
	move_dir = Vector3(0, 0, -1).rotated(Vector3.UP, C.get_node("Mesh").rotation.y)
	move_dir = move_dir.normalized()*lunge_speed*C.var_scale
	
	if C.is_on_floor():
		
		# Reset movement if we have hit the ground
		move_dir = Vector3()
		
		# Check if the animation is over and if it is end lunging
		if anim.current_animation == "SwordIdleloop":
			C.reset_movement_state()
		# If we are on the floor, have hit the ground, and are at a certain point in the animation damage peeps
		if anim.current_animation == "LungeHit":
			var anim_progress = anim.current_animation_position/anim.current_animation_length
			
			if anim_progress >= 0 and anim_progress < 0.3:
				for opponent in $"../Sword".in_lightsaber:
					if not opponent == C:
						if opponent.has_method("take_knockback"):
							# change to knockback variable
							opponent.take_knockback(Vector3(0, 0, -knockback).rotated(Vector3.UP, C.get_node("Mesh").rotation.y))
						
						if opponent.has_method("take_damage"):
							opponent.take_damage(1, C)
							$"../Sword".in_lightsaber.erase(opponent)
		
		# If we have hit the ground play LungeHit and queue base so we know when its over
		if not ["LungeHit", "SwordIdleloop"].has(anim.current_animation):
			anim.play("LungeHit", 0)
			anim.queue("SwordIdleloop")
			audio_player.play("SaberLunge")
	
	# Calculate gravity and respawn position
	if not C.is_on_floor():
		C.char_vel.y += lunge_gravity*_delta*C.var_scale
	else:
		C.char_vel.y = lunge_gravity*_delta*C.var_scale
	
	C.set_velocity(C.char_vel+move_dir+C.push_vel)
	C.move_and_slide()


func initiate():
	
	C.mesh_angle_to = get_mesh_angle_to()
	audio_player.play("LungeInitiate")
	anim.play("LungeInitiate")
	anim.queue("Lungeloop")
	C.char_vel.y = lunge_jumpspeed*C.var_scale
	lunge_target = null
	
	find_opponent()
	
	if lunge_target:
		if lunge_target.has_method("warn"):
			lunge_target.warn("sword_lunge", [self])


func get_sword():
	pass


func block(_who_from):
	if C.has_logic("Stamina"):
		C.get_logic("Stamina").change_stamina(-100)


func get_mesh_angle_to():
	# we need to do something different if its an AI
	var move_dir_new = C.get_move_dir()
	var moved = (move_dir_new != Vector3())
	
	var mesh_angle_to = Vector2(-move_dir_new.x, move_dir_new.z).angle()+deg_to_rad(90)
	
	if moved:
		return mesh_angle_to
	else:
		return C.mesh_angle_to


var lunge_snap_range = 5
var lunge_snap_cone = 1.6
func find_opponent():
	
	var _target = null
	
	var in_cone = []
	
	for destroyable in get_tree().get_nodes_in_group("AttackLockOn"):
		if not destroyable == C and not destroyable.dead:
			var target_pos2 = destroyable.global_position
			var self_pos2 = C.global_position
			
			var rot_dir = Basis.looking_at(target_pos2-self_pos2, Vector3.UP).get_euler().y
			
			var rot_to = abs(f.angle_to_angle(C.mesh_angle_to, rot_dir))
			
			if rot_to <= lunge_snap_cone:
				var dist = target_pos2.distance_to(self_pos2)
				in_cone.append({"d" : destroyable, "rot_to" : rot_to, "dist" : dist})
	
	var most_desirable = null
	var backup = null
	for opponent in in_cone:
		if opponent.dist <= lunge_snap_range:
			
			var desirability = (opponent.dist/lunge_snap_range) + (opponent.rot_to/lunge_snap_cone)
			
			if opponent.d.is_in_group("Character"):
				if opponent.d.player:
					desirability *= 2
			
			opponent["desirability"] = desirability
			
			if not backup:
				backup = opponent
				most_desirable = opponent
			else:
				# if there is something to compare to
				var their_des = most_desirable.desirability
				var our_des = desirability
				
				if our_des < their_des:
					most_desirable = opponent
					backup = opponent
	
	if backup:
		var final_descision = backup
		if most_desirable:
			final_descision = most_desirable
		
		if final_descision:
			lunge_target = final_descision.d
			
			var target_pos2 = final_descision.d.global_position
			var self_pos2 = C.global_position
			
			var rot_dir = Basis.looking_at(target_pos2-self_pos2, Vector3.UP).get_euler().y
			
			_target = final_descision.d
			
			C.get_node("Mesh").rotation.y = rot_dir
			C.mesh_angle_to = rot_dir



func vector3to2(vector3):
	return Vector2(vector3.x, vector3.z)
