extends Control

var last_level = null

func _ready():
	_on_load_level_pressed()

#func _input(_event):
	#if Input.is_action_just_pressed("unlock"):
		#_on_load_level_pressed()

func _on_load_hub_pressed():
	var mod = $Mod.text
	
	load_hub(mod)

func _on_load_level_pressed():
	var mod = $Mod.text
	var level = $Level.text
	var section = $Section.text
	
	if !section:
		if $FreePlayCheck.pressed:
			var p_data = [{"Char":"BaylanSkoll.json", "Mod":mod}, {"Char":"RD3.json", "Mod":mod}]
			var p_team = []
			
			var mods_path = SETTINGS.mod_path+"/"+mod+"/characters/chars"
			
			var chars = DirAccess.get_files_at(mods_path)
			
			for c in chars:
				if c.ends_with(".json"):
					p_team.append({"Mod":mod, "Path":c})
			
			Levels.load_freeplay_level(mod, level, p_data, p_team)
		else:
			Levels.load_story_level(mod, level)
	else:
		
		var create_level = Levels.create_level(mod, level, section)
		
		Levels.add_child(create_level)
		
		create_level.Story_load_characters()
		
		Players.drop_in_currents(create_level)
		
		Levels.create_level(mod, level, section)
		
		var type = "Story"
		if level == "HUB":
			type = "Hub"
		
		#level_state = {"Type" : "Hub", "Mod" : "Ahsoka Show", "Section" : "WorldBetweenWorlds", "LevelName" : "HUB", "Mode" : "Story"}
		Levels.level_state.Type = type
		Levels.level_state.Mod = mod
		Levels.level_state.Section = section
		Levels.level_state.LevelName = level
		Levels.level_state.Mode = "Story"
	
	Interface.get_node("Icons").show()
	hide()


func load_hub(mod):
	
	var player_data = [{"Mod" : "Ahsoka Show", "Char" : "NRTrooper.json"}, {"Mod" : "Ahsoka Show", "Char" : "Jakris.json"}]
	
	Levels.load_hub(mod, player_data)
	
	Interface.get_node("Icons").show()
	
	hide()
