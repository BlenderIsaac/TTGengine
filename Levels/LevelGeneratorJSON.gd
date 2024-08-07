extends "Level.gd"


func CREATE_LEVEL(N_mod, N_level_name, N_level_section):
	var level_path = SETTINGS.mod_path+"/"+N_mod+"/levels/leveldata/"+N_level_name+"/"+N_level_section+"/"+N_level_section+".json"
	
	var leveldata = load_leveldata(level_path)
	
	generate(leveldata, N_level_name, N_mod, N_level_section)


func generate(leveldata, gen_level_name, gen_mod, gen_section):
	section = gen_section
	
	var path = SETTINGS.mod_path+"/"+gen_mod+"/levels/leveldata/"+gen_level_name
	
	if leveldata.has("Mesh"):
		for mesh_data in leveldata.Mesh:
			var config = {}
			
			if mesh_data.has("Config"):
				config = mesh_data.Config
			
			var data_path = f.get_data_path(mesh_data, gen_mod)
			var mesh = generate_mesh(data_path, config)
			
			add_child(mesh)
			
			if mesh_data.has("Materials"):
				var matte_datas = mesh_data.Materials
				
				for matte_id in matte_datas:
					
					var matte_data = matte_datas.get(matte_id)
					
					var matte = MATERIALS.get_matte(matte_data, gen_mod)
					
					mesh.set_surface_override_material(int(matte_id), matte)
	
	
	if leveldata.has("Col"):
		var cols = []
		var configs = []
		
		for col_data in leveldata.Col:
			var config = {}
			
			if col_data.has("Config"):
				config = col_data.Config
			
			cols.append(f.get_data_path(col_data, gen_mod))
			configs.append(config)
		
		add_child(generate_static_body(cols, configs))
	
	
	if leveldata.has("Nav"):
		for nav_data in leveldata.Nav:
			var config = {}
			
			if nav_data.has("Config"):
				config = nav_data.Config
			
			add_child(generate_nav(f.get_data_path(nav_data, gen_mod), config))
	
	if leveldata.has("NavLinks"):
		for navlink_file in leveldata.NavLinks:
			load_navlink_file(navlink_file.Path, gen_level_name, mod)
	
	if leveldata.has("Scenes"):
		# loop through the scenes
		for scene in leveldata.Scenes:
			
			var config = []
			
			# loop through the configurations
			if scene.has("Config"):
				config = scene.Config
			
			add_child(generate_scene(f.get_data_path(scene, gen_mod), config))
	
	if leveldata.has("DeathY"):
		death_height = leveldata.DeathY
	
	# generate characters
	if leveldata.has("CharSpawn"):
		for CharSpawn in leveldata.CharSpawn:
			var dead = false
			
			if Levels.char_spawn_dead.has(gen_section):
				if Levels.char_spawn_dead[gen_section].has(char_index):
					dead = true
			
			if !dead:
				var char_pos = Vector3(CharSpawn.PosX, CharSpawn.PosY, CharSpawn.PosZ)
				
				generate_char(CharSpawn.Char, CharSpawn.Mod, char_pos)
			
			char_index += 1
	
	# set up cameras
	# TODO: make this have cam areas and stuff
	if leveldata.has("Camera"):
		var campath = generate_scene(path+"/"+leveldata.Camera, [])
		
		var cam = get_node("GameCam")
		
		cam.follow_path = true
		cam.cam_path = campath
		
		add_child(campath)
		
		cam.snap()
	
	if leveldata.has("CamCurves"):
		for curve_filename in leveldata.CamCurves:
			
			var curve_path = path+"/"+curve_filename
			
			add_child(generate_curve(curve_path))
	
	if leveldata.has("Doors"):
		for door_data in leveldata.Doors:
			generate_door(door_data)
	
	player_spawns = leveldata.get("PlayerSpawn", [])
	team_spawns = leveldata.get("TeamSpawn", [])



func load_leveldata(path):
	
	var file = FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	
	file.close()
	
	return data

func generate_scene(path, config=[]):
	var scene = l.get_load(path).instantiate()
	
	# loop through the nodes that are affected
	for node_data in config:
		var node = scene
		
		if node_data.has("Node"):
			node = get_node(node_data.Node)
		
		for variable in node_data.Config.keys():
			
			var value = node_data.Config.get(variable)
			
			if typeof(value) != typeof(node.get(variable)):
				value = str_to_var(value)
			
			node.set(variable, value)
	
	return scene


