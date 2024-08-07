extends "res://Logic/LOGIC.gd"

# Logic Type: MOVEMENT STATE
# Contains: Air Slash movement state

var lightsaber_hurt_per_frame = 20
var hit = 0
var weapon_logic = "Sword"
var saber_sound = "SaberMove"

var prev_activated = false

var knockback = 10.0

func exclusive_physics(_delta):
	
	if not C.is_on_floor():
		C.char_vel.y += C.get_base_movement_state().air_gravity*_delta*C.var_scale
	else:
		C.char_vel.y = C.get_base_movement_state().air_gravity*_delta*C.var_scale
	
	C.set_velocity(C.char_vel+C.push_vel+base_state.move_dir)
	C.move_and_slide()
	
	if C.is_on_floor():
		anim.play(C.weapon_prefix+"Land", .1)
		C.reset_movement_state()
	
	if anim.current_animation == "AirSlash":
		if anim.current_animation_position >= anim.current_animation_length-.001:
			anim.play(C.weapon_prefix+"Fallloop", .3)
			C.reset_movement_state()
	
	C.mesh_angle_lerp(_delta, 0.2)


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
	
	anim.play("AirSlash", .1)
	audio_player.play(saber_sound)
	
	if snapped_attack_target:
		if snapped_attack_target.has_method("warn"):
			snapped_attack_target.warn("sword", [self])


var snapped_attack_target = null
var snapped_attack_range = 3
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


func inclusive_physics(_delta):
	
	if C.weapon_prefix == C.get_logic(weapon_logic).our_prefix and prev_activated:
		
		if C.key_just_pressed("Fight") and not C.AI:
			
			if C.movement_state == "Jump":
				C.set_movement_state("AirSlash")
	
	prev_activated = C.weapon_prefix == C.get_logic(weapon_logic).our_prefix


func exclusive_process(_delta):
	if anim.current_animation == "AirSlash":
		var anim_progress = anim.current_animation_position/anim.current_animation_length
		
		if hit < lightsaber_hurt_per_frame:
			if anim_progress > 0.15 and anim_progress < 0.95:
				for opponent in $"../Sword".in_lightsaber:
					if not opponent == C:
						
						if opponent.has_method("take_knockback"):
							# change to variable on how much knockback they take
							opponent.take_knockback(Vector3(0, 0, -knockback).rotated(Vector3.UP, C.get_node("Mesh").rotation.y))
						
						if opponent.has_method("take_damage"):
							opponent.take_damage(1, C)
							$"../Sword".in_lightsaber.erase(opponent)
							hit += 1


func initiate():
	C.get_logic(weapon_logic).draw_weapon()
	swipe()


var valid_damage_logics = ["SwordSlam", "SwordLunge"]
func exclusive_damage(_amount, _who_from=null):
	
	if _who_from != null:
		if "movement_state" in _who_from:
			if valid_damage_logics.has(_who_from.movement_state):
				C.generic_damage(_amount)
	else:
		C.generic_damage(_amount)
	
	if _who_from and _who_from.is_in_group("projectile"):
		_who_from.deflect(C)


