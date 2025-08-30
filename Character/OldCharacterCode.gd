extends Node
class_name CharacterManager


# This function gets dict from a character file
static func get_character_file_dict(file : String):
	# Read the file and get it as a dictionary
	var file_access = FileAccess.open(ResourceManager.CharactersFolderLoadDir.new().get_dir() + file + ".json", FileAccess.READ)
	var dict = JSON.parse_string(file_access.get_as_text())
	
	# Close the file (important)
	file_access.close()
	
	return dict


# This function takes a character file and runs it through the inherit chain recursively
static func complete_character_file_dict(dict):
	
	if dict.has("Inherits"):
		var inherited_data = complete_character_file_dict(get_character_file_dict(dict.Inherits))
		
		for key in dict.keys():
			var value = dict.get(key)
			
			if key.begins_with("#"):
				
				if typeof(value) == typeof({}):
					
					# dictionary editing
					for sub_key in value.keys():
						inherited_data[key.lstrip("#")][sub_key] = value.get(sub_key)
				elif typeof(value) == typeof([]):
					for element in value:
						var replace_instead = false
						
						if key == "#Logics":
							var idx = 0
							
							for d in inherited_data.Logics:
								if d.cLogicsPath == element.cLogicsPath:
									replace_instead = true
									inherited_data[key.lstrip("#")][idx] = element
								
								idx += 1
						elif key == "#Animations":
							var idx = 0
							
							for d in inherited_data.Animations:
								if d.Name == element.Name:
									replace_instead = true
									inherited_data[key.lstrip("#")][idx] = element
								
								idx += 1
						
						
						if not replace_instead:
							inherited_data[key.lstrip("#")].append(element)
				
			else:
				inherited_data[key] = value
		
		return inherited_data
	else:
		return dict


