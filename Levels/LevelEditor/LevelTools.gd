extends Node3D

var links = []

var current_nav_link = null

func get_pos_under_mouse():
	var cam = get_viewport().get_camera_3d()
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_from = cam.project_ray_origin(mouse_pos)
	var ray_to = ray_from + cam.project_ray_normal(mouse_pos) * 1000
	var space_state = get_world_3d().direct_space_state
	var selection = space_state.intersect_ray(PhysicsRayQueryParameters3D.create(ray_from, ray_to))
	return selection


@onready var options = $HBOX/VBOX/Options
func _process(_delta):
	
	for child in $HBOX/VBOX.get_children():
		if !child == options:
			
			if child.name == options.text:
				child.show()
			else:
				child.hide()
	
	
	if Input.is_action_just_pressed("Click") and options.text == "CharSpawn":
		
		if !check_ui_hovered():
			
			var pos = get_pos_under_mouse()
			
			if pos:
				$Pos.position = pos.position + Vector3(0, 0.01, 0)
				$Pos.show()
				
				$HBOX/VBOX/CharSpawn/Label.text = str(pos.position)
				stored_char_pos = pos.position
				
				DisplayServer.clipboard_set(str(pos.position))
	
	
	if Input.is_action_just_pressed("Click") and $HBOX/VBOX/NavLinks/Online.button_pressed and options.text == "NavLinks":
		if !check_ui_hovered():
			if !current_nav_link:
				var pos = get_pos_under_mouse()
				
				if pos:
					var navlink = l.get_load("res://Levels/LevelEditor/NavLinkVisual.tscn").instantiate()
					
					$NavLink.add_child(navlink)
					
					navlink.position = pos.position
					navlink.groups = get_link_groups()
					navlink.bidirectional = $HBOX/VBOX/NavLinks/Bidirectional.button_pressed
					
					navlink.update_visuals()
					
					current_nav_link = navlink


func _on_save_pressed():
	
	var level_name = get_parent().level_name
	var mod = get_parent().mod
	
	var path = SETTINGS.mod_path+"/"+mod+"/levels/leveldata/"+level_name+"/"+level_name+"NavLinks.json"
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	
	var json_string = JSON.stringify({"NavLinks" : links})
	
	var json_beauty = JSONBeautifier.beautify_json(json_string)
	
	file.store_string(json_beauty)


func _on_load_pressed():
	var level_name = get_parent().level_name
	var mod = get_parent().mod
	
	var path = SETTINGS.mod_path+"/"+mod+"/levels/leveldata/"+level_name+"/"+level_name+"NavLinks.json"
	
	var file = FileAccess.open(path, FileAccess.READ)
	
	if file:
		var data = JSON.parse_string(file.get_as_text())
		
		for child in $NavLink.get_children():
			child.queue_free()
		links.clear()
		
		for navlink in data.NavLinks:
			
			var POS = str_to_var("Vector3"+navlink.POS)
			var FROM = str_to_var("Vector3"+navlink.FROM)
			var TO = str_to_var("Vector3"+navlink.TO)
			
			links.append(
					{
						"POS" : POS,
						"FROM" : FROM,
						"TO" : TO,
						"GROUPS" : navlink.GROUPS,
						"BIDI" : navlink.BIDI,
					}
				)
			
			var NEWNAV = l.get_load("res://Levels/LevelEditor/NavLinkVisual.tscn").instantiate()
			
			$NavLink.add_child(NEWNAV)
			
			NEWNAV.update(POS, FROM, TO, navlink.GROUPS, navlink.BIDI)


func check_ui_hovered():
	
	var group = get_tree().get_nodes_in_group("UiButton")
	
	for child in group:
		if child.is_hovered():
			return true
	
	return false

func get_link_groups():
	
	var groups = []
	for link_group_button in $HBOX/VBOX/NavLinks/Links.get_children():
		
		if link_group_button.button_pressed:
			var link_group = link_group_button.text
			
			groups.append(link_group)
	
	return groups


var stored_char_pos = Vector3()
func _on_add_to_file_pressed():
	var level_path = SETTINGS.mod_path+"/"+get_parent().mod+"/levels/leveldata/"+get_parent().level_name+"/"+get_parent().section+"/"+get_parent().section+".json"
	
	var leveldata = get_parent().load_leveldata(level_path)
	
	if !leveldata.has("CharSpawn"):
		leveldata.CharSpawn = []
	
	leveldata.CharSpawn.append(
		{
			"Mod" : $HBOX/VBOX/CharSpawn/Mod.text,
			"Char" : $HBOX/VBOX/CharSpawn/Char.text,
			"PosX" : stored_char_pos.x,
			"PosY" : stored_char_pos.y,
			"PosZ" : stored_char_pos.z
		}
	)
	
	var beautiful_leveldata = JSONBeautifier.beautify_json(str(leveldata))
	
	var file = FileAccess.open(level_path, FileAccess.WRITE)
	file.store_string(beautiful_leveldata)
	
	file.close()


