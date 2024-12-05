extends Control

var team_indexes = {}
var current_mod_selecting = ""

var selected_indexes = {
	"0" : 0,
	"1" : 1,
	#"2" : 2,
	#"3" : 3,
	}
var player_back = {
	"0" : "Blue",
	"1" : "Green",
	"2" : "Yellow",
	"3" : "Red",
	}
var currently_pressed_keys = [
	[],
	[],
	#[],
	#[],
	]
var char_data = {}
@onready var audio_player = $AudioPlayer

var transition_speed = 1.0
var frame_delay = 3
var transition_left = 0.0
var last_imagetexture = null

var sound_mod = "Ahsoka Show"
var sounds = {
	"MinikitCollect" : {
		"cSoundsPath" : ["MK-PICKUP.WAV"]
	},
	"SceneTransition" : {
		"cSoundsPath" : ["WIPESCREEN.WAV"]
	}
}

func _ready():
	$LevelEnd/StudTotal/HBoxContainer/VBoxContainer/HBoxContainer/Group/LeftStud/Stud.play("Gold")
	$LevelEnd/StudTotal/HBoxContainer/VBoxContainer/HBoxContainer/Group/RightStud/Stud.play("Gold")
	#$LevelEnd/StudTotal/HBoxContainer/VBoxContainer/HBoxContainer/LeftStud/Stud.play("Gold")
	#$LevelEnd/StudTotal/HBoxContainer/VBoxContainer/HBoxContainer/RightStud/Stud.play("Gold")
	
	$LevelEnd/Continue.hide()
	$LevelEnd.hide()
	
	$FreePlaySelect.hide()
	$ModeSelect.hide()
	$Pause.hide()
	$Icons.hide()
	
	audio_player.add_library(sounds, sound_mod)


func _process(_delta):
	
	if transition_left > 0:
		if frame_delay <= 0:
			
			transition_left -= _delta
			
			
			$Transition.region_rect.size.x = lerp(0.0, last_imagetexture.get_size().x, transition_left)
		else:
			frame_delay -= 1
			$Transition.region_rect.size.x = last_imagetexture.get_size().x
	else:
		$Transition.region_rect.size.x = 0.0
	
	
	$Label.text = str(1/get_process_delta_time())#str(team_indexes)
	
	if $ModeSelect.visible:
		var player_num = 0
		for plyr in Players.dropped_in:
			if plyr.active:
				if key_just_unpressed("Special", player_num):
					
					set_icons_mode("hearts")
					#for icon in Interface.get_node("Icons").get_children():
						#icon.get_node("Control/InGame").show()
						#icon.get_node("Control/InSelect").hide()
					
					get_tree().paused = false
					
					get_node("ModeSelect").hide()
					
					Levels.exit_menu_to_hub()
					
					for character in get_tree().get_nodes_in_group("Character"):
						if character.player:
							#var rand_vec = f.RandomVector3(-0.1, 0.1, 0, 0, -0.1, 0.1)
							#var rand_pos = Levels.door_position + rand_vec
							#
							#character.position = rand_pos
							
							character.reset_movement_state()
							
							character.anim.play(character.weapon_prefix+"Idleloop", 0)
			
			player_num += 1
	
	if $FreePlaySelect.visible and !freeplay_select_anim:
		
		sin_time1 += randf_range(_delta, 2*_delta)
		sin_time2 += randf_range(.5*_delta, 1.5*_delta)
		
		FreePlaySelect_tick()
	
	if $ControlSettings.visible:
		ControlSettings_tick()
	
	if $Pause.visible or $ModeSelect.visible or $LevelEnd.visible:
		Button_tick()
	elif $ControlSettings.visible and input_editing_idx == -1:
		Button_tick()
	
	if $LevelEnd.visible:
		LevelFinish_tick(_delta)
	
	if freeplay_select_anim:
		
		if freeplay_select_anim_timer >= 1.0:
			freeplay_select_anim_timer = 0.0
			freeplay_select_anim_stage = 1.0
		
		var select_index = 0
		for anim in freeplay_select_anim_data:
			var node = $FreePlaySelect/SelectAnim.get_child(select_index)
			
			if freeplay_select_anim_stage == 0:
				
				node.global_position = f.LerpVector2(anim.StartPosition, anim.EndPosition, ease(freeplay_select_anim_timer, freeplay_select_anim_ease))
				node.get_node("Back").scale = f.LerpVector2(anim.StartScale, anim.EndScale, ease(freeplay_select_anim_timer, freeplay_select_anim_ease))
			elif freeplay_select_anim_stage == 1:
				node.position.x += 10
				
				if node.position.x > get_viewport_rect().size.x+60:
					freeplay_select_anim_data.erase(anim)
					node.queue_free()
			
			select_index += 1
		
		if freeplay_select_anim_data.is_empty():
			freeplay_select_anim = false
			
			start_level()
		
		freeplay_select_anim_timer += _delta
	
	minikit_tick(_delta)
	
	update_currently_pressed_keys()

