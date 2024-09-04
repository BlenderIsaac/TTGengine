extends "Level.gd"

var level_created_mod

@warning_ignore("unused_parameter")
func CREATE_LEVEL(N_mod, N_level_name, N_section):
	
	level_created_mod = N_mod
	
	var gltf_path = SETTINGS.mod_path+"/"+N_mod+"/levels/leveldata/"+N_level_name+"/"+N_section+"/"+N_section+".glb"#+N_level_section+"/"+N_level_section+".json"
	var ttgl_path = SETTINGS.mod_path+"/"+N_mod+"/levels/leveldata/"+N_level_name+"/"+N_section+"/"+N_section+".ttgl"
	
	var gltf = generate_gltf(gltf_path)
	gltf.name = "LEVEL_GLTF"
	
	var text = FileAccess.open(ttgl_path, FileAccess.READ)
	
	var mode = ""
	var modes = ["OBJECTS", "SCENE"]
	player_spawns = []
	team_spawns = []
	
	var static_body = StaticBody3D.new()
	static_body.hide()
	static_body.add_to_group("respawnable")
	static_body.name = "LEVEL_COLLISION"
	add_child(static_body)
	
	# name indexes
	var stud_idx = 0
	var point_idx = 0
	var sun_idx = 0
	var col_idx = 0
	var nav_idx = 0
	var blwup_idx = 0
	var door_idx = 0
	var anim_idx = 0
	var kill_area_idx = 0
	var cam_idx = 0
	
	while !text.eof_reached():
		
		var line = text.get_line()
		
		if line in modes:
			mode = line
			continue
		
		if line != "":
			match mode:
				"OBJECTS":
					var array = line.split(",")
					var obj_type = array[0]
					
					var properties = get_properties(array.slice(1))
					
					var props = properties.PROPERTIES
					var attr = properties.ATTRIBUTES
					
					if obj_type == "REF":
						
						# ref
						
						if attr.has("PLAYER_SPAWN"):
							var spawn = {}
							spawn.Num = int(props.NUMBER)
							spawn.Mod = props.MOD
							spawn.Char = props.CHARACTER
							spawn.Pos = props.POSITION
							
							player_spawns.append(spawn)
						if attr.has("ENEMY_SPAWN"):
							var dead = false
							
							if Levels.char_spawn_dead.has(N_section):
								if Levels.char_spawn_dead[N_section].has(char_index):
									dead = true
							
							if !dead:
								generate_char(props.CHARACTER, props.MOD, props.POSITION)
							
							char_index += 1
					#elif obj_type == "CMR_CRV":
						#var camera_curve_path = gltf_path.trim_suffix(".glb") + "Curve" + array[1] + ".obj"
						#
						#add_child(generate_curve(camera_curve_path))
					elif obj_type == "NAV_LNK":
						add_child(create_navlink(Vector3(0, 0, 0), props.POSITION_FROM, props.POSITION_TO, props.LINKS, props.BIDI))
					elif obj_type == "STUD":
						var new_stud = l.get_load("res://Objects/Stud.tscn").instantiate()
						
						new_stud.position = props.POSITION
						new_stud.sleeping = true
						new_stud.freeze = true
						new_stud.infinite = true
						new_stud.set_type(props.TYPE.capitalize())
						new_stud.name = "Stud"+str(stud_idx)
						stud_idx += 1
						
						add_child(new_stud)
					elif obj_type == "SUN":
						var point = DirectionalLight3D.new()
						point.position = props.POSITION
						
						var rot = props.ROTATION
						
						point.rotation = rot
						point.rotate_object_local(Vector3(1, 0, 0), -PI/2)
						point.light_energy = float(props.ENERGY)
						point.light_color = props.COLOUR
						point.shadow_enabled = props.SHADOW
						point.name = "Sun"+str(sun_idx)
						sun_idx += 1
						
						add_child(point)
					elif obj_type == "POINT":
						var point = OmniLight3D.new()
						
						point.position = props.POSITION
						point.light_energy = float(props.ENERGY)
						point.light_color = props.COLOUR
						point.shadow_enabled = props.SHADOW
						point.omni_range = 10
						point.name = "Point"+str(point_idx)
						point_idx += 1
						
						add_child(point)
					else:
						# not ref
						var obj = gltf.get_node_or_null(array[1])
						
						#if attr.has("COL"):
							#print(array[1])
						
						if obj:
							@warning_ignore("unused_variable")
							
							if attr.has("COL"):
								
								if attr.has("ANIM"):
									var animated_body = CharacterBody3D.new()
									if not obj is MeshInstance3D:
										var is_acutal_obj = obj.get_node_or_null(str(obj.name))
										if is_acutal_obj:
											obj = is_acutal_obj
									
									var col = generate_box_col(obj, "Collision"+str(col_idx))
									
									animated_body.add_child(col)
									
									obj.add_child(animated_body)
								else:
									
									var col = generate_col(obj.mesh)
									col.transform = f.transform_based_on_parent(gltf, obj)#obj.transform
									static_body.add_child(col)
									col.name = "Collision"+str(col_idx)
								
								col_idx += 1
							
							if attr.has("NAV"):
								var nav = generate_nav(obj.mesh)
								nav.transform = obj.transform
								nav.name = "Navigation"+str(nav_idx)
								nav_idx += 1
								add_child(nav)
							
							if obj_type == "MATTE":
								var mesh_obj = obj
								
								if !mesh_obj is MeshInstance3D:
									obj = obj.get_node(str(obj.name))
								
								var idx = 0
								for matte in props.MATERIALS:
									
									if !obj.get_surface_override_material_count() <= idx:
										
										obj.set_surface_override_material(idx, matte)
									
									idx += 1
							elif obj_type == "BLWUP":
								if true:
									# add materials to the object
									var idx = 0
									for matte in props.MATERIALS:
										
										obj.set_surface_override_material(idx, matte)
										
										idx += 1
									
									# create the static body
									var static_bod = StaticBody3D.new()
									static_bod.transform = obj.transform
									static_bod.name = "Blowup"+str(blwup_idx)
									
									# reparent the object
									obj.get_parent().add_child(static_bod)
									obj.get_parent().remove_child(obj)
									obj.transform = Transform3D()
									obj.owner = null
									static_bod.add_child(obj)
									
									# generate collision
									var col = generate_box_col(obj, "BlowupCol"+str(blwup_idx))
									static_bod.add_child(col)
									
									#var col = generate_convex_col(obj.mesh)
									#col.transform = obj.transform
									
									# set the script and stud value
									static_bod.set_script(l.get_load("res://Objects/BreakableObject.gd"))
									static_bod.stud_value = int(props.STUDS_DROPPED)
									static_bod.aim_pos = Vector3(0, obj.get_aabb().size.y/2, 0)
									
									blwup_idx += 1
							elif obj_type == "CMR_CRV":
								if obj is MeshInstance3D:
									var nav = generate_cam_nav(obj.mesh)
									nav.transform = obj.transform
									nav.name = "CameraCurve"+str(cam_idx)
									nav.set_navigation_layer_value(1, false)
									nav.set_navigation_layer_value(8, true)
									nav.add_to_group("CamCurve")
									
									cam_idx += 1
									add_child(nav)
									
									obj.hide()
							elif obj_type == "ANIM":
								
								var area = generate_area(obj, "AnimArea"+str(anim_idx), "AnimCol"+str(anim_idx))
								anim_idx += 1
								
								area.set_script(l.get_load("res://Objects/AreaAnim.gd"))
								
								area.props = props
								area.attr = attr
								area.gltf = gltf
								
								obj.add_child(area)
								obj.hide()
							elif obj_type == "DOOR":
								var door = generate_area(obj, "Door"+str(door_idx), "DoorCol"+str(door_idx))
								door.rotation = obj.rotation
								door.set_script(l.get_load("res://Objects/Door.gd"))
								
								door.DoorId = int(props.ID)
								var door_dest = {}
								match props.TYPE:
									"HUB_NTO_LVL":
										door_dest["Type"] = "HubIntoLevel"
										door_dest["Mod"] = props.MOD
										door_dest["Level"] = props.LEVEL
									"SECTN_CHNG":
										door_dest["Type"] = "SectionChange"
										door_dest["Section"] = props.NEWSECTION
										door_dest["DoorId"] = int(props.NEWDOORID)
									"FNSH_LVL":
										door_dest["Type"] = "FinishLevel"
									"CYCL_HUB":
										door_dest["Type"] = "CycleHubs"
										door_dest["Direction"] = "Forward"
										if !props.ANTICLOCKWISE:
											door_dest["Direction"] = "Backward"
									"VIS":
										door_dest["Type"] = "Visual"
								
								door.destination = door_dest
								
								if props.TYPE != "FNSH_LVL":
									door.spawn_positions.append(props.POSITION_0)
									door.spawn_positions.append(props.POSITION_1)
								
								#var destination = {"Type" : "SectionChange", "Section" : "HangarA", "DoorId" : 0}
								#var destination = {"Type" : "Visual"}
								#var destination = {"Type" : "HubIntoLevel", "Mod" : "Basic Characters", "Level" : "SandStuff"}
								#var destination = {"Type" : "CycleHubs", "Direction" : "Forward"}
								#var destination = {"Type" : "FinishLevel",}
								
								obj.add_child(door)
								
								obj.hide()
								
								door_idx += 1
							elif obj_type == "MOD_OBJ":
								
								match props.TYPE:
									"gen_PUSH":
										obj.set_script(l.get_load("res://Box.gd"))
									"lsw_JEDI_DOOR":
										obj.set_script(l.get_load("res://SaberWall.gd"))
									"gen_LEVER":
										obj.set_script(l.get_load("res://Objects/Lever.gd"))
									"gen_PANEL":
										obj.set_script(l.get_load("res://Objects/Panel.gd"))
								
								if "props" in obj:
									obj.props = props
									obj.attr = attr
									obj.gltf = gltf
								
							elif obj_type == "DIE_AREA":
								
								var area = generate_area(obj, "KillArea"+str(kill_area_idx), "KillCol"+str(kill_area_idx))
								area.set_script(l.get_load("res://Levels/DeathZone.gd"))
								obj.add_child(area)
								obj.hide()
							elif obj_type == "COLLECT":
								pass
							elif obj_type == "LOGIC":
								obj.set_script(l.get_load("res://Scripts/LogicLine.gd"))
								obj.gltf = gltf
								
								obj.props = props
								obj.attr = attr
								obj.gltf = gltf
							
							if obj_type == "N":
								obj.hide()
				"SCENE":
					var prop = line.split(":")
					var key = prop[0]
					var value = prop[1]
					
					match key:
						"DefaultMod":
							pass
						"DefaultEnv":
							if pyth_bool(value) == false:
								$Environment.environment = null
						"DefaultSun":
							if pyth_bool(value) == false:
								$DefaultSun.queue_free()
						"WorldColour":
							$Environment.environment = l.get_load("res://Levels/ClearColorEnv.tres")
							$Environment.environment.background_color = value
						"DeathY":
							death_height = float(value)
					
	
	text.close()
	
	
	add_child(gltf)