func generate_mesh(path, _config={}):
	var mesh = ObjParse.load_obj(path)
	
	var m = MeshInstance3D.new()
	
	m.mesh = mesh
	
	MATERIALS.set_materials(mesh, m, mod)
	
	return m


func generate_door(variables):
	
	var door = l.get_load("res://Objects/Door.tscn").instantiate()
	
	var keys = variables.keys()
	var values = variables.values()
	for i in variables.size():
		var key = keys[i]
		var value = values[i]
		
		if typeof(value) != typeof(door.get(key)):
			value = str_to_var(str(value))
		
		door.set(key, value)
	
	add_child(door)


func generate_gltf(path, _config={}):
	var gltf = GLTFDocument.new()
	var gltf_state = GLTFState.new()
	var snd_file = FileAccess.open(path, FileAccess.READ)
	var fileBytes = PackedByteArray()
	fileBytes = snd_file.get_buffer(snd_file.get_length())
	
	gltf.append_from_buffer(fileBytes, "base_path?", gltf_state)
	var node = gltf.generate_scene(gltf_state)
	
	for child in f.get_all_children(node):
		if child is MeshInstance3D:
			MATERIALS.set_materials(child.mesh, child, mod)
	
	return node


func generate_static_body(paths, _configs={}, _config={}):
	var static_body = StaticBody3D.new()
	
	for path in paths:
		var path_config = {}
		
		if _configs.has(path):
			path_config = _configs.get(path)
		
		static_body.add_child(generate_col(path, path_config))
	
	static_body.add_to_group("respawnable")
	
	return static_body


func generate_col(path, _config={}):
	
	var col = ObjParse.load_obj(path)
	
	var shape = col.create_trimesh_shape()
	
	var c = CollisionShape3D.new()
	
	c.shape = shape
	
	return c


func generate_convex_col(path, _config={}):
	
	var col = ObjParse.load_obj(path)
	
	var shape = col.create_convex_shape()
	
	var c = CollisionShape3D.new()
	
	c.shape = shape
	
	return c


func generate_nav(path, _config={}):
	var mesh = ObjParse.load_obj(path)
	
	var nav_mesh = NavigationMesh.new()
	var n = NavigationRegion3D.new()
	var source_data = NavigationMeshSourceGeometryData3D.new()
	source_data.add_mesh(mesh, Transform3D())
	
	NavigationMeshGenerator.bake_from_source_geometry_data(nav_mesh, source_data)
	
	n.navigation_mesh = nav_mesh
	
	return n


func generate_curve(path, _config={}):
	var curve = CurveObjImport.import_curve(path)
	
	for child in curve.get_children():
		child.add_to_group("CAMCURVE")
	
	return curve

var group_nav_layers = {
	"LinkJump" : 1,
	"LinkFall" : 2,
	"LinkDoubleJump" : 3,
	"LinkJetpack" : 4,
	"LinkGrapple" : 5,
	"LinkShortie" : 6,
	"LinkSlide" : 1,
}

func create_navlink(pos, from, to, groups, bidi):
	var new_NavLink = NavigationLink3D.new()
	
	new_NavLink.position = pos
	new_NavLink.start_position = from
	new_NavLink.end_position = to
	new_NavLink.bidirectional = bidi
	
	new_NavLink.navigation_layers = 0
	
	for group in groups:
		
		if group_nav_layers.has(group):
			new_NavLink.set_navigation_layer_value(group_nav_layers.get(group), true)
		
		new_NavLink.add_to_group(group)
	
	return new_NavLink



func load_navlink_file(file_name, file_level_name, file_mod):
	var path = SETTINGS.mod_path+"/"+file_mod+"/levels/leveldata/"+file_level_name+"/"+file_name
	
	var file = FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	
	for navlink in data.NavLinks:
		var POS = str_to_var("Vector3"+navlink.POS)
		var FROM = str_to_var("Vector3"+navlink.FROM)
		var TO = str_to_var("Vector3"+navlink.TO)
		
		add_child(create_navlink(POS, FROM, TO, navlink.GROUPS, navlink.BIDI))