func isPaused():
	if $FreePlaySelect.visible:
		return true
	if $ModeSelect.visible:
		return true
	if $Pause.visible:
		return true
	if $ControlSettings.visible:
		return true
	if $LevelEnd.visible:
		return true
	if $CharacterList.visible:
		return true
	
	return false

#region >< Pause Menu ><

var pause_owner = null
func Button_tick():
	
	var button = get_viewport().gui_get_focus_owner()
	
	if button != null and button.is_visible_in_tree():
		
		if pause_owner != null:
			
			if key_just_unpressed("Jump", pause_owner):
				
				var method_name = str("Button_", button.name)
				
				if has_method(method_name):
					call(method_name)
			
			if key_just_pressed("Up", pause_owner):
				button.find_valid_focus_neighbor(SIDE_TOP).grab_focus()
			
			if key_just_pressed("Down", pause_owner):
				button.find_valid_focus_neighbor(SIDE_BOTTOM).grab_focus()
		
		else:
			
			var check_owner = 0
			
			for player in Players.dropped_in:
				
				if key_just_unpressed("Jump", check_owner):
					
					var method_name = str("Button_", button.name)
					
					if has_method(method_name):
						call(method_name)
				
				if key_just_pressed("Up", check_owner):
					button.find_valid_focus_neighbor(SIDE_TOP).grab_focus()
				
				if key_just_pressed("Down", check_owner):
					button.find_valid_focus_neighbor(SIDE_BOTTOM).grab_focus()
				
				check_owner += 1

func Button_DropOut():
	if pause_owner != null:
		Players.drop_out_char(pause_owner, get_tree().get_first_node_in_group("LEVELROOT"))
		Players.dropped_in[pause_owner].control_type = "keyboard"
		Players.dropped_in[pause_owner].active = false
		unPause()

func Button_Resume():
	unPause()

func Button_Quit():
	# go to main menu or hub
	
	var levelroot = get_tree().get_first_node_in_group("LEVELROOT")
	
	if levelroot.is_hub:
		$Pause/Center/Quit/QuitHub.hide()
	else:
		$Pause/Center/Quit/QuitHub.show()
	
	$"Pause/Center/Main Pause".hide()
	$Pause/Center/Quit.show()
	
	$Pause/Center/Quit/QuitCancel.grab_focus()

func Button_QuitCancel():
	$"Pause/Center/Main Pause".show()
	$Pause/Center/Quit.hide()
	
	$"Pause/Center/Main Pause/Quit".grab_focus()

func Button_QuitRestart():
	pass # Replace with function body.

func Button_QuitHub():
	
	var player_data = get_player_data()#[]
	
	#for character in get_tree().get_nodes_in_group("Character"):
		#if character.player:
			#player_data.insert(character.player_number, {"Char" : character.current_filename, "Mod" : character.origin_mod})
	
	var levelroot = get_tree().get_first_node_in_group("LEVELROOT")
	
	var hub_mod = levelroot.mod
	
	levelroot.free()
	
	unPause()
	
	Levels.load_hub(hub_mod, player_data)

func Button_QuitMenu():
	var levelroot = get_tree().get_first_node_in_group("LEVELROOT")
	
	levelroot.free()
	
	unPause()
	
	hide_element("Icons")
	
	get_tree().change_scene_to_file("res://Interfaces/main_menu.tscn")

func Button_QuitDesktop():
	# TODO: Save here maybe?
	get_tree().quit()

func Button_ControlSetup():
	input_editing_idx = -1
	$Pause.hide()
	$ControlSettings.show()
	$ControlSettings/Center/VBoxContainer/SettingsCancel.grab_focus()

var is_paused = false
func Pause(owner_num):
	is_paused = true
	pause_owner = owner_num
	
	var only_one_left = true
	var player_num = 0
	for player in Players.dropped_in:
		if player.active and player_num != owner_num:
			only_one_left = false
		
		player_num += 1
	
	if pause_owner == null or only_one_left:
		$"Pause/Center/Main Pause/DropOut".hide()
		$"Pause/Center/Main Pause/Resume".grab_focus()
	else:
		$"Pause/Center/Main Pause/DropOut".show()
		$"Pause/Center/Main Pause/DropOut".grab_focus()
	
	for menu in $Pause/Center.get_children():
		menu.hide()
	
	$"Pause/Center/Main Pause".show()
	
	get_tree().paused = true
	$Pause.show()

func unPause():
	is_paused = false
	get_tree().paused = false
	$Pause.hide()

#endregion

