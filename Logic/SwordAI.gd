extends "res://Logic/BaseAI.gd"

# Logic Type: AI logic
# Contains: Logic for sword characters

var force_weapon_out = []

var sword_range = 3.2

var logic_slash_path = "SwordSlash"
var logic_block_path = "SwordBlock"

var slash_logic = null
var block_logic = null

var block_states = ["Base"]

func _init():
	logic_path = "Sword"
	
	valid_logics = ["Jump", "Base", "SwordSlash", "SwordBlock"]
	
	AI_desired_distance = .1
	AI_max_distance = 2
	player_max_distance = 10
	
	attack_type = "Sword"

func _ready():
	find_logics()
	reset_target_delay()

func _process(delta):
	
	find_logics()
	
	block_cooldown -= delta
	
	if C.AI and !C.dead and valid_logics.has(C.movement_state):
		
		if block_cooldown > 0.0:
			if block_states.has(C.movement_state) and C.get_logic("Stamina").stamina > 0:
				if C.movement_state != "SwordBlock":
					C.get_logic("SwordBlock").delay_released_fight = 0.0
					C.set_movement_state("SwordBlock")
		else:
			if C.movement_state == "SwordBlock":
				anim.play(C.weapon_prefix+"Idleloop", .2)
				C.reset_movement_state()
		
		if not C.player: #TODO: replace with faction code
			
			C.AI_desired_distance = AI_desired_distance
			C.AI_max_distance = AI_max_distance
			
			# temporary bad guy code
			if current_target and current_target.dead:
				current_target = null
			
			if current_target:
				
				C.target = current_target.global_position
				
				if C.is_on_floor() and valid_logics.has(C.movement_state):
					
					logic.draw_weapon()
					
					if can_attack(current_target):
						attack(current_target)
					
					var rot = get_rot_to_char(current_target)
					C.mesh_angle_to = rot.y + PI
			else:
				
				if block_cooldown <= 0.0:logic.store_weapon()
				
				
				current_delay -= delta
				if current_delay <= 0:
					reset_target_delay()
					var new_t = find_target(true, false)
					
					if new_t == null:
						new_t = find_target(true, true)
					
					if new_t:
						current_target = new_t
		else:
			
			C.AI_desired_distance = peep_desired_distance
			C.AI_max_distance = peep_max_distance
			
			# temporary good guy ai code
			
			current_delay -= delta
			
			if !character_exists(current_target):
				current_target = null
			
			
			if character_exists(current_target):
				C.target = current_target.global_position
				
				if current_following:
					if C.global_position.distance_to(current_target.global_position) > player_max_distance:
						C.target = current_following.global_position
				
				if C.is_on_floor() and valid_logics.has(C.movement_state):
					
					logic.draw_weapon()
					
					if can_attack(current_target):
						attack(current_target)
					
					var rot = get_rot_to_char(current_target)
					C.mesh_angle_to = rot.y + PI
				
			elif current_following:
				C.target = current_following.global_position
				
			if not current_target:
				
				if block_cooldown <= 0.0 and force_weapon_out.is_empty():
					logic.store_weapon()
				
				if current_delay <= 0:
					reset_target_delay()
					
					var new_t = find_target(false, true)
					
					if new_t != null:
						current_target = new_t
			
			
			var play_t = find_target(true, false, current_following != null)
			
			if play_t != null:
				current_following = play_t


func can_attack(character):
	if C.global_position.distance_to(character.global_position) < sword_range:
		if C.weapon_prefix == slash_logic.our_prefix and slash_logic.prev_activated:
			# TODO: Create better fix for this. For reference this is to fix characters on stairs not fighting
			if abs(C.global_position.y-character.global_position.y) < .1:
				return true
	
	return false

func attack(_character):
	
	#to_blocking = true
	if anim.current_animation.begins_with("Slash"):
		var anim_progress = anim.current_animation_position/anim.current_animation_length
		# anim_progress is between 0 and 1
		if anim_progress > .1:
			slash_logic.next_combo = true
	
	if C.is_in_base_movement_state():
		if C.is_on_floor():
			anim.play("SwordIdleloop")
			slash_logic.combo_num = 0
			slash_logic.next_combo = true
			C.set_movement_state("SwordSlash")


func find_logics():
	if not slash_logic:
		slash_logic = C.get_node_or_null("Logic/"+logic_slash_path)
		logic = C.get_node_or_null("Logic/"+logic_path)
		block_logic = C.get_node_or_null("Logic/"+logic_block_path)


func get_rot_to_char(c):
	var targetPos = c.aim_pos+c.global_position
	
	# Get the direction vector from the source to the target
	var direction = (C.global_position-targetPos).normalized()
	
	# Calculate the rotation that points from the source to the target
	
	var rotationBasis = Basis.looking_at(direction, Vector3(0, 1, 0))
	var rot = rotationBasis.get_euler()
	
	return rot


var block_cooldown = 0.0
func warning_projectile(from):
	block_cooldown = 5.0
	
	if from.size() > 0:
		var target = from[0]
		
		var dist = target.global_position.distance_to(C.global_position)
		
		var time = dist/4
		
		block_cooldown = time


func warning_punch(_from):
	block_cooldown = 0.5


func warning_sword(from):
	block_cooldown = 5.0
	
	if from.size() > 0:
		
		var time = 2.0
		
		block_cooldown = time


func warning_sword_lunge(from):
	warning_sword(from)


func warning_aoe(from):
	var f_pos = f.to_vec2(from[0].global_position)
	var s_pos = f.to_vec2(global_position)
	
	var jump_state = C.get_logic("Jump")
	
	if f_pos.distance_to(s_pos) <= 3.5:
		if (C.is_in_base_movement_state() or C.movement_state == "Jump"):
			if jump_state.can_start_jump():
				
				C.ai_to = C.position
				C.target = C.position
				
				C.set_movement_state("Jump")
				jump_state.click_jump()


func character_exists(chr):
	
	if chr != null:
		if !is_instance_valid(chr):
			return false
		
		if "dead" in chr and chr.dead == true:
			return false
		
		if is_instance_valid(chr) and chr.is_queued_for_deletion():
			return false
	else:
		return false
	
	return true