func get_properties(array):
	var properties = {
		"ATTRIBUTES" : [],
		"PROPERTIES" : {}
	}
	
	for element in array:
		
		if ":" in element:
			
			var key_value = element.split(":")
			var key = key_value[0]
			var value = key_value[1]
			
			if key in ["POSITION", "SCALE"]:
				value = vector_to_godot(value)
			elif key.begins_with("POSITION"):
				value = vector_to_godot(value)
			elif key == "ROTATION":
				value = rot_to_godot(value)
			elif key == "MATERIALS":
				value = material_to_godot(value)
			
			if typeof(value) == typeof(""):
				if value == "True":
					value = true
				elif value == "False":
					value = false
			
			properties.PROPERTIES[key] = value
		else:
			properties.ATTRIBUTES.append(element)
	
	return properties

func pyth_bool(string):
	return string == "True"

func vector_to_godot(vector_string):
	
	vector_string = vector_string.trim_prefix("Vector3(").trim_suffix(")")
	var vector_array = vector_string.split(";")
	
	var vector = Vector3(float(vector_array[0]), float(vector_array[1]), float(vector_array[2]))
	
	return vector

func rot_to_godot(vector_string):
	
	vector_string = vector_string.trim_prefix("Vector3(").trim_suffix(")")
	var vector_array = vector_string.split(";")
	
	var blender_x = float(vector_array[0])
	var blender_y = float(vector_array[1])
	var blender_z = float(vector_array[2])
	
	return Vector3(blender_x, blender_y, blender_z)