#region >< Minikits ><

var minikit_displaying = false:
	set(value):
		
		if value != minikit_displaying:
			if value == true:
				$Minikits/MiddlePos/BottomPos/Alignment/Scaler/MinikitAnim.play("ComeIn")
			else:
				$Minikits/MiddlePos/BottomPos/Alignment/Scaler/MinikitAnim.play_backwards("ComeIn")
		
		minikit_displaying = value
var traveling_minikits = []
var minikits_collected = 0:
	set(value):
		minikits_collected = value
		$Minikits/MiddlePos/BottomPos/Alignment/Scaler/Name.text = str(value) + "/10"
func minikit_found(projected_pos):
	var minikit_spawn = $Minikits/MiddlePos/BottomPos/Alignment/Scaler/MinkitVis.duplicate()
	add_child(minikit_spawn)
	minikit_spawn.position = projected_pos
	traveling_minikits.append([0.0, minikit_spawn])
	
	audio_player.play("MinikitCollect")
	
	minikit_spawn.scale = Vector2(0.246, 0.246)
	
	minikit_displaying = true


func minikit_tick(_delta):
	
	var minikit_anim = $Minikits/MiddlePos/BottomPos/Alignment/Scaler/MinikitAnim
	
	if traveling_minikits.is_empty() and minikit_anim.current_animation == "":
		if $Pause.visible or finish_stage == "minikit":
			minikit_displaying = true
		else:
			minikit_displaying = false
	
	for minikit in traveling_minikits:
		var diff = $Minikits/MiddlePos/BottomPos/Alignment/Scaler/MinkitVis.global_position - minikit[1].global_position
		minikit[1].position += diff.normalized()*_delta*500.0*(minikit[0])
		
		minikit[0] += _delta
		
		if diff.length() < 5*minikit[0]:
			minikit_anim.play("Gain")
			minikits_collected += 1
			traveling_minikits.erase(minikit)
			minikit[1].queue_free()

#endregion

#region >< Level Finish ><

var finish_stage = "trueJedi"
var finish_stages = [
	#"characterUpdate",
	#"trueJedi",
	"studTotal",
	"minikit",
	#"goldBrickUpdate",
	"continue",
]

func characterUpdate_init():
	clear_icons()
	load_icons(Levels.level_state.Mod)
	show_element("CharacterList")
	$LevelEnd/AnimationPlayer.play("CharacterUpdate")
	$LevelEnd/AnimationPlayer.queue("CharacterUpdateLoop")
func characterUpdate_uninit():
	hide_element("CharacterList")

func continue_init():
	$LevelEnd/AnimationPlayer.play("ContinueIn")
	$LevelEnd/Continue.show()
	$LevelEnd/Continue/VBoxPause/Hub.grab_focus()

func studTotal_init():
	show_element("Icons")
	set_icons_mode("just_icons")
	
	advance_finish_stage()

func init_level_finish():
	pass

var level_finish_player_data = []

func trueJedi_init():
	$LevelEnd/AnimationPlayer.play("TrueJediStart")
	truejedi_tickup = 0.0

func minikit_init():
	show_element("Icons")
	set_icons_mode("just_icons")
	
	minikits_count_up_to = minikits_collected
	minikits_collected = 0
	var minikit_buildup = $LevelEnd/MinikitBuildup/SubViewportContainer/SubViewport/MinikitBuilding
	minikit_buildup.show()
	$LevelEnd/MinikitBuildup.show()
	minikit_buildup.play_model("Ahsoka Show", "Debe", minikits_count_up_to)
	minikit_buildup.connect("piece_added", advance_minikit_count_up)

func minikit_uninit():
	minikit_displaying = false
	var minikit_buildup = $LevelEnd/MinikitBuildup/SubViewportContainer/SubViewport/MinikitBuilding
	minikit_buildup.hide()
	$LevelEnd/MinikitBuildup.hide()
	
	minikit_buildup.clear_model()

func advance_minikit_count_up():
	var minikit_anim = $Minikits/MiddlePos/BottomPos/Alignment/Scaler/MinikitAnim
	minikit_anim.play("Gain")
	minikits_collected += 1

