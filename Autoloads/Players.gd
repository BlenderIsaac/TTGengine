extends Node

var dropped_in = [
	## {"active" : BOOL, "control_type" : STRING, "controller_num" : INT}
	{"active" : true, "control_type" : "keyboard", "controller_number" : 0, "money" : 0},
	{"active" : false, "control_type" : "keyboard", "controller_number" : 0, "money" : 0},
#	{"active" : false, "control_type" : "keyboard", "controller_number" : 0},
#	{"active" : false, "control_type" : "keyboard", "controller_number" : 0},
]

var keys_pressed = []

func _ready():
	set_process_mode(PROCESS_MODE_ALWAYS)

func _process(_delta):
	
	var char_num = 0
	for keys in SETTINGS.player_keys:
		var pause_key = keys.Pause
		
		if f.key_press(pause_key, "keyboard"):
			if !keys_pressed.has(pause_key):
				
				if dropped_in[char_num].active == false:
					drop_in_char({"control_type" : "keyboard"}, char_num, get_tree().get_first_node_in_group("LEVELROOT"))
					dropped_in[char_num].control_type = "keyboard"
					dropped_in[char_num].active = true
				else:
					if Interface.is_paused == false:
						if dropped_in[char_num].control_type == "keyboard":
							Interface.Pause(char_num)
						#drop_out_char(char_num, get_tree().get_first_node_in_group("LEVELROOT"))
						#dropped_in[char_num].control_type = "keyboard"
						#dropped_in[char_num].active = false
				
				keys_pressed.append(pause_key)
				
				Interface.update_freeplay_select_interface()
		else:
			keys_pressed.erase(pause_key)
		
		
		char_num += 1


func _input(event):
	if event is InputEventJoypadButton:
		if event.button_index == 6:
			if event.pressed == true:
				controller_start_pressed(event.device)

func controller_start_pressed(controller_num):
	var char_num = 0
	
	# first check if controller is already in use
	for char_data in dropped_in:
		
		if char_data.active == true:
			if char_data.control_type == "controller" and char_data.controller_number == controller_num:
				# drop out
				Interface.Pause(char_num)
				return
		
		char_num += 1
	
	char_num = 0
	
	for char_data in dropped_in:
		
		if char_data.active == false:
			# drop in
			drop_in_char({"control_type" : "controller", "controller_number" : controller_num}, char_num, get_tree().get_first_node_in_group("LEVELROOT"))
			
			dropped_in[char_num].control_type = "controller"
			dropped_in[char_num].controller_number = controller_num
			dropped_in[char_num].active = true
			return
		
		char_num += 1


func drop_in_currents(levelroot):
	
	var player_num = 0
	for character in dropped_in:
		if character.active:
			drop_in_char(character, player_num, levelroot, false)
		else:
			var char_node = find_dropped_out_char_by_num(player_num, levelroot)
			
			if char_node:
				char_node.player_number = player_num
				char_node.control_type = character.control_type
				if character.control_type == "controller":
					char_node.controller_number = character.controller_number
				
				char_node.setup_keys()
				char_node.update_HUD()
				char_node.update_camera_target()
		
		player_num += 1

func drop_out_char(char_num, levelroot):
	var character = find_dropped_in_char_by_num(char_num, levelroot)
	
	if character:
		character.AI = true
		
		character.update_HUD()
		character.update_camera_target()
		
		character.ai_to = character.position
		character.target = character.position


func drop_in_char(char_data, char_num, levelroot, dropinanim=true):
	
	var character = find_dropped_out_char_by_num(char_num, levelroot)
	
	if character:
		character.AI = false
		
		character.player_number = char_num
		if dropinanim:
			character.modulate_anim.stop()
			character.modulate_anim.play("FlashAnims/respawn")
		character.control_type = char_data.control_type
		if char_data.control_type == "controller":
			character.controller_number = char_data.controller_number
		character.just_dropped = true
		
		character.setup_keys()
		character.update_HUD()
		character.update_camera_target()


func find_dropped_in_char_by_num(char_num, levelroot):
	
	for character in levelroot.get_tree().get_nodes_in_group("Character"):
		if character.player:
			
			if character.player_number == char_num:
				
				if character.AI == false:
					return character
	
	return null


func find_dropped_out_char_by_num(char_num, levelroot):
	var char_to_drop_in = null
	var backup = null
	
	var has_been_taken = false
	
	for character in levelroot.get_tree().get_nodes_in_group("Character"):
		if character.player and has_been_taken == false:
			
			if character.player_number == char_num:
				
				if character.AI == true:
					char_to_drop_in = character
					break
				else:
					has_been_taken = true
			
			elif character.player_number == -1:
				backup = character
	
	var final_char = null
	if char_to_drop_in:
		final_char = char_to_drop_in
	else:
		if backup:
			final_char = backup
	
	return final_char


