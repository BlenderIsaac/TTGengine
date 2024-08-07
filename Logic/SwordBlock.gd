extends "res://Logic/LOGIC.gd"

# Logic Type: MOVEMENT STATE
# Contains: Blocking movement state

# variable for how long since we released fight. This is for the delay between letting go and then going back to base movement.
var delay_released_fight = 0.0
var max_delay_before_undoing = 0.5
var max_delay_before_cancel = 0.1
# variable for how long since we started tapping fight. This is so we can deflect.
var time_since_start = 0.0
# variable in seconds for how long we can deflect after pressing F
var deflect_time = 0.3
# variable in seconds for how much deflect time we gain after successfully deflecting
var extra_deflect_time = 0.1
# variable in seconds for how long we can super deflect after pressing F
var superdeflect_time = 0.05

var deflected_bullet_rot = null
var blocks_to_choose = ["SwordBlock1loop", "SwordBlock2loop", "SwordBlock3loop"]
var reflects_to_choose = ["SwordBlock1Deflect", "SwordBlock2Deflect", "SwordBlock3Deflect"]

var volatile_timer = 0.0
var volatile_delay = 0.15
var volatile = false

var our_logic = "Sword"
var fight_logic = "SwordSlash"

var states_to_block = ["SwordLunge", "SwordSlash", "SwordSlam", "Stamina"]


func initiate():
	C.get_logic(our_logic).draw_weapon()

func exclusive_physics(_delta):
	# reset move_dir on our base movement state
	C.get_base_movement_state().freeze()
	
	if volatile:
		if volatile_timer <= 0.0:
			volatile = false
		else:
			if not C.key_press("Fight"):
				C.set_movement_state(fight_logic)
				
				volatile = false
				anim.play(C.get_logic(fight_logic).our_prefix+"Idleloop", .1)
				C.get_logic(fight_logic).combo_num = 0
				C.get_logic(fight_logic).next_combo = true
	
	volatile_timer -= _delta
	
	if not blocks_to_choose.has(anim.current_animation):
		if not reflects_to_choose.has(anim.current_animation):
			new_block()
	
	if C.key_press("Fight") and not C.AI:
		if delay_released_fight > 0.0:
			new_block(true)
			time_since_start = 0.0
		delay_released_fight = 0.0
	else:
		if !C.AI:
			delay_released_fight += _delta
			if delay_released_fight > max_delay_before_undoing:
				anim.play(C.weapon_prefix+"Idleloop", .2)
				C.reset_movement_state()
		
		if delay_released_fight > max_delay_before_cancel:
			var cancel_keys = ["Jump", "Special"]
			
			for key in cancel_keys:
				if C.key_press(key) and not C.AI:
					C.reset_movement_state()
					anim.play("NULL", .4)
					break
	
	
	if C.is_on_floor():
		# Calculate Gravity
		C.char_vel.y = C.get_base_movement_state().air_gravity*_delta*C.var_scale
	else:
		C.char_vel.y += C.get_base_movement_state().air_gravity*_delta*C.var_scale
	
	
	time_since_start += _delta
	
	if deflected_bullet_rot:
		C.mesh_angle_to = deflected_bullet_rot.y
	
	C.mesh_angle_lerp(_delta, 0.4)
	
	# Set the velocity
	C.set_velocity(C.char_vel+C.push_vel+C.knock_vel)
	C.move_and_slide()

var lead_up = false
func inclusive_physics(_delta):
	
	if C.key_press("Fight"):
		if states_to_block.has(C.movement_state):
			lead_up = true
	
	if C.weapon_prefix == C.get_logic(our_logic).our_prefix and C.PHYSkey_just_pressed("Fight"):
		if C.movement_state == C.base_state:
			lead_up = true
			volatile = true
			volatile_timer = volatile_delay
	
	if C.is_in_base_movement_state():
		if lead_up == true and C.key_press("Fight") and C.is_on_floor():
			C.set_movement_state("SwordBlock")
			
			if deflected_bullet_rot:
				deflected_bullet_rot.y = C.mesh_angle_to
		
		lead_up = false



