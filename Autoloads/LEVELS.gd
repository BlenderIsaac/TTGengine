extends Node

var LEVEL_LOAD

var current_level = null

var level_state = {"Type" : "Hub", "Mod" : "Ahsoka Show", "Section" : "WorldBetweenWorlds", "LevelName" : "HUB", "Mode" : "Story"}
var object_changes = {}
var char_spawn_dead = {}
var objects_dead = {}

var debug_cam_transform = Transform3D()

var player_team = []

func _ready():
	LEVEL_LOAD = l.get_load("res://Levels/level.tscn")

func _process(_delta):
	
	if next_level_load_data.Active == true:
		if !is_instance_valid(next_level_load_data.ToDelete):
			callv(next_level_load_data.ToRun, next_level_load_data.Args)
			next_level_load_data.ToDelete = null
			next_level_load_data.Active = false


func create_level_instance():
	return LEVEL_LOAD.instantiate()


func create_level(mod, level_name, section):
	var level = create_level_instance()
	
	current_level = level
	level.level_name = level_name
	level.mod = mod
	
	level.CREATE_LEVEL(mod, level_name, section)
	
	if debug_cam_transform != Transform3D():
		level.get_node("Camera3D").transform = debug_cam_transform
	
	return level


func hub_into_level(mod_name, level_name):
	
	var prev_level = get_child(0)
	prev_level.hide()
	
	Interface.load_mode_select(mod_name, level_name)

func exit_menu_to_hub():
	var prev_level = get_child(0)
	prev_level.show()


func get_initial_section(mod_name, level_name):
	var level_path = SETTINGS.mod_path+"/"+mod_name+"/levels/leveldata/"+level_name+"/"+level_name+".json"
	
	var file = FileAccess.open(level_path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	
	return data.StartSection


func i_am_dead(dead_object):
	var section = level_state.Section
	var list = objects_dead.get(section, [])
	list.append(get_tree().get_first_node_in_group("LEVELROOT").get_path_to(dead_object))
	Levels.objects_dead[section] = list


func load_story_level(mod_name, level_name):
	get_tree().paused = false
	
	if get_children().size() > 0:
		var prev_level = get_child(0)
		
		if prev_level:
			remove_child(prev_level)
			prev_level.queue_free()
	
	object_changes = {}
	char_spawn_dead = {}
	
	# TODO: Unskippable Start Cutscene
	
	var section = get_initial_section(mod_name, level_name)
	var level = create_level(mod_name, level_name, section)
	
	level_state.Type = "Level"
	level_state.Mode = "Story"
	level_state.Mod = mod_name
	level_state.LevelName = level_name
	level_state.Section = section
	
	add_child(level)
	
	level.Story_load_characters()
	
	Players.drop_in_currents(level)


func load_freeplay_level(mod_name, level_name, player_data, new_player_team):
	var prev_level = get_child(0)
	get_tree().paused = false
	
	remove_child(prev_level)
	prev_level.queue_free()
	
	object_changes = {}
	char_spawn_dead = {}
	
	# TODO: Skippable Start Cutscene
	var section = get_initial_section(mod_name, level_name)
	var level = create_level(mod_name, level_name, section)
	
	level_state.Type = "Level"
	level_state.Mode = "Freeplay"
	level_state.Mod = mod_name
	level_state.LevelName = level_name
	level_state.Section = section
	
	add_child(level)
	
	for p_team in new_player_team:
		level.preload_char_from_file(p_team.Path, p_team.Mod)
	
	level.Specific_load_characters(player_data)
	
	player_team = new_player_team
	
	Players.drop_in_currents(level)


func change_section(new_section, doorid=0):
	var player_data = Interface.get_player_data()
	var prev_level = get_child(0)
	
	# obtain changed data
	object_changes[level_state.Section] = {}
	var obj_changers = get_tree().get_nodes_in_group("OBJCHANGE")
	for obj in obj_changers:
		if obj.has_meta("obj_changes"):
			
			var dictionary = {}
			
			for var_change in obj.get_meta("obj_changes"):
				dictionary[var_change] = obj.get(var_change)
			
			object_changes[level_state.Section][prev_level.get_path_to(obj)] = dictionary
	
	get_tree().paused = false
	remove_child(prev_level)
	prev_level.queue_free()
	
	
	var level = create_level(level_state.Mod, level_state.LevelName, new_section)
	level_state.Section = new_section
	
	if object_changes.has(level_state.Section):
		var obj_changes = object_changes[level_state.Section]
		
		for obj_i in obj_changes.size():
			var path = obj_changes.keys()[obj_i]
			for var_i in obj_changes[path].size():
				var vari = obj_changes[path].keys()[var_i]
				var value = obj_changes[path].values()[var_i]
				
				level.get_node(path).set(vari, value)
	
	
	if objects_dead.has(level_state.Section):
		var dead_in_section = objects_dead[level_state.Section]
		
		for object in dead_in_section:
			level.get_node(object).queue_free()
	
	
	add_child(level)
	
	var door_pos = null
	
	for door in get_tree().get_nodes_in_group("Door"):
		if "DoorId" in door:
			if door.DoorId == doorid:
				door_pos = {}
				
				door_pos["PosStart"] = door.spawn_positions[0]
				door_pos["PosEnd"] = door.spawn_positions[1]
				door_pos["MeshRot"] = door.rotation.y
	
	level.Spawn_at_door(player_data, door_pos)
	Players.drop_in_currents(level)


func finish_level():
	#var player_data = Interface.get_player_data()
	var prev_level = get_child(0)
	
	get_tree().paused = false
	remove_child(prev_level)
	prev_level.queue_free()
	
	Interface.finish_level()



var next_level_load_data = {
	"Active" : false,
	"ToDelete" : null,
	"ToRun" : "",
	"Args" : [],
}


func load_hub(mod, player_data):
	
	var section = get_initial_section(mod, "HUB")
	
	var hub = create_level(mod, "HUB", section)
	
	# ISSUE - infinite studs can be gotten by cycling hubs over and over again
	object_changes = {}
	char_spawn_dead = {}
	
	level_state.Type = "Hub"
	level_state.Mod = mod
	level_state.Mode = "Hub"
	level_state.LevelName = "HUB"
	level_state.Section = section
	
	add_child(hub)
	
	#if to_last_door and Levels.door_position:
		#for player in player_data:
			#
			#var rand_vec = f.RandomVector3(-0.1, 0.1, 0, 0, -0.1, 0.1)
			#var rand_pos = Levels.door_position + rand_vec
			#
			#player.PosX = rand_pos.x
			#player.PosY = rand_pos.y
			#player.PosZ = rand_pos.z
	
	hub.Specific_load_characters(player_data)
	
	hub.is_hub = true
	
	Players.drop_in_currents(hub)


func cycle_hubs(_current_mod, player_data, _direction):
	var levelroot = get_tree().get_first_node_in_group("LEVELROOT")
	
	levelroot.queue_free()
	
	next_level_load_data.ToDelete = levelroot
	next_level_load_data.ToRun = "load_hub"
	next_level_load_data.Args = ["Ahsoka Show", player_data]
	next_level_load_data.Active = true