var minikits_count_up_to = 0
var truejedi_tickup = 0.0
var truejedi_anim_point = 0.0
func LevelFinish_tick(_delta):
	
	var truejedi_perc = 100
	
	var LEanim:AnimationPlayer = $LevelEnd/AnimationPlayer
	if finish_stage == "characterUpdate":
		if LEanim.current_animation == "CharacterUpdateLoop":
			# do stuff
			# if stuff has been done:
			LEanim.play("CharacterUpdateFade")
		elif not LEanim.is_playing():
			advance_finish_stage()
	elif finish_stage == "trueJedi":
		var yellow = $LevelEnd/TrueJedi/HBoxContainer/VBoxContainer/Counter/Animated/Yellow
		if LEanim.current_animation == "TrueJediStart":
			
			if LEanim.current_animation_position > 1.0 and truejedi_tickup < truejedi_perc:
				truejedi_tickup += _delta*60*0.7
			
			if truejedi_tickup > truejedi_perc:
				LEanim.play("TrueJediEnd")
				if truejedi_perc >= 100:
					truejedi_anim_point = 0.0
					$LevelEnd/TrueJedi/HBoxContainer/VBoxContainer/Percentage/AnimPerc/ZoomIn.text = str(int(truejedi_tickup),"%")
					$LevelEnd/TrueJedi/HBoxContainer/VBoxContainer/Percentage/AnimPerc/ZoomOut.text = str(int(truejedi_tickup),"%")
					$LevelEnd/TrueJedi/HBoxContainer/VBoxContainer/Percentage/AnimPerc/AnimationPlayer.play("PercJuice")
			
			var idx = 1.0
			for node in yellow.get_children():
				if idx < truejedi_tickup/10.0:
					node.modulate.a = 1.0
				else:
					var piece_val = (truejedi_tickup - idx*10)+10
					node.modulate.a = piece_val/10
				
				idx += 1.0
			
			$LevelEnd/TrueJedi/HBoxContainer/VBoxContainer/Percentage.text = str(int(truejedi_tickup),"%")
		elif LEanim.current_animation == "TrueJediEnd":
			#LEanim.seek(1, true)
			if truejedi_perc == 100:
				
				var idx = 1.0
				for node in yellow.get_children():
					
					var pos = idx/10 - truejedi_anim_point/10
					
					if pos < -0.1:
						pos += 1
					
					node.modulate.a = pos
					
					idx += 1.0
				
				if truejedi_anim_point > 10.0:
					truejedi_anim_point = 0.0
				
				var truejedi_win_anim_speed = 12
				truejedi_anim_point += _delta*truejedi_win_anim_speed
		else:
			advance_finish_stage()
	elif finish_stage == "continue":
		pass
	elif finish_stage == "minikit":
		if minikits_count_up_to == minikits_collected:
			advance_finish_stage()

func advance_finish_stage():
	if has_method(finish_stage+"_uninit"):
		call(finish_stage+"_uninit")
	finish_stage = finish_stages[finish_stages.find(finish_stage)+1]
	if has_method(finish_stage+"_init"):
		call(finish_stage+"_init")

func finish_level():
	hide_all_elements()
	
	if has_method(finish_stage+"_uninit"):
		call(finish_stage+"_uninit")
	
	finish_stage = finish_stages[0]
	if has_method(finish_stage+"_init"):
		call(finish_stage+"_init")
	
	show_element("LevelEnd")


func Button_ContinueStory():
	pass # Replace with function body.


func Button_Hub():
	hide_element("LevelEnd")
	show_element("Icons")
	Levels.load_hub(Levels.level_state.Mod, level_finish_player_data)


#endregion

#region >< Free Play Select ><

var load_level_name = ""
var load_level_mod = ""

var sin_time1 = 0
var sin_time2 = 0

var mode_selected = ""

@onready var character_container = $CharacterList/Container

