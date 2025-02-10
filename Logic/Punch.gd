extends "res://Logic/LOGIC.gd"

# Logic Type: MOVEMENT STATE
# Contains: Slash movement state

var next_combo = false
var combo_num = 0
var max_combo = 2
var hit = 0
var our_prefix = ""

var stamina_damage = 1

var prev_pose = Vector3()
#var prev_activated = false

var valid_movement_states = ["Base", "Dodge"]
var knockbacks = [3.0, 3.0, 3.0]

var punch_move_speed = 30

func exclusive_physics(_delta):
	C.get_base_movement_state().freeze()
	
	if anim.current_animation == "Idleloop":
		
		if next_combo == true and combo_num < max_combo+1:
			hit = 0
			find_opponent()
			
			var move_dir = C.get_move_dir()
			
			var move_angle = Vector2(-move_dir.x, move_dir.z).angle()+deg_to_rad(90)
			
			var angle_dif = abs(f.angle_to_angle(C.mesh_angle_to, move_angle))
			# if we don't have a target  or the angle to our target is greater than 90 degrees.
			
			if not snapped_attack_target or angle_dif < PI/2:
				if move_dir != Vector3():
					C.mesh_angle_to = move_angle
			
			anim.play("Punch"+str(combo_num+1))
			
			
			if snapped_attack_target:
				if snapped_attack_target.has_method("warn"):
					snapped_attack_target.warn("punch", [self])
			
			#anim.queue("Idleloop")
			next_combo = false
			combo_num += 1
		else:
			C.reset_movement_state()
	else:
		if not anim.current_animation.begins_with("Punch"):
			anim.play("Idleloop", .3)
	
	if not C.is_on_floor():
		C.char_vel.y += C.get_base_movement_state().air_gravity*_delta*C.var_scale
	else:
		C.char_vel.y = C.get_base_movement_state().air_gravity*_delta*C.var_scale
	
	var root_vel = Vector3()
	
	var bone_pos = $"../../Mesh/Armature/Skeleton3D".get_bone_pose_position(0)-prev_pose
	var anim_progress = anim.current_animation_position/anim.current_animation_length
	
	if anim_progress >= .1 and anim_progress <= .9:
		root_vel = bone_pos.rotated(Vector3.UP, $"../../Mesh".rotation.y)
	
	# get a test move speed
	var vel = Vector3(0, 0, -punch_move_speed*C.var_scale*_delta).rotated(Vector3.UP, C.get_node("Mesh").rotation.y)
	
	C.set_velocity((C.char_vel+root_vel/_delta)+C.push_vel+vel)
	C.move_and_slide()
	
	if not C.is_on_floor():
		C.reset_movement_state()
	
	C.mesh_angle_lerp(_delta, 0.2)
	
	# setup this for the next frame
	prev_pose = $"../../Mesh/Armature/Skeleton3D".get_bone_pose_position(0)


var snapped_attack_target = null
var snapped_attack_range = 1.3
var snapped_attack_cone = 2
func find_opponent():
	
	snapped_attack_target = null
	
	var in_cone = []
	
	for destroyable in get_tree().get_nodes_in_group("AttackLockOn"):
		if not destroyable == C and not destroyable.dead:
			var target_pos2 = destroyable.global_position
			var self_pos2 = C.global_position
			
			var rot_dir = Basis.looking_at(target_pos2-self_pos2, Vector3.UP).get_euler().y
			
			var rot_to = abs(f.angle_to_angle(C.mesh_angle_to, rot_dir))
			
			if rot_to <= snapped_attack_cone:
				var dist = target_pos2.distance_to(self_pos2)
				in_cone.append({"d" : destroyable, "rot_to" : rot_to, "dist" : dist})
	
	var most_desirable = null
	var backup = null
	for opponent in in_cone:
		if opponent.dist <= snapped_attack_range:
			
			var desirability = (opponent.dist/snapped_attack_range) + (opponent.rot_to/snapped_attack_cone)
			
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
			var target_pos2 = final_descision.d.global_position
			var self_pos2 = C.global_position
			
			var rot_dir = Basis.looking_at(target_pos2-self_pos2, Vector3.UP).get_euler().y
			
			snapped_attack_target = final_descision.d
			
			C.get_node("Mesh").rotation.y = rot_dir
			C.mesh_angle_to = rot_dir


func inclusive_physics(_delta):
	
	#if C.weapon_prefix == our_prefix:# and prev_activated:
		if C.key_just_pressed("Fight") and not C.AI:
			
			if anim.current_animation.begins_with("Punch"):
				var anim_progress = anim.current_animation_position/anim.current_animation_length
				# anim_progress is between 0 and 1
				if anim_progress > .1:
					next_combo = true
			
			find_opponent()
			
			if snapped_attack_target:
				if valid_movement_states.has(C.movement_state):
					if C.is_on_floor():
						anim.play("Idleloop", .3)
						combo_num = 0
						next_combo = true
						C.set_movement_state("Punch")
						C.weapon_prefix = our_prefix
	
	#prev_activated = C.weapon_prefix == our_prefix


func exclusive_process(_delta):
	if anim.current_animation.begins_with("Punch"):
		var anim_progress = anim.current_animation_position/anim.current_animation_length
		
		if anim_progress > 0.9 and anim_progress < 1:
			if snapped_attack_target and is_instance_valid(snapped_attack_target):
				if snapped_attack_target.global_position.distance_to(C.global_position) < snapped_attack_range:
					
					audio_player.play("Punch")
					
					if snapped_attack_target.has_method("take_knockback"):
						var knockback = Vector3(0, 0, -knockbacks[combo_num-1]).rotated(Vector3.UP, C.get_node("Mesh").rotation.y)
						snapped_attack_target.take_knockback(knockback)
					
					if snapped_attack_target.has_method("take_damage"):
						snapped_attack_target.take_damage(f.Damage.new(1, C))
						
						hit += 1
					
					snapped_attack_target = null
			pass # add hurt code here.
#				for opponent in $"../Sword".in_lightsaber:
#					if not opponent == C:
#
#						if opponent.has_method("take_knockback"):
#							# change to variable on how much knockback they take
#
#							opponent.take_knockback(Vector3(0, 0, -knockbacks[combo_num-1]).rotated(Vector3.UP, C.get_node("Mesh").rotation.y))
#
#						if opponent.has_method("take_damage"):
#							opponent.take_damage(1, C)
#							$"../Sword".in_lightsaber.erase(opponent)
#							hit += 1
						
						

#func WEAPON_AI():
	#pass

func exclusive_damage(_amount, _who_from=null):
	pass
