extends "res://Levels/Level.gd"

#func snapped_vec2(vec2, value):
#	return Vector2(snapped(vec2.x, value), snapped(vec2.y, value))
#
#
#func get_object_under_mouse():
	#var cam = $Cam
	#var mouse_pos = get_viewport().get_mouse_position()
	#var ray_from = cam.project_ray_origin(mouse_pos)
	#var ray_to = ray_from + cam.project_ray_normal(mouse_pos) * 1000
	#var space_state = get_world_3d().direct_space_state
	#var selection = space_state.intersect_ray(PhysicsRayQueryParameters3D.create(ray_from, ray_to))
	#return selection


func _on_temp_spawner_timeout():
	
	if SETTINGS.spawn_troops == "true":
		var node = $Level/TEMPSpawnings
		var next_spawn_ind = randi_range(0, node.get_child_count()-1)
		var next_spawn = node.get_child(next_spawn_ind)
		var new_ai
		
		var char_mod = "Basic Characters"
		var char_path = SETTINGS.mod_path+"/"+mod+"/characters/chars/"
		
		var randy = randf_range(0, 10)
		
		if randy < 7:
			new_ai = spawn_char_from_file(char_path+"Stormtrooper.json", char_mod)
		elif randy < 8.5:
			new_ai = spawn_char_from_file(SETTINGS.mod_path+"/Fallen Order/characters/chars/"+"PurgeTrooperGun.json", "Fallen Order")
		elif randy < 9.5:
			new_ai = spawn_char_from_file(SETTINGS.mod_path+"/Fallen Order/characters/chars/"+"PurgeTrooperStaff.json", "Fallen Order")
		else:
			new_ai = spawn_char_from_file(char_path+"GrandInquisitor.json", char_mod)
		
		if new_ai:
			new_ai.position = next_spawn.global_position + Vector3(randf()/4, randf()/4, randf()/4)
			
			add_child(new_ai)