func FreePlaySelect_tick():
	
	$FreePlaySelect/PlayerSelects/Player0/Back.position.x = 2*sin(sin_time1*5)
	$FreePlaySelect/PlayerSelects/Player0/Back.position.y = 2*cos(sin_time1*5)
	
	$FreePlaySelect/PlayerSelects/Player1/Back.position.x = 2*cos(sin_time2*-5)
	$FreePlaySelect/PlayerSelects/Player1/Back.position.y = 2*sin(sin_time2*5)
	
	var grid = character_container.get_node(current_mod_selecting)
	
	var columns = grid.columns
	var full_rows = grid.get_child_count()/columns
	var rows = ceil(float(grid.get_child_count())/columns)
	
	var incomplete_row_columns = grid.get_child_count()-full_rows*columns
	#var num_spaces_missing = columns-incomplete_row_columns
	
	for player_number in selected_indexes.keys():
		
		if Players.dropped_in[int(player_number)].active == true:
			
			var change = false
			var new_num = team_indexes.keys().find(current_mod_selecting)
			
			if key_just_pressed("ChangeLeft", player_number):
				new_num += 1
				change = true
			
			if key_just_pressed("ChangeRight", player_number):
				new_num -= 1
				change = true
			
			
			if change:
				if new_num < 0:
					new_num = team_indexes.keys().size()-1
				
				if new_num > team_indexes.keys().size()-1:
					new_num = 0
				
				current_mod_selecting = team_indexes.keys()[new_num]
				
				for team_name in team_indexes.keys():
					character_container.get_node(team_name).hide()
				
				character_container.get_node(current_mod_selecting).show()
				
				selected_indexes = {
				"0" : 0,
				"1" : 1,
				}
			
			var select_index = selected_indexes.get(player_number)
			
			var pos_y = select_index/columns
			var pos_x = select_index-pos_y*columns
			
			var vec = Vector2(pos_x, pos_y)
			
			if key_just_pressed("Jump", player_number):
				if !team_indexes.get(current_mod_selecting).has(select_index):
					add_to_team(select_index)
				else:
					remove_from_team(select_index)
				
				#update = true
			
			if key_just_unpressed("Fight", player_number):
				play_character_select_anim()
			
			if key_just_unpressed("Special", player_number):
				show_element("ModeSelect")
				hide_element("FreePlaySelect")
				hide_element("CharacterList")
				
				$ModeSelect/CenterPause/VBoxPause.get_node(mode_selected).grab_focus()
			
			if key_just_pressed("Up", player_number):
				vec.y -= 1
				
				if vec.y < 0:
					vec.y = rows-1
					
					if !full_rows == rows:
						if vec.x >= incomplete_row_columns:
							vec.y = rows-2
				
				#update = true
			
			if key_just_pressed("Down", player_number):
				vec.y += 1
				
				if vec.y > rows-1:
					vec.y = 0
					
				if !full_rows == rows:
					if vec.y > rows-2:
						if vec.x >= incomplete_row_columns:
							vec.y = 0
				
				#update = true
			
			if key_just_pressed("Left", player_number):
				vec.x -= 1
				
				if vec.x < 0:
					vec.x = columns-1
					
					if vec.y == rows-1:
						if !full_rows == rows:
							vec.x = incomplete_row_columns-1
				
				#update = true
			
			if key_just_pressed("Right", player_number):
				vec.x += 1
				
				if vec.x > columns-1:
					vec.x = 0
				if vec.y == rows-1:
					if !full_rows == rows:
						if vec.x >= incomplete_row_columns:
							vec.x = 0
				
				#update = true
			
			var new_select_index = int(vec.y)*int(columns) + int(vec.x)
			
			selected_indexes[str(player_number)] = new_select_index
			
			#if update:
			update_selects()


func update_freeplay_select_interface():
	if $FreePlaySelect.visible:
		var char_num = 0
		for player in Players.dropped_in:
			if player.active:
				$FreePlaySelect/Center/PlayerContainers.get_node(str("Player", char_num, "Container")).show()
				$FreePlaySelect/PlayerSelects.get_node(str("Player", char_num)).show()
			else:
				$FreePlaySelect/Center/PlayerContainers.get_node(str("Player", char_num, "Container")).hide()
				$FreePlaySelect/PlayerSelects.get_node(str("Player", char_num)).hide()
			
			char_num += 1
		
		update_selects()


func clear_icons():
	char_data = {}
	
	var container = character_container
	var normgrid = character_container.get_node("NormGrid")
	
	for grid in container.get_children():
		if !grid == normgrid:
			if !grid == character_container.get_node('Norm'):
				grid.name = "DelMe"
				grid.queue_free()


func load_icons(mod):
	
	var mod_grid = character_container.get_node("NormGrid").duplicate()
	
	character_container.add_child(mod_grid)
	
	var mods_path = SETTINGS.mod_path+"/"+mod+"/characters/chars"
	
	var chars = DirAccess.get_files_at(mods_path)
	
	for c in chars:
		if c.ends_with(".json"):
			
			var icon_path = ""
			var char_name = ""
			
			var next_file = mods_path+"/"+c
			
			while icon_path == "" and char_name == "":
				
				var file = FileAccess.open(next_file, FileAccess.READ)
				var data = JSON.parse_string(file.get_as_text())
				
				if data.has("Icon") and icon_path == "":
					icon_path = data.Icon
				
				if data.has("Name") and char_name == "":
					char_name = data.Name
				
				if data.has("Inherits"):
					next_file = mods_path+"/"+data.Inherits
				
				file.close()
			
			var icon = create_icon(MATERIALS.load_texture(SETTINGS.mod_path+"/"+mod+"/characters/icons/"+icon_path), char_name)
			
			if !char_data.has(mod):
				char_data[mod] = []
			
			char_data[mod].append({
				#"Name" : data.Name,
				"Path" : c,
				"Mod" : mod,
			})
			
			mod_grid.add_child(icon)
	
	mod_grid.name = mod
	
	return mod_grid

func create_icon(icon, char_name):
	var norm = character_container.get_node('Norm')
	
	var new_icon = norm.duplicate()
	
	new_icon.get_node("Back/NAME").texture = icon
	new_icon.get_node("Back/NAME").name = char_name
	
	new_icon.show()
	
	return new_icon


