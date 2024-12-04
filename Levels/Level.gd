extends Node3D

#var stud_player_values = []
var mod = "Basic Characters"
var level_name = "HUB"
var section = ""

var main_menu = null
var char_can_change = false
var death_height = -5

var is_hub = false


func _process(_delta):
	
	if Input.is_action_just_pressed("restart"):
		Levels.debug_cam_transform = $Camera3D.global_transform
		Levels.load_story_level(Levels.level_state.Mod, Levels.level_state.LevelName)
		#get_tree().reload_current_scene()
	
	if Input.is_action_just_pressed("switchcam"):
		if $Camera3D.current:
			$Camera3D.current = false
			$GameCam.current = true
		else:
			$Camera3D.current = true
			$GameCam.current = false
	
	tick(_delta)

func _physics_process(_delta):
	phy_tick(_delta)
func tick(_delta):
	pass
func phy_tick(_delta):
	pass

func add_money(player_number, value):
	Players.dropped_in[player_number].money += value

func get_money(player_number):
	return Players.dropped_in[player_number].money

func get_player_data():
	var player_data = [null, null]
	for c in get_tree().get_nodes_in_group("Character"):
		if c.player_number >= 0:
			player_data[c.player_number] = {"Mod" : c.origin_mod, "Char" : c.current_filename}
	
	return player_data

var player_spawns = []
var team_spawns = []
func Story_load_characters():
	
	var replace = {
		1 : "RD3.json"
	}
	
	for player in player_spawns:
		
		if player.Num in replace.keys():
			player.Char = replace[player.Num]
		
		preload_char_from_file(player.Char, player.Mod)
		create_level_character(player)
	
	for player in team_spawns:
		player.Num = -1
		preload_char_from_file(player.Char, player.Mod)
		create_level_character(player)


func Specific_load_characters(players_data, override_position=null):
	
	var player_index = 0
	for player in player_spawns:
		
		var playerdata = players_data[player_index]
		
		player.Mod = playerdata.Mod
		player.Char = playerdata.Char
		player.Num = player_index
		
		if override_position == null:
			if playerdata.has("Pos"):
				player.Pos = playerdata.Pos
		else:
			player.Pos.x = override_position.Pos.x + randf_range(-.01, .01)
			player.Pos.y = override_position.Pos.y
			player.Pos.z = override_position.Pos.z + randf_range(-.01, .01)
			
			player["MeshRot"] = override_position.MeshRot
		
		preload_char_from_file(player.Char, player.Mod)
		
		create_level_character(player)
		
		player_index += 1


func Spawn_at_door(players_data, door_pos):
	
	if "CamTransform" in door_pos:
		$GameCam.begin_transform_override = true
		$GameCam.transform = door_pos.CamTransform
	
	var player_index = 0
	for player in player_spawns:
		
		var playerdata = players_data[player_index]
		
		player.Mod = playerdata.Mod
		player.Char = playerdata.Char
		player.Num = player_index
		
		var dist = 0.5
		if players_data.size() > 1:
			dist = player_index/(players_data.size()-1)
		
		var player_position = f.LerpVector3(door_pos.PosStart, door_pos.PosEnd, dist)
		
		player.Pos = player_position
		player["MeshRot"] = door_pos.MeshRot
		
		preload_char_from_file(player.Char, player.Mod)
		create_level_character(player)
		
		player_index += 1


func create_level_character(playerdata):
	var c = spawn_char_from_file(playerdata.Char, playerdata.Mod)
	
	c.player = true
	c.player_number = playerdata.Num
	c.position = playerdata.Pos
	
	add_child(c)
	
	c.setup_keys()
	c.update_HUD()
	c.update_camera_target()
	
	if playerdata.has("MeshRot"):
		c.get_node("Mesh").rotation.y = playerdata.MeshRot
		c.mesh_angle_to = playerdata.MeshRot


func preload_mod_chars(char_mod):
	
	var mods_path = SETTINGS.mod_path+"/"+char_mod+"/characters/chars"
	
	var chars = DirAccess.get_files_at(mods_path)
	
	for c in chars:
		preload_char_from_file(c, char_mod)


func preload_char_from_file(filename, char_mod):
	
	var mods_path = SETTINGS.mod_path+"/"+char_mod+"/characters/chars/"+filename
	
	# open and close the file, accessing the data
	var file = FileAccess.open(mods_path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	
	# the special load part of the file
	if data.has("Load"):
		var loads = data.Load
		
		# preload textures
		if loads.has("Textures"):
			for texture in loads.Textures:
				MATERIALS.load_texture(f.get_data_path(texture, char_mod))
		
		# preload materials
		if loads.has("Materials"):
			for matte in loads.Materials:
				MATERIALS.get_matte(matte, char_mod)
		
		# preload objects
		if loads.has("Obj"):
			for obj in loads.Obj:
				o.get_obj(f.get_data_path(obj, char_mod))
	
	# preload sounds
	if data.has("Sounds"):
		for key in data.Sounds.keys():
			var value = data.Sounds.get(key)
			
			for path_type in value.keys():
				var sound_list = value.get(path_type)
				
				for sound in sound_list:
					a.load_stream(f.get_data_path({path_type : sound}, char_mod))
	
	# preload rigs
	if data.has("Rig"):
		var rig_path = SETTINGS.mod_path+"/"+char_mod+"/characters/rigs/"+data.Rig
		if !data.Rig.ends_with(".glb"):
			l.get_load(rig_path)
	
	# preload attached objects
	if data.has("Models"):
		for model in data.Models:
			o.get_obj(f.get_data_path(model, char_mod))
	
	# preloading the materials
	if data.has("Materials"):
		for body_part in data.Materials.values():
			for matte in body_part.values():
				MATERIALS.get_matte(matte, char_mod)
	
	# preload animations
	if data.has("Animations"):
		for anim_name in data.Animations:
			l.get_load(f.get_data_path(anim_name, char_mod))


func spawn_char_from_file(path, char_mod):
	# change this function so it just spawns a generic character and calls change_charater on the char
	
	# generate a new character
	var new_char = l.get_load("res://Character/Character.tscn").instantiate()
	
	new_char.change_character_to_file(path, char_mod)
	
	return new_char


var char_index = 0
func generate_char(char_path, char_mod, char_pos):
	var character = spawn_char_from_file(char_path, char_mod)
	
	character.position = char_pos
	character.char_spawn = true
	character.char_spawn_index = char_index
	
	add_child(character)
	
	return character


@warning_ignore("unused_parameter")
func CREATE_LEVEL(N_mod, N_level_name, N_level_section):
	pass

#@warning_ignore("unused_parameter")
#func generate(leveldata, gen_level_name, gen_mod, gen_section):
	#pass
