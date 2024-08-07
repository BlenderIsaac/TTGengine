extends StaticBody3D

var open_range = 5
var open = false
var open_timer = 0.0
var open_time = 3.0

var DoorId = null

var destination = {"Type" : "SectionChange", "Section" : "HangarA", "DoorId" : 0}
#var destination = {"Type" : "Visual"}
#var destination = {"Type" : "HubIntoLevel", "Mod" : "Basic Characters", "Level" : "SandStuff"}
#var destination = {"Type" : "CycleHubs", "Direction" : "Forward"}
#var destination = {"Type" : "EndLevel",}
var door_path = {}#{"LevelPath" : "RescueTheWitch/VesperDoor.gltf", "Mod" : "Ahsoka Show", "Level" : "RescueTheWitch"}

var gltf

func _ready():
	
	add_to_group("Door")
	
	open_timer = open_time
	
	gltf = generate_gltf()
	add_child(gltf)
	
	#position = Vector3(-12, 1.3411, -20)
	#rotation_degrees = Vector3(0, 90, 0)


func _process(delta):
	if open == false:
		if character_near():
			open_timer = open_time
			open = true
			gltf.get_node("AnimationPlayer").play("Open", .1)
	elif open == true:
		open_timer -= delta
		
		if open_timer < 0.0:
			if !character_near():
				gltf.get_node("AnimationPlayer").play("Close", .1)
				open = false
			else:
				open_timer = open_time


func generate_gltf():
	var gltf_document = GLTFDocument.new()
	var gltf_state = GLTFState.new()
	var path = f.get_data_path(door_path, door_path.Mod)
	var snd_file = FileAccess.open(path, FileAccess.READ)
	var fileBytes = PackedByteArray()
	fileBytes = snd_file.get_buffer(snd_file.get_length())
	
	gltf_document.append_from_buffer(fileBytes, "base_path?", gltf_state)
	var node = gltf_document.generate_scene(gltf_state)
	
	#for child in f.get_all_children(node):
		#if child is MeshInstance3D:
			#MATERIALS.set_materials(child.mesh, child, door_path.Mod)
	
	return node


func character_near():
	for character in get_tree().get_nodes_in_group("Character"):
		if character.global_position.distance_to(global_position) < open_range:
			return true
	
	return false


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