func update_selects():
	var grid = character_container.get_node(current_mod_selecting)
	
	var cell_index = 0
	for cell in grid.get_children():
		cell.get_node("Back").show()
		cell.get_node("Back").modulate.a = 1.0
		
		var selected = team_indexes[current_mod_selecting].has(cell_index)
		
		var player_num = 0
		for index in selected_indexes.values():
			if index == cell_index:
				var sprite = get_node("FreePlaySelect/PlayerSelects/Player"+str(player_num))
				
				if Players.dropped_in[player_num].active == true:
					cell.get_node("Back").hide()
					sprite.get_node("Back/Icon").texture = cell.get_node("Back").get_child(0).texture
					sprite.position = cell.get_node("Back").global_position
					
					sprite.show()
					
					if selected:
						sprite.get_node("Back").modulate.a = 0.5
					else:
						sprite.get_node("Back").modulate.a = 1.0
					
					var player_node = $FreePlaySelect/Center/PlayerContainers.get_node("Player"+str(player_num)+"Container")
					
					player_node.get_node("Back").texture = l.get_load("res://Textures/"+player_back.get(str(player_num))+"Back.png")
					player_node.get_node("Back/Icon").texture = cell.get_node("Back").get_child(0).texture
					
					player_node.get_node("Name").text = cell.get_node("Back").get_child(0).name
					
				else:
					sprite.hide()
			
			if selected:
				cell.get_node("Back").modulate.a = 0.5
			
			player_num += 1
		
		cell_index += 1


func add_to_team(index):
	team_indexes.get(current_mod_selecting).append(index)

func remove_from_team(index):
	team_indexes.get(current_mod_selecting).erase(index)


func get_player_data():
	var player_data = []
	
	for character in get_tree().get_nodes_in_group("Character"):
		if character.player:
			player_data.append(null)
	
	for character in get_tree().get_nodes_in_group("Character"):
		if character.player:
			player_data[character.player_number] = {"Char" : character.current_filename, "Mod" : character.origin_mod}
	
	return player_data


func get_player_team():
	var player_team = []
	
	for select_index in selected_indexes.values():
		var player_index = int(select_index)
		
		if !player_team.has(char_data.get(current_mod_selecting)[player_index]):
			player_team.append(char_data.get(current_mod_selecting)[player_index])
	
	for mod in team_indexes.keys():
		var team_list = team_indexes.get(mod)
		
		for team_index in team_list:
			if !player_team.has(char_data.get(mod)[team_index]):
				player_team.append(char_data.get(mod)[team_index])
	
	return player_team


func start_level():
	
	var player_data = []
	
	for p in Players.dropped_in:
		player_data.append({})
	
	for str_index in selected_indexes.keys():
		
		var index = int(str_index)
		var char_index = selected_indexes.get(str_index)
		
		player_data[index] = {
			"Mod" : char_data.get(current_mod_selecting)[char_index].Mod,
			"Char" : char_data.get(current_mod_selecting)[char_index].Path
		}
	
	show_element("Icons")
	
	set_icons_mode("hearts")
	#for icon in Interface.get_node("Icons").get_children():
		#icon.get_node("Control/InGame").show()
		#icon.get_node("Control/InSelect").hide()
	
	hide_element("FreePlaySelect")
	hide_element("CharacterList")
	
	var player_team = get_player_team()
	
	Levels.load_freeplay_level(load_level_mod, load_level_name, player_data, player_team)

func hide_element(ele):get_node(ele).hide()
func show_element(ele):get_node(ele).show()
func hide_all_elements():for node_name in ["FreePlaySelect", "CharacterList", "ModeSelect", "Pause", "ControlSettings", "Icons", "LevelEnd"]:get_node(node_name).hide()
func set_icon_mode(player, mode):
	var icon = get_node("Icons").get_child(player)
	
	icon.get_node("Control/InGame").hide()
	icon.get_node("Control/InSelect").hide()
	
	if mode == "info":
		icon.get_node("Control/InSelect").show()
	elif mode == "hearts":
		icon.get_node("Control/InGame").show()
	elif mode == "dropped_out":
		pass
	elif mode == "off":
		pass # icons move off screen
	elif mode == "just_icon":
		pass
	elif mode == "just_hearts":
		pass # only the hearts in a row
	elif mode == "just_studs":
		pass

func set_icons_mode(new_mode):
	set_icon_mode(0, new_mode)
	set_icon_mode(1, new_mode)
# hearts, dropped_out, just_studs, just_hearts, just_icon, info, off

