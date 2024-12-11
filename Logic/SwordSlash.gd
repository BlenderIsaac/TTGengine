extends "res://Logic/LOGIC.gd"

# Logic Type: MOVEMENT STATE
# Contains: Slash movement state

var next_combo = false
var combo_num = 0
var max_combo = 2
var lightsaber_hurt_per_frame = 20
var hit = 0
var our_prefix = "Sword"
var saber_sounds = ["SaberMove", "SaberMove", "SaberMove"]

#var track_speed = 7.0

var slash_times = [[0.49, 0.72], [0.2, 0.44], [0.42, 0.6]]
# 0.47 -> 0.69
# 0.20 -> 0.44
# 0.42 -> 0.6

var prev_activated = false
var attack_speed = 0.1
var knockbacks = [10.0, 10.0, 10.0]

func exclusive_physics(_delta):
	C.get_base_movement_state().freeze()
	
	var root_vel = C.get_root_vel(.1, .9)/_delta
	
	if anim.current_animation == "SwordIdleloop":
		
		if next_combo == true:
			swipe()
		else:
			slash_frozen = true
			reset_delay = reset_delay_max
	else:
		if not anim.current_animation.begins_with("Slash"):
			anim.play("SwordIdleloop")
	
	if slash_frozen:
		
		anim.play("Slash"+str(combo_num), 0)
		anim.seek(anim.current_animation_length, true)
		root_vel = Vector3()
		
		if reset_delay <= 0 or C.key_press("Jump"):
			slash_frozen = false
			C.reset_movement_state()
		
		reset_delay -= _delta
	
	if not C.is_on_floor():
		C.char_vel.y += C.get_base_movement_state().air_gravity*_delta*C.var_scale
	else:
		C.char_vel.y = C.get_base_movement_state().air_gravity*_delta*C.var_scale
	
	var track_vel = root_vel#*2
	#TODO: When we fix root_vel, track_vel should only change when root_vel is non-zero
	if f.is_character_valid(snapped_attack_target): #and root_vel.length() > 0:
		var extra_vel =(snapped_attack_target.global_position-C.global_position).normalized()*base_state.run_speed*C.var_scale*attack_speed
		extra_vel.y = 0
		
		track_vel = root_vel.rotated(Vector3.UP, -C.mesh_angle_to)
		track_vel.z *= 5
		track_vel = track_vel.rotated(Vector3.UP, C.mesh_angle_to)
		track_vel += extra_vel
		
		if snapped_attack_target.global_position.distance_to(C.global_position) < 1.2:
			track_vel = Vector3()
	
	C.set_velocity((C.char_vel+track_vel)+C.push_vel)
	C.move_and_slide()
	
	if not C.is_on_floor():
		C.reset_movement_state()
	
	C.mesh_angle_lerp(_delta, 0.2)


func block(_who_from):
	if C.has_logic("Stamina"):
		C.get_logic("Stamina").change_stamina(-3)

#func super_block(_who_from):
	#if C.has_logic("Stamina"):
		#C.get_logic("Stamina").change_stamina(-10)


func swipe():
	
	hit = 0
	find_opponent()
	
	var move_dir = C.get_move_dir()
	
	var move_angle = Vector2(-move_dir.x, move_dir.z).angle()+deg_to_rad(90)
	
	var angle_dif = abs(f.angle_to_angle(C.mesh_angle_to, move_angle))
	# if we don't have a target  or the angle to our target is greater than 90 degrees.
	
	if not snapped_attack_target or angle_dif < PI/2:
		if move_dir != Vector3():
			C.mesh_angle_to = move_angle
	
	if snapped_attack_target:
		if snapped_attack_target.has_method("warn"):
			snapped_attack_target.warn("sword", [self])
	
	combo_num += 1
	
	if combo_num > max_combo+1:
		combo_num = 1
	
	anim.play("Slash"+str(combo_num))
	anim.queue("SwordIdleloop")
	audio_player.play(saber_sounds[combo_num-1])
	next_combo = false


var snapped_attack_target = null
var snapped_attack_range = 5.0
var snapped_attack_cone = 1.3
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


var reset_delay = 0.0
var reset_delay_max = 0.2
var slash_frozen = false

func inclusive_physics(_delta):
	
	if C.weapon_prefix == our_prefix and prev_activated:
		
		if C.key_just_pressed("Fight") and not C.AI:
			
			if anim.current_animation.begins_with("Slash"):
				var anim_progress = anim.current_animation_position/anim.current_animation_length
				# anim_progress is between 0 and 1
				
				if anim_progress > .1:
					next_combo = true
			
			if slash_frozen:
				#if combo_num < max_combo+1:
				swipe()
				slash_frozen = false
			
			if C.is_in_base_movement_state():
				if C.is_on_floor():
					anim.play(our_prefix+"Idleloop", .1)
					combo_num = 0
					next_combo = true
					C.set_movement_state("SwordSlash")
	
	prev_activated = C.weapon_prefix == our_prefix


func doing_damage():
	var anim_progress = anim.current_animation_position/anim.current_animation_length
	var damage_start = 0.3
	var damage_end = 0.95
	
	if slash_times.size() > combo_num:
		damage_start = slash_times[combo_num-1][0]
		damage_end = slash_times[combo_num-1][1]
	
	if anim_progress > damage_start and anim_progress < damage_end:
		return true
	
	return false


func exclusive_process(_delta):
	
	if anim.current_animation.begins_with("Slash"):
		
		if doing_damage():
			if hit < lightsaber_hurt_per_frame:
				#$"../Sword".SwordExtras.scale.y = 2.0
				for opponent in $"../Sword".in_lightsaber:
					if not opponent == C:
						
						if opponent.has_method("take_knockback"):
							# change to variable on how much knockback they take
							
							opponent.take_knockback(Vector3(0, 0, -knockbacks[combo_num-1]).rotated(Vector3.UP, C.get_node("Mesh").rotation.y), self)
						
						if opponent.has_method("take_damage"):
							opponent.take_damage(1, C)
							audio_player.play("SaberSmack")
							$"../Sword".in_lightsaber.erase(opponent)
							hit += 1
		else:
			pass
			#$"../Sword".SwordExtras.scale.y = 1.0


var valid_damage_logics = ["SwordSlam"]
func exclusive_damage(_amount, _who_from=null):
	var damage_taken = false
	
	if _who_from != null:
		if "movement_state" in _who_from:
			if valid_damage_logics.has(_who_from.movement_state):
				C.generic_damage(_amount)
				damage_taken = true
			elif _who_from.movement_state == "SwordLunge":
				C.get_logic("Stamina").change_stamina(-7)
	else:
		C.generic_damage(_amount)
		damage_taken = true
	
	if _who_from and _who_from.is_in_group("projectile"):
		_who_from.deflect(C)
		#C.generic_damage(_amount)
		#damage_taken = true
	
	if !damage_taken:
		C.get_logic("Stamina").change_stamina(-2)