var prev_block = null
func new_block(reflecting=true):
	
	audio_player.play("SaberMove")
	
	var reflects_avaliable = reflects_to_choose.duplicate()
	var blocks_avaliable = blocks_to_choose.duplicate()
	
	if prev_block:
		var index = 0
		for i in reflects_avaliable:
			if i == prev_block:
				reflects_avaliable.remove_at(index)
				blocks_avaliable.remove_at(index)
				break
			
			index += 1
	
	var new_block_idx = randi_range(0, blocks_avaliable.size()-1)
	
	if reflecting:
		anim.clear_queue()
		
		anim.play(reflects_avaliable[new_block_idx], 0.06)
		anim.queue(blocks_avaliable[new_block_idx])
	else:
		anim.play(blocks_avaliable[new_block_idx], 0.06)
	
	prev_block = reflects_avaliable[new_block_idx]


func exclusive_knockback(_amount, _who_from=null):
	var t = true
	
	if _who_from and _who_from.is_in_group("projectile"):
		if (C.key_press("Fight") and not C.AI) or C.AI:
			t = false
			
			if time_since_start < superdeflect_time:pass
			elif time_since_start < deflect_time:pass
			else:
				C.generic_knockback(_amount*0.4)
	
	if t:
		C.generic_knockback(_amount)


var valid_damage_logics = ["SwordSlam"]
func exclusive_damage(_amount, _who_from=null):
	
	if _who_from != null:
		
		if "movement_state" in _who_from:
			if valid_damage_logics.has(_who_from.movement_state):
				C.generic_damage(_amount)
			
			if _who_from.movement_state == "SwordSlash":
				var SwordSlash = _who_from.get_logic("SwordSlash")
				
				if time_since_start < superdeflect_time:
					if SwordSlash.has_method("super_block"):
						audio_player.play("SaberSaber")
						SwordSlash.super_block(self)
					else:
						audio_player.play("SaberSaber")
						SwordSlash.block(self)
					
					# add something else that is special here
					change_stamina(5)
				elif time_since_start < deflect_time:
					#C.take_knockback(Vector3(0, 0, .5).rotated(Vector3.UP, _who_from.rotation.y))
					
					SwordSlash.block(self)
					
					change_stamina(2)
					
					time_since_start -= extra_deflect_time
					
					if time_since_start < superdeflect_time:
						time_since_start = superdeflect_time
					
					
				else:
					change_stamina(-3)
			
			elif _who_from.movement_state == "SwordLunge":
				var SwordLunge = _who_from.get_logic("SwordLunge")
				
				if time_since_start < superdeflect_time:
					if SwordLunge.has_method("super_block"):
						audio_player.play("SaberSaber")
						SwordLunge.super_block(self)
					else:
						audio_player.play("SaberSaber")
						SwordLunge.block(self)
					
					change_stamina(100)
				elif time_since_start < deflect_time:
					#C.take_knockback(Vector3(0, 0, .5).rotated(Vector3.UP, _who_from.rotation.y))
					
					SwordLunge.block(self)
					
					change_stamina(-5)
					
					time_since_start -= extra_deflect_time
					
					if time_since_start < superdeflect_time:
						time_since_start = superdeflect_time
					
				else:
					change_stamina(-100)
			else:
				change_stamina(-_amount)
		
		elif _who_from.is_in_group("projectile"):
			if (C.key_press("Fight") and not C.AI) or C.AI:
				deflected_bullet_rot = _who_from.rotation
				if time_since_start < superdeflect_time:
					if _who_from.has_method("super_reflect"):
						audio_player.play("SaberBullet") # change to different sound effect
						_who_from.super_reflect(C)
					else:
						audio_player.play("SaberBullet")
						_who_from.reflect(C)
					
					# add something else that is special here
					change_stamina(5)
				elif time_since_start < deflect_time:
					#C.take_knockback(Vector3(0, 0, .5).rotated(Vector3.UP, _who_from.rotation.y))
					_who_from.reflect(C)
					
					time_since_start -= extra_deflect_time
					
					if time_since_start < superdeflect_time:
						time_since_start = superdeflect_time
					
					change_stamina(1)
				else:
					
					# get this knockback value from _who_from instead
					#C.take_knockback(Vector3(0, 0, 1).rotated(Vector3.UP, _who_from.rotation.y))
					audio_player.play("SaberBullet")
					
					_who_from.deflect(C)
					change_stamina(-1)
				
				new_block(false)
			else:
				C.generic_damage(_amount)
		else:
			C.generic_damage(_amount)
	else:
		C.generic_damage(_amount)


func change_stamina(value):
	if C.has_logic("Stamina"):
		C.get_logic("Stamina").change_stamina(value)
