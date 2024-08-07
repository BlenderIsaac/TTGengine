extends "res://Logic/BaseAI.gd"

# Logic Type: AI logic
# Contains: Logic for gun characters


func _init():
	AI_desired_distance = 5
	AI_max_distance = 10
	
	player_max_distance = 6
	
	logic_path = "Logic/ProjectileWeapon"
	
	attack_type = "Gun"
	
	valid_logics = ["Base", "Jump"]


func _ready():
	find_logic()
	reset_target_delay()

#func warning_aoe(from):
	#var f_pos = f.to_vec2(from[0].global_position)
	#var s_pos = f.to_vec2(global_position)
	#
	#var jump_state = C.get_logic("Jump")
	#
	#if f_pos.distance_to(s_pos) <= 3.5:
		#if (C.is_in_base_movement_state() or C.movement_state == "Jump"):
			#if jump_state.can_start_jump():
				#
				#C.ai_to = C.position
				#C.target = C.position
				#
				#C.set_movement_state("Jump")
				#jump_state.click_jump()


func can_attack(character):
	if logic.can_shoot():
		if logic.char_not_obstructed(character):
			return true
	return false


func attack(character):
	logic.shoot(logic.get_gun_rot_to_char(character), character)