func material_to_godot(material_string):
	var materials = []
	var material_arrays = material_string.split(";")
	
	for matte_array in material_arrays:
		var raw_array = matte_array.split("|")
		
		materials.append(decode_material(raw_array))
	
	return materials

func decode_material(matte_array):
	#["1", "Material", "UNSHADED", "ALBEDO-ff4b32ff"]
	# dealing with bad materials
	if matte_array.size() == 2 or matte_array.is_empty() or matte_array[0] == "":
		return MATERIALS.get_basic_material("ffffff", MATERIALS.BasicMatte)
	
	var matte_type = matte_array[2]
	var base_material = MATERIALS.BasicMatte
	
	if matte_type == "PART":
		base_material = MATERIALS.AddMatte
	elif matte_type == "ROUGH":
		base_material = MATERIALS.RoughMatte
	elif matte_type == "UNSHDD":
		base_material = MATERIALS.UnshadedMatte
	elif matte_array.has("METALLIC"):
		base_material = MATERIALS.MetallicMatte
	elif matte_type == "LOAD":
		var path_data = (matte_array[3].trim_prefix("LOADPATH")).split("&")
		var matte_path = f.get_data_path({path_data[0] : path_data[1], "Mod" : level_created_mod})
		return MATERIALS.get_loaded_material(matte_path)
	
	var colour="ffffff"
	var texture
	var normal_texture
	for item in matte_array.slice(3):
		if item.begins_with("ALBEDO"):
			colour = item.trim_prefix("ALBEDO")
		if item.begins_with("PRESET"):
			if matte_array.has("METALLIC"):
				colour = MATERIALS.metallic_material_data[item.trim_prefix("PRESET")]
			else:
				colour = MATERIALS.material_data[item.trim_prefix("PRESET")]
		if item.begins_with("TEXTURE"):
			var texture_string = item.trim_prefix("TEXTURE")
			texture = decode_texture_string(texture_string.split("&"))
		if item.begins_with("NORMAL_TEXTURE"):
			var texture_string = item.trim_prefix("NORMAL_TEXTURE")
			normal_texture = decode_texture_string(texture_string.split("&"))
	
	if texture:
		if normal_texture:
			return MATERIALS.get_texture_normal_material(texture, normal_texture, base_material, colour)
		else:
			return MATERIALS.get_texture_material(texture, base_material, colour)
	else:
		return MATERIALS.get_basic_material(colour, base_material)

