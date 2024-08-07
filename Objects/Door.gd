extends Area3D

var DoorId = null

var destination = {}#{"Type" : "SectionChange", "Section" : "HangarA", "DoorId" : 0}
#var destination = {"Type" : "Visual"}
#var destination = {"Type" : "HubIntoLevel", "Mod" : "Basic Characters", "Level" : "SandStuff"}
#var destination = {"Type" : "CycleHubs", "Direction" : "Forward"}
#var destination = {"Type" : "EndLevel",}

var spawn_positions = []

func _ready():
	
	connect("body_entered", enter_door)
	
	collision_mask = 3
	
	add_to_group("Door")


func enter_door(body):
	
	if body.is_in_group("Character"):
		
		if not body.AI:
			
			if destination.Type == "HubIntoLevel":
				# entering into level
				
				Levels.hub_into_level(destination.Mod, destination.Level)#, player_data)
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