var freeplay_select_anim = false
var freeplay_select_anim_data = []
var freeplay_select_anim_timer = 0.0
var freeplay_select_anim_ease = -2.5
var freeplay_select_anim_stage = 0
func play_character_select_anim():
	
	freeplay_select_anim_timer = 0.0
	freeplay_select_anim_stage = 0
	
	hide_element("Icons")
	$FreePlaySelect.get_node("PlayerSelects").hide()
	$FreePlaySelect.get_node("Center").hide()
	hide_element("CharacterList")
	
	var final_team = team_indexes.duplicate(true)
	
	for i in selected_indexes.keys():
		
		var cell_index = int(selected_indexes.get(i))
		
		if team_indexes.get(current_mod_selecting).has(cell_index):
			final_team.get(current_mod_selecting).erase(cell_index)
			final_team.get(current_mod_selecting).insert(int(i), cell_index)
		
		if !team_indexes.get(current_mod_selecting).has(cell_index):
			final_team.get(current_mod_selecting).insert(int(i), cell_index)
	
	freeplay_select_anim_data.clear()
	
	var team_size = 0
	
	for team in final_team.values():
		team_size += team.size()
	
	var pos = 0
	for mod in final_team.keys():
		
		var index = 0
		var team = final_team.get(mod)
		
		for team_index in team:
			
			var og_cell_node = character_container.get_node(mod).get_child(team_index)
			
			var icon = og_cell_node.duplicate()
			$FreePlaySelect/SelectAnim.add_child(icon)
			icon.global_position = og_cell_node.global_position
			icon.get_node("Back").modulate.a = 1.0
			icon.get_node("Back").show()
			
			if selected_indexes.values().has(team_index):
				for str_play_index in selected_indexes.keys():
					if int(str_play_index) == index:
						icon.get_node("Back").texture = get_node(str("FreePlaySelect/PlayerSelects/Player", str_play_index, "/Back")).texture
			
			var pos_index = pos+0.5 - (float(team_size)/2.0)
			var center_of_screen = get_viewport_rect().size/2
			freeplay_select_anim_data.append(
					{
						"StartScale" : icon.get_node("Back").scale,
						"EndScale" : Vector2(0.3, 0.3),
						
						"StartPosition" : icon.global_position,
						"EndPosition" : center_of_screen + (Vector2(pos_index, 0)*80),
					}
				)
			
			index += 1
			
			pos += 1
	
	freeplay_select_anim = true

#endregion

#region >< Mode Select ><

func load_mode_select(mod_name, level_name):
	
	set_icons_mode("info")
	#for icon in Interface.get_node("Icons").get_children():
		#icon.get_node("Control/InGame").hide()
		#icon.get_node("Control/InSelect").show()
	
	get_tree().paused = true
	
	load_level_name = level_name
	load_level_mod = mod_name
	get_node("ModeSelect").show()
	
	pause_owner = null
	
	$ModeSelect/CenterPause/VBoxPause/StoryMode.grab_focus()


func Button_StoryMode():
	$ModeSelect.hide()
	
	mode_selected = "StoryMode"
	
	Levels.load_story_level(load_level_mod, load_level_name)
	
	set_icons_mode("hearts")
	#for icon in Interface.get_node("Icons").get_children():
		#icon.get_node("Control/InGame").show()
		#icon.get_node("Control/InSelect").hide()

func Button_FreePlay():
	team_indexes = {load_level_mod : []}
	current_mod_selecting = load_level_mod
	
	clear_icons()
	load_icons(load_level_mod)
	
	setup_freeplay()
	mode_selected = "FreePlay"
	update_freeplay_select_interface()

func Button_SuperFreePlay():
	
	var mods = DirAccess.get_directories_at(SETTINGS.mod_path)
	team_indexes = {}
	
	current_mod_selecting = load_level_mod
	
	clear_icons()
	
	for mod in mods:
		team_indexes[mod] = []
		var grid = load_icons(mod)
		
		if mod == load_level_mod:
			grid.show()
		else:
			grid.hide()
	
	setup_freeplay()
	mode_selected = "SuperFreePlay"
	update_freeplay_select_interface()

func setup_freeplay():
	
	for character in get_tree().get_nodes_in_group("Character"):
		if character.player:
			var filename = character.current_filename
			
			var index = 0
			for data in char_data.get(current_mod_selecting):
				if data.Path == filename:
					selected_indexes[str(character.player_number)] = index
				
				index += 1
	
	show_element("Icons")
	$FreePlaySelect.get_node("PlayerSelects").show()
	# TODO make this procedural with multiple characters
	$FreePlaySelect.get_node("Center").show()
	
	hide_element("ModeSelect")
	show_element("FreePlaySelect")
	show_element("CharacterList")
	
	$LevelEnd/AnimationPlayer.play("CharacterUpdateReset")
	
	# clear SelectAnim
	for node in $FreePlaySelect/SelectAnim.get_children():
		node.queue_free()

#endregion

#region >< Keys ><

