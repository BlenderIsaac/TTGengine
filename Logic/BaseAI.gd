extends "res://Logic/LOGIC.gd"

# Logic Type: AI logic
# Contains: Logic for gun characters

var target_check_delay_max = .5
# time before we check for target
var current_delay = 0

var current_following
var current_target

var AI_desired_distance = 5
var AI_max_distance = 10

var player_max_distance = 6

var peep_desired_distance = 3
var peep_max_distance = 5

var jump_save_target = null

var weapons = []
var current_weapon = 0

# Temp so it leaves me alone
var logic_path = ""
var logic = null
@export var attack_type = "None"
func find_logic():pass
# temp end


var valid_logics = ["Base", "Jump"]

func _ready():
	for lgc in get_parent().get_children():
		if lgc.has_method("WEAPON_AI"):
			weapons.append(lgc)
	
	reset_target_delay()

func _process(delta):
	
	if C.AI:# and valid_logics.has(C.movement_state):
		if not C.player: #TEMP, replace with faction code
			enemy_ai(delta)
		else:
			party_ai(delta)


func party_ai(delta):
	
	C.AI_desired_distance = peep_desired_distance
	C.AI_max_distance = peep_max_distance
	
	current_delay -= delta
	
	# make sure our current target isn't dead, and if so stop targeting
	if current_target != null and (!is_instance_valid(current_target) or current_target.dead):
		current_target = null
	
	# Check if we are ready to attack someone
	if current_target and is_instance_valid(current_target):
		
		C.target = current_target.global_position
		
		if current_following:
			if C.global_position.distance_to(current_target.global_position) > player_max_distance:
				C.target = current_following.global_position
		
		if C.is_on_floor() and valid_logics.has(C.movement_state):
			
			jump_save_target = C.global_position
			
			if has_weapon():
				weapons[current_weapon].draw_weapon()
				
				if can_attack(current_target):
					attack(current_target)
				
				var rot = get_rot_to_char(current_target)
				C.mesh_angle_to = rot.y + PI
		
		else:
			
			if jump_save_target:
				if C.is_in_base_movement_state():
					var jump = C.get_logic("Jump")
					
					if jump.can_continue_jumping():
						C.ai_to = jump_save_target
						C.set_movement_state("Jump")
		
	elif current_following:
		C.target = current_following.global_position
	
	# If we don't have a current target
	if not current_target:
		
		if has_weapon():
			weapons[current_weapon].store_weapon()
			
			if current_delay <= 0:
				reset_target_delay()
				
				var new_t = find_target(false, true)
				
				if new_t != null:
					current_target = new_t
	
	# look for someone to follow
	if !f.is_character_valid(current_following):
		var play_t = find_target(true, false, current_following != null)
		
		if play_t != null:
			current_following = play_t

func enemy_ai(delta):
	C.AI_desired_distance = AI_desired_distance
	C.AI_max_distance = AI_max_distance
	
	# temporary bad guy code
	if current_target != null and (!is_instance_valid(current_target) or current_target.dead):
		current_target = null
	
	if current_target:
		
		C.target = current_target.global_position
		
		if C.is_on_floor() and valid_logics.has(C.movement_state):
			
			jump_save_target = C.global_position
			
			if has_weapon():
				weapons[current_weapon].draw_weapon()
				
				if can_attack(current_target):
					attack(current_target)
				
				var rot = get_rot_to_char(current_target)
				C.mesh_angle_to = rot.y + PI
			
		else:
			if jump_save_target:
				if C.is_in_base_movement_state():
					var jump = C.get_logic("Jump")
					
					if jump.can_continue_jumping():
						C.ai_to = jump_save_target
						C.set_movement_state("Jump")
		
	else:
		
		if has_weapon():
			weapons[current_weapon].store_weapon()
			
			current_delay -= delta
			if current_delay <= 0:
				reset_target_delay()
				var new_t = find_target(true, false)
				
				if new_t == null:
					new_t = find_target(true, true)
				
				if new_t:
					current_target = new_t


func can_attack(_character):
	return false


func attack(_character):
	pass


func reset_target_delay():
	current_delay = target_check_delay_max


var activated = false
var AI_activate_range = 30
func find_target(player, AI, in_range_of_follow=false): # add faction as a point to it
	
	var targets = []
	
	for character in get_tree().get_nodes_in_group("Character"):
		
		if character.player == player or player == null:
			if character.AI == AI or AI == null:
				if character.dead == false:
					
					var char_range = C.global_position.distance_to(character.global_position)
					
					if char_range <= AI_activate_range:
						if in_range_of_follow == false or char_range <= player_max_distance:
							
							if character != self:
								targets.append(character)
	
	
	
	var most_des = null
	for target in targets:
		if most_des:
			if a_more_des_than_b(target, most_des):
				most_des = target
		else:
			most_des = target
	
	return most_des

func has_weapon():
	return !weapons.is_empty()

func a_more_des_than_b(a, b):
	if get_desirability(a) > get_desirability(b):
		return true
	return false


func get_desirability(character):
	var des = 0
	
	var dist_to_char = C.global_position.distance_to(character.global_position)
	
	des = 1/dist_to_char
	
	return des


func get_rot_to_char(c):
	var targetPos = c.aim_pos+c.global_position
	
	# Get the direction vector from the source to the target
	var direction = (C.global_position-targetPos).normalized()
	
	# Calculate the rotation that points from the source to the target
	
	var rotationBasis = Basis.looking_at(direction, Vector3(0, 1, 0))
	var rot = rotationBasis.get_euler()
	
	return rot