func decode_texture_string(array):
	return f.get_data_path({array[0] : array[1], "Mod" : level_created_mod})

func generate_gltf(path):
	var gltf = GLTFDocument.new()
	var gltf_state = GLTFState.new()
	var snd_file = FileAccess.open(path, FileAccess.READ)
	var fileBytes = PackedByteArray()
	fileBytes = snd_file.get_buffer(snd_file.get_length())
	
	gltf.append_from_buffer(fileBytes, "base_path?", gltf_state)
	var node = gltf.generate_scene(gltf_state)
	
	return node

func generate_col(mesh):
	
	var shape = mesh.create_trimesh_shape()
	
	var c = CollisionShape3D.new()
	
	c.shape = shape
	
	return c

func generate_convex_col(mesh):
	
	var shape = mesh.create_convex_shape(true, true)
	
	var c = CollisionShape3D.new()
	
	c.shape = shape
	
	return c


func generate_area(obj, area_name, col_name):
	var area = Area3D.new()
	area.name = area_name
	var col = CollisionShape3D.new()
	col.name = col_name
	var shape = BoxShape3D.new()
	
	shape.size = obj.mesh.get_aabb().size*obj.scale
	
	area.add_child(col)
	col.shape = shape
	#area.position = obj.position
	#area.rotation = obj.rotation
	
	return area


func generate_cam_nav(mesh):
	
	var nav_mesh = NavigationMesh.new()
	nav_mesh.cell_size = 0.1
	nav_mesh.agent_radius = 0.1
	nav_mesh.agent_max_climb = 1.0
	nav_mesh.agent_max_slope = 90
	var n = NavigationRegion3D.new()
	
	var source_data = NavigationMeshSourceGeometryData3D.new()
	source_data.add_mesh(mesh, Transform3D())
	
	NavigationMeshGenerator.bake_from_source_geometry_data(nav_mesh, source_data)
	
	n.navigation_mesh = nav_mesh
	
	return n


func generate_nav(mesh):
	
	var nav_mesh = NavigationMesh.new()
	var n = NavigationRegion3D.new()
	
	var source_data = NavigationMeshSourceGeometryData3D.new()
	source_data.add_mesh(mesh, Transform3D())
	
	NavigationMeshGenerator.bake_from_source_geometry_data(nav_mesh, source_data)
	
	n.navigation_mesh = nav_mesh
	
	return n

var curve_idx = 0
func generate_curve(path):
	var curve = CurveObjImport.import_curve(path)
	
	for child in curve.get_children():
		child.add_to_group("CAMCURVE")
	
	curve.name = "CamCurve" + str(curve_idx)
	curve_idx += 1
	
	return curve


func generate_box_col(obj, col_name):
	var col = CollisionShape3D.new()
	col.name = col_name
	var shape = BoxShape3D.new()
	var aabb = obj.mesh.get_aabb()
	shape.size = aabb.size*obj.scale
	col.shape = shape
	col.position = aabb.position + shape.size/2
	
	return col


var group_nav_layers = {
	"Jump" : 1,
	"Fall" : 2,
	"DoubleJump" : 3,
	"Jetpack" : 4,
	"Grapple" : 5,
	"Shortie" : 6,
	"Slide" : 1,
}

var navlink_idx = 0
func create_navlink(pos, from, to, groups, bidi):
	var new_NavLink = NavigationLink3D.new()
	
	new_NavLink.position = pos
	new_NavLink.start_position = from
	new_NavLink.end_position = to
	new_NavLink.bidirectional = bidi
	
	new_NavLink.navigation_layers = 0
	
	for group in groups.split(";"):
		
		if group_nav_layers.has(group):
			new_NavLink.set_navigation_layer_value(group_nav_layers.get(group), true)
		
		new_NavLink.add_to_group("Link"+group)
	
	new_NavLink.name = "NavLink"+str(navlink_idx)
	navlink_idx += 1
	
	return new_NavLink


func _on_timer_2_timeout():
	Levels.finish_level()
