extends Area3D

var DoorId = null

var destination = {}#{"Type" : "SectionChange", "Section" : "HangarA", "DoorId" : 0}
#var destination = {"Type" : "Visual"}
#var destination = {"Type" : "HubIntoLevel", "Mod" : "Basic Characters", "Level" : "SandStuff"}
#var destination = {"Type" : "CycleHubs", "Direction" : "Forward"}
#var destination = {"Type" : "FinishLevel",}

var spawn_positions = []

var cam = null

func _process(_delta):
	if destination.Type == "HubIntoLevel":
		for character in get_tree().get_nodes_in_group("Character"):
			if not character.AI:
				if character.global_position.distance_squared_to(self.global_position) <= 5*5:
					
					DebugDraw2D.set_text("Level", destination.Level)
					if destination.Level in SaveGame.save_data.ModData[destination.Mod].LevelData:
						
						var level_save_data = SaveGame.save_data.ModData[destination.Mod].LevelData[destination.Level]
						DebugDraw2D.set_text("Minikits", level_save_data.MinikitsFound.count("1"))
						DebugDraw2D.set_text("Story True Jedi", level_save_data.StoryModeStudGoal)
						DebugDraw2D.set_text("Freeplay True Jedi", level_save_data.FreeplayStudGoal)
						DebugDraw2D.set_text("Red Brick", level_save_data.RedBrickCollected)
					else:
						DebugDraw2D.set_text("Minikits", 0)
						DebugDraw2D.set_text("Story True Jedi", false)
						DebugDraw2D.set_text("Freeplay True Jedi", false)
						DebugDraw2D.set_text("Red Brick", false)


func _ready():
	#DEBUG code
	#print(destination)
	#if destination.Type == "FinishLevel":
		#Interface.minikits_collected = 1
		#enter()
	#if "Level" in destination:
		#if destination.Level == "RescueTheWitch":
			#enter()
	
	connect("body_entered", body_entered)
	
	collision_mask = 3
	
	add_to_group("Door")


func body_entered(body):
	
	if body.is_in_group("Character"):
		if not body.AI:
			enter()


func enter():
	if destination.Type == "HubIntoLevel":
		# entering into level
		var level_save_data = SaveGame.save_data.ModData[destination.Mod].LevelData[destination.Level]
		if level_save_data.LevelState == SaveGame.LevelState.UNLOCKED:
			Levels.hub_into_level(destination.Mod, destination.Level, self)#, player_data)
	elif destination.Type == "CycleHubs":
		
		var player_data = Interface.get_player_data()
		#var player_data = []
		#
		#for character in get_tree().get_nodes_in_group("Character"):
			#if character.player:
				#player_data.append(null)
		#
		#for character in get_tree().get_nodes_in_group("Character"):
			#if character.player:
				#player_data[character.player_number] = {"Char" : character.current_filename, "Mod" : character.origin_mod}
		
		Levels.cycle_hubs("Basic Characters", player_data, destination.Direction)
	elif destination.Type == "SectionChange":
		
		Levels.change_section(destination.Section, destination.DoorId)
	elif destination.Type == "Visual":
		pass
	elif destination.Type == "FinishLevel":
		Levels.finish_level()