# This function sets us to a particular character based off dict
static func change_character(dict, c_path, mod): # TODO: We don't need c_path here once we remove current_character_filename
	
	current_filename = ""
	
	$Agent.navigation_layers = 0
	
	origin_mod = mod
	
	# Clear all current audio loops
	$AudioPlayer.clear_loops()
	
	if dict.has("Faction"):
		if typeof(dict.Faction) == TYPE_ARRAY:
			faction = dict.Faction
		else:
			faction = [dict.Faction]
	alignment = dict.get("Alignment", 0)
	
	
	# change name
	if dict.has("Name"):
		char_name = dict.Name
	
	# add sounds
	$AudioPlayer.clear()
	if dict.has("Sounds"):
		
		var all_sounds = initial_sounds.duplicate()
		
		for sound in dict.Sounds.keys():
			var value = dict.Sounds.get(sound)
			
			all_sounds[sound] = value
		
		for key in all_sounds:
			var value = all_sounds.get(key)
			
			for path_type in value.keys():
				var sound_list = value.get(path_type)
				
				for sound in sound_list:
					$AudioPlayer.add_sound(f.get_data_path({path_type : sound}, origin_mod), key, origin_mod)
		
		#for title in dict.Sounds.keys():
			## issue here
			#$AudioPlayer.add_sound(dict.Sounds.get(title), title, origin_mod)
			## add config and randomization of sounds
		#for sound in initial_sounds.keys():
			#$AudioPlayer.add_sound(initial_sounds.get(sound), sound, origin_mod)
	
	# Setup the Icon using the Materials autoload
	if dict.has("Icon"):
		icon = Materials.load_texture(SETTINGS.mod_path+"/"+origin_mod+"/characters/icons/"+dict.Icon)
	else:
		icon = null
	
	var old_max = max_hit_points
	var old_h = hit_points
	var old_ratio = old_h/old_max
	# If the dict specifies health then set our new health to it
	if dict.has("Health"):
		max_hit_points = dict.Health
	else:
		max_hit_points = 4.0
	
	if dict.has("AI_Health"):
		ai_hit_points = dict.AI_Health
	else:
		ai_hit_points = max_hit_points
	
	if dict.has("HeartsPerRow"):
		hearts_per_row = dict.HeartsPerRow
	else:
		hearts_per_row = -1
	
	if dict.has("HeartXOffset"):
		heart_x_offset = dict.HeartXOffset
	else:
		heart_x_offset = 30
	
	if !health_ratio_accurate:
		health_ratio = old_ratio
	
	hit_points = ceil(health_ratio*max_hit_points)
	health_ratio_accurate = true
	#if old_max == old_h:
	# find how many health we were off max
	#if hit_points != 1:
	#	
	#	var diff = old_max - old_h
	#	var new_health = max_hit_points - clamp(diff, 0, max_hit_points-1)
	#	
	#	hit_points = new_health
	
	update_hearts()
	
	
	if dict.has("Collision"):
		collision_scene = dict.Collision
	else:
		collision_scene = "CharacterCollision.tscn"
	
	var current_col = get_node_or_null("Col")
	var current_push_col = get_node_or_null("Pushaway/Col")
	var col_load = l.get_load(SETTINGS.mod_path+"/"+origin_mod+"/characters/collisions/"+collision_scene)
	
	if current_col:
		#current_col.name = "ColDelete"
		current_col.free()
	if current_push_col:
		#current_col.name = "ColPushDelete"
		current_push_col.free()
	
	var new_col:CollisionShape3D = col_load.instantiate()
	var new_push_col:CollisionShape3D = col_load.instantiate()
	var new_cast_shape = new_col.shape.duplicate()
	
	add_child(new_col)
	new_col.name = "Col"
	
	$Pushaway.add_child(new_push_col)
	new_push_col.name = "Col"
	
	$TailCast.shape = new_cast_shape
	$TailCast.position = new_col.position
	
	# delete current rig
	var m = get_node_or_null("Mesh")
	var m_rot = Vector3()
	if m:
		m_rot = m.rotation
		
		m.name = "DeletingMesh"
		m.queue_free()
	
	# create rig/subrig
	var rig_name = "GenRig.tscn"
	var subrig_name = null
	
	if dict.has("Rig"):
		rig_name = dict.Rig
	
	if dict.has("SubRig"):
		subrig_name = dict.SubRig
	
	current_rig = rig_name
	subrig = subrig_name
	
	if subrig_name != null:
		rig_name = subrig_name
	
	
	
	var rig_path = SETTINGS.mod_path+"/"+origin_mod+"/characters/rigs/"+rig_name
	#var rig# = 
	var rig_instance# = l.get_load(rig_path).instantiate()
	
	if subrig_name.ends_with(".glb"):
		rig_instance = f.generate_gltf(rig_path)
		rig_instance.rotation_degrees.y += 90.0
		#var rooot = BoneAttachment3D.new()
		#m_rot.x = -PI/2
		#rooot.bone_idx = 0
		#rooot.name = "ROOT"
		#rooot.override_pose = true
		#rig_instance.get_node("Armature/Skeleton3D").add_child(rooot)
	else:
		m_rot.x = 0
		rig_instance = l.get_load(rig_path).instantiate()
	
	add_child(rig_instance)
	rig_instance.name = "Mesh"
	rig_instance.rotation = m_rot
	
	
	# replace parts
	if dict.has("ReplaceParts"):
		for part_name in dict.ReplaceParts:
			var new_part_filename = dict.ReplaceParts.get(part_name)
			
			var parts_path = SETTINGS.mod_path+"/"+origin_mod+"/characters/rigs/replacers/"+new_part_filename
			var new_part = f.generate_gltf(parts_path)
			var part_mesh = new_part.get_child(0).get_child(0).get_child(0)
			new_part.get_child(0).get_child(0).remove_child(part_mesh)
			new_part.free()
			new_part = part_mesh
			
			var skeleton = rig_instance.get_node("Armature/Skeleton3D")
			var current_part = skeleton.get_node(part_name)
			
			current_part.name = "DelMe"
			current_part.free()
			
			new_part.name = part_name
			skeleton.add_child(new_part)
			#new_part.skeleton = NodePath("..")
	
	anim = $Mesh/AnimationPlayer
	anim.playback_process_mode = 0
	
	# hide particular bits
	if dict.has("HideParts"):
		for part in dict.HideParts:
			get_node("Mesh/Armature/Skeleton3D/"+part).hide()
	
	# Get the meshes and set bit to it
	bits = get_armature_bits()
	
	# Reset the modulation and create a new list of meshes_to_modulate
	reset_modulation()
	
	# generate models
	if dict.has("Models"):
		var attach_no = 0
		for model in dict.Models:
			if model.Type == "Model":
				var p = f.get_data_path(model, mod)
				attach_model(p, attach_no, int(model.Bone), model.Materials)
				
				attach_no += 1
			elif model.Type == "SoftBody":
				var p = f.get_data_path(model, mod)
				attach_softbody(p, attach_no, int(model.Bone), model.Materials, model.Indices, model.Offsets)
				
				attach_no += 1
	
	# add materials
	for part_matt_name in dict.Materials.keys():
		var part_matte_data = dict.Materials.get(part_matt_name)
		for matte_id in part_matte_data:
			set_material(part_matt_name, int(matte_id), Materials.get_matte(part_matte_data.get(matte_id), origin_mod))
	
	# get the parent of the logics
	var LogicParent = get_node("Logic")
	
	# create the base logic
	base_state = dict.BaseState
	
	# I don't know if logic_switched_vars is necessary
	# delete all current logics
	for logic in LogicParent.get_children():
		if logic.has_method("get_switched_var"):
			logic_switched_vars[logic.logic_name()] = logic.get_switched_var()
		
		if logic.has_method("reset"):
			logic.reset()
		
		logic.free()
	
	# loop through all the logics and create them
	for logic in dict.Logics:
		var config = {}
		
		if logic.has("Config"):
			config = logic.Config
		
		var data_path = f.get_data_path(logic, mod)
		
		if SETTINGS.use_internal_logics == "true":
			data_path = "res://Logic/" + logic.cLogicsPath
		
		add_logic(data_path, config, logic_switched_vars)
	
	# store current animation
	var anim_player = $Mesh/AnimationPlayer
	
	# Remove a library if one exists and add a new blank one.
	if anim_player.has_animation_library(""):
		anim_player.remove_animation_library("")
	anim_player.add_animation_library("", AnimationLibrary.new())
	
	# add the animations
	if dict.has("Animations"):
		for anim_name in dict.Animations:
			var new_anim = l.get_load(f.get_data_path(anim_name, mod))
			
			add_animation(anim_name.Name, new_anim)
	
	anim_player.connect("animation_started", anim_started)
	
	#get_base_movement_state().C = self
	var switch_anim = get_base_movement_state().get_switch_anim()
	anim_player.play(switch_anim[0], 0.0)
	anim_player.seek(switch_anim[1], true)
	
	# show which character we are
	current_path = c_path
	
	# remove our weapon
	weapon_prefix = ""
	
	# set the movement state to our base state
	reset_movement_state()
	
	# if we are inside the tree and have access to the hud update it
	if is_inside_tree():
		update_HUD()