func key_press(key, player):
	var control_type = Players.dropped_in[int(player)].control_type
	
	if control_type == "keyboard":
		var keys = SETTINGS.player_keys[(int(player))]
		if Input.is_key_pressed(OS.find_keycode_from_string(keys.get(key))):
			return true
	else:
		var buttons = SETTINGS.player_controller_buttons[int(player)]
		
		if buttons.has(key):
			var device_num = Players.dropped_in[int(player)].controller_number
			
			if Input.is_joy_button_pressed(device_num, buttons.get(key)):
				return true
	
	
	return false

func key_just_pressed(key, player):
	if key_press(key, int(player)):
		if !currently_pressed_keys[int(player)].has(key):
			return true
	
	return false

func key_just_unpressed(key, player):
	if !key_press(key, int(player)):
		if currently_pressed_keys[int(player)].has(key):
			return true
	
	return false

func update_currently_pressed_keys():
	var player_num = 0
	
	for _i in currently_pressed_keys:
		
		var keys_array = []
		
		var keys = SETTINGS.player_keys[int(player_num)]
		
		for key in keys:
			if key_press(key, player_num):
				keys_array.append(key)
		
		currently_pressed_keys[player_num] = keys_array
		
		player_num += 1

#endregion

#region >< Control Setup ><

var control_player_number = 0
var input_editing_idx = -1
var editing = false
func ControlSettings_tick():
	$Label.text = str("editing_idx: "+str(input_editing_idx)+"\nediting?: "+str(editing))
	var button = get_viewport().gui_get_focus_owner()
	
	if button != null and button.is_visible_in_tree():
		if pause_owner != null:
			
			if editing == false:
				if button.get_parent() == $ControlSettings/Center/VBoxContainer/Columns/InputButtons:
					if key_just_unpressed("Jump", pause_owner):
						input_editing_idx = button.get_index()
						editing = true
				
				#var new_p_num = control_player_number
				#
				#if key_just_pressed("ChangeLeft", pause_owner):
					#new_p_num -= 1
					#
					#if new_p_num < 0:
						#new_p_num = Players.dropped_in.size()-1
				#
				#if key_just_pressed("ChangeRight", pause_owner):
					#new_p_num += 1
					#
					#if new_p_num >= Players.dropped_in.size():
						#new_p_num = 0
				#
				#if new_p_num != control_player_number:
					#save_player_settings(new_p_num)
			else:
				pass


func _input(event):
	if editing == true:
		if event is InputEventKey:
			
			var new_key = OS.get_keycode_string(event.keycode)
			
			$ControlSettings/Center/VBoxContainer/Columns/ChosenInput.get_child(input_editing_idx).text = new_key
			
			input_editing_idx = -1
			editing = false


func save_player_settings(play_num):
	var new_keys = {
		'Up' : 'W',
		'Down' : 'S',
		'Left' : 'A',
		'Right' : 'D',
		'Special': 'H',
		'Jump' : 'G',
		'Fight' : 'F',
		'Tag' : 'T',
		'ChangeLeft' : 'R',
		'ChangeRight' : 'Y',
		'Pause' : 'Q',
	}
	
	for label in $ControlSettings/Center/VBoxContainer/Columns/ChosenInput.get_children():
		new_keys[label.name] = label.text
	
	SETTINGS.player_keys[play_num] = new_keys
	
	for character in get_tree().get_nodes_in_group("Character"):
		character.setup_keys()


func Button_SettingsSave():
	save_player_settings(control_player_number)

func Button_SettingsCancel():
	$ControlSettings.hide()
	$Pause.show()
	
	$"Pause/Center/Main Pause/ControlSetup".grab_focus()

func Button_SettingsReset():
	pass # Replace with function body.

#endregion

func transition_in():
	last_imagetexture = get_viewport_texture()
	$Transition.texture = last_imagetexture
	$Transition.region_rect.size.y = last_imagetexture.get_size().y
	transition_left = transition_speed
	audio_player.play("SceneTransition")
	frame_delay = 3
	#$Transition/AnimationPlayer.play("out")

func get_viewport_texture():
	var img = get_viewport().get_texture().get_image()
	
	var imgtex = ImageTexture.new()
	imgtex.set_image(img)
	
	return imgtex

func _on_timer_timeout():
	var col_1 = Color("00ffff")
	var col_2 = Color("9a36e7")
	
	var color = $Pause.theme.get("Button/colors/font_focus_color")
	
	if color == col_1:
		$Pause.theme.set("Button/colors/font_focus_color", col_2)
		$Pause.theme.set("Button/colors/font_hover_color", col_2)
	else:
		$Pause.theme.set("Button/colors/font_focus_color", col_1)
		$Pause.theme.set("Button/colors/font_hover_color", col_1)
