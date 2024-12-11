extends Node3D

# A lot of this is cannabilized from LevelGeneratorTTGL and it will need to be rewritten when changes
# to that are made

var c_mod = null

var sound_mod = "Ahsoka Show"
var sounds = {
	"MinikitBuild" : {
		"cSoundsPath" : ["MK-PANEL.WAV"]
	},
	"MinikitWoosh" : {
		"cSoundsPath" : ["JP_OQ_DJUMP.WAV"]
	},
}

func _ready():
	$AudioPlayer.add_library(sounds, sound_mod)

@warning_ignore("unused_signal")
signal piece_added

var model = null

var t = 0.0

var built = 0

var build_up_to = 10

var phase1 = 0.6
var phase1_l = 0.0

var phase2 = 0.3
var phase2_l = 0.0

var phase3 = 0.15
var phase3_l = 0.0

var done = false

func _process(delta):
	#if Input.is_action_just_pressed("Click"):
		#load_model("Ahsoka Show", "Debe")
		#animate(model.get_child(0))
	
	if model:
		$Rotating/Pivoting.rotation.y += delta*2.0
		t += delta
		$Rotating.rotation.z = sin(t*2.0)*0.5
		
		if not done:
			var obj = model.get_child(built)
			if phase1_l > 0:
				phase1_l = clamp(phase1_l-delta, 0.0, phase1)
				obj.scale = f.LerpVector3(Vector3(1, 1, 1), Vector3(0, 0, 0), clamp(0.0, 1.0, phase1_l/phase1))
				if phase1_l <= 0:
					$AudioPlayer.play("MinikitWoosh")
			elif phase2_l > 0:
				
				obj.scale = Vector3(1, 1, 1)
				phase2_l = clamp(phase2_l-delta, 0.0, phase2)
				obj.position = f.LerpVector3(obj.get_meta("og_pos"), obj.get_meta("nu_pos"), clamp(0.0, 1.0, phase2_l/phase2))
				
				if phase2_l <= 0:
					emit_signal("piece_added")
					$AudioPlayer.play("MinikitBuild")
				
			elif phase3_l > 0:
				obj.position = obj.get_meta("og_pos")
				phase3_l = clamp(phase3_l-delta, 0.0, phase3)
				
				var diff = (obj.get_meta("og_pos") - obj.get_meta("nu_pos")).normalized()
				
				model.position = f.LerpVector3(Vector3(0, 0, 0), diff*.3, sin((phase3_l/phase3)*PI))
			else:
				model.position = Vector3(0, 0, 0)
				
				built += 1
				if built < build_up_to:
					animate(model.get_child(built))
				else:
					done = true
	


func animate(_obj):
	phase1_l = phase1
	phase2_l = phase2
	phase3_l = phase3

func play_model(mod, level_name, up_to=10):
	build_up_to = up_to
	load_model(mod, level_name)
	
	built = 0
	if built < build_up_to:
		animate(model.get_child(built))
	else:
		done = true

func load_model(mod, level_name):
	
	c_mod = mod
	var gltf_path = SETTINGS.mod_path+"/"+mod+"/levels/leveldata/"+level_name+"/Minikit/Minikit.glb"
	var ttgl_path = SETTINGS.mod_path+"/"+mod+"/levels/leveldata/"+level_name+"/Minikit/Minikit.ttgl"
	
	var gltf = generate_gltf(gltf_path)
	gltf.name = "MINKIT_GLTF"
	model = gltf
	
	var text = FileAccess.open(ttgl_path, FileAccess.READ)
	
	var into_meat = false
	
	while !text.eof_reached():
		
		var line = text.get_line()
		
		
		if into_meat == true and line != "":
			var array = line.split(",")
			var obj = gltf.get_node_or_null(array[1])
			var obj_type = array[0]
			
			var properties = get_properties(array.slice(1))
			
			var props = properties.PROPERTIES
			var _attr = properties.ATTRIBUTES
			
			if obj:
				@warning_ignore("unused_variable")
				
				if obj_type == "MATTE":
					var mesh_obj = obj
					
					if !mesh_obj is MeshInstance3D:
						obj = obj.get_node(str(obj.name))
					
					var idx = 0
					for matte in props.MATERIALS:
						
						if !obj.get_surface_override_material_count() <= idx:
							
							obj.set_surface_override_material(idx, matte)
						
						idx += 1
		
		if line == "OBJECTS":
			into_meat = true
	
	for obj in gltf.get_children():
		obj.set_meta("og_pos", obj.position)
		obj.translate_object_local(Vector3(0, -3.2, 0))
		obj.set_meta("nu_pos", obj.position)
		obj.scale = Vector3()
	
	
	
	text.close()
	$Rotating/Pivoting.add_child(gltf)


func clear_model():
	if model:
		model.queue_free()
		model = null


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

func vector_to_godot(vector_string):
	
	vector_string = vector_string.trim_prefix("Vector3(").trim_suffix(")")
	var vector_array = vector_string.split(";")
	
	var vector = Vector3(float(vector_array[0]), float(vector_array[1]), float(vector_array[2]))
	
	return vector

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
		var matte_path = f.get_data_path({path_data[0] : path_data[1], "Mod" : c_mod})
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
	return f.get_data_path({array[0] : array[1], "Mod" : c_mod})


func generate_gltf(path):
	var gltf = GLTFDocument.new()
	var gltf_state = GLTFState.new()
	var snd_file = FileAccess.open(path, FileAccess.READ)
	var fileBytes = PackedByteArray()
	fileBytes = snd_file.get_buffer(snd_file.get_length())
	
	gltf.append_from_buffer(fileBytes, "base_path?", gltf_state)
	var node = gltf.generate_scene(gltf_state)
	
	return node
