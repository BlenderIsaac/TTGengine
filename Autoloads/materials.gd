extends Node


var material_data = {
	"White" : "F4F4F4",
	"Very Light Gray" : "E8E8E8",
	"Very Light Grey" : "E8E8E8",
	"Very Light Bluish Gray" : "E4E5D9",
	"Very Light Bluish Grey" : "E4E5D9",
	"Light Bluish Gray" : "A3A2A4",
	"Light Bluish Grey" : "A3A2A4",
	"Light Gray" : "A1A5A2",
	"Light Grey" : "A1A5A2",
	"Dark Gray" : "545955",
	"Dark Grey" : "545955",
	"Dark Bluish Gray" : "4D5156",
	"Dark Bluish Grey" : "4D5156",
	"Black" : "101010",
	"Dark Red" : "7C021F",
	"Red" : "D6001E",
	"Coral" : "FF6666",
	"Salmon" : "F06D61",
	"Light Salmon" : "F9B7A5",
	"Sand Red" : "88605E",
	"Dark Brown" : "2E0F06",
	"Brown" : "543324",
	"Light Brown" : "7C503A",
	"Medium Brown" : "755945",
	"Reddish Brown" : "5B2D0E",
	"Fabuland Brown" : "B3694E",
	"Dark Tan" : "8A7553",
	"Medium Tan" : "CCA373",
	"Tan" : "D5BC7C",
	"Light Nougat" : "FAD1B1",
	"Nougat" : "D09168",
	"Medium Nougat" : "B17A49",
	"Earth Orange" : "D86D2C",
	"Dark Orange" : "91501C",
	"Rust" : "B52C20",
	"Orange" : "F57D23",
	"Medium Orange" : "F58624",
	"Bright Light Orange" : "FCB100",
	"Light Orange" : "F9A777",
	"Yellow" : "F8C718",
	"Light Yellow" : "FFE383",
	"Bright Light Yellow" : "FDF683",
	"Neon Yellow" : "E6FF00",
	"Light Lime" : "DEEA92",
	"Yellowish Green" : "E0FC9A",
	"Medium Lime" : "B7D425",
	"Lime" : "94BC0E",
	"Olive Green" : "808452",
	"Dark Green" : "053515",
	"Green" : "157D26",
	"Bright Green" : "1B9822",
	"Medium Green" : "73DCA1",
	"Light Green" : "A5DBB5",
	"Sand Green" : "618365",
	"Dark Turquoise" : "069D9F",
	"Light Turquoise" : "31B5CA",
	"Aqua" : "9CD6CC",
	"Light Aqua" : "D5F2EA",
	"Dark Blue" : "0A2441",
	"Blue" : "2653A7",
	"Dark Azure" : "078BC9",
	"Maersk Blue" : "6BADD6",
	"Medium Azure" : "2ACDE8",
	"Sky Blue" : "77C9D8",
	"Medium Blue" : "558AC5",
	"Bright Light Blue" : "8FBFE9",
	"Light Blue" : "7ED9F2",
	"Sand Blue" : "61738C",
	"Dark Blue-Violet" : "0E3E9A",
	"Violet" : "675BBF",
	"Blue-Violet" : "506CEF",
	"Medium Violet" : "9391E4",
	"Light Violet" : "C1CADE",
	"Dark Purple" : "491D8E",
	"Purple" : "A5499C",
	"Light Purple" : "B4348C",
	"Medium Lavender" : "A06AB9",
	"Lavender" : "CDA1DE",
	"Sand Purple" : "845E84",
	"Magenta" : "98006C",
	"Dark Pink" : "D82E8D",
	"Medium Dark Pink" : "F785B1",
	"Bright Pink" : "EA9BC4",
	"Pink" : "FFC0CB",
	
	# not really real ones
	"Flesh" : "d09168",
	"Light Flesh" : "fad1b1",
	"Medium Flesh" : "CCA373",
}

var material_data2 = {
	"Light Flesh" : "fad1b1",
	"Medium Flesh" : "CCA373",
	"Medium Nougat" : "b17a49",
	"Bright Light Blue" : "8fbfe9",
	"Flesh" : "d09168",
	"White" : "f4f4f4",
	"Red" : "d6001e",
	"Dark Purple" : "5e2980",
	"Black" : "101010",
	"Dark Bluish Grey" : "4d5156",
	"Dark Red" : "7c021f",
	"Reddish Brown" : "581b0f",
	"Tan" : "d5bc7c",
	"Medium Blue" : "558ac5",
	"Light Bluish Grey" : "a3a2a4",
	"Sand Blue" : "61738c",
	"Sand Green" : "618365",
	"Orange" : "f57d23",
	"Blue" : "2653a7",
	"Dark Blue": "0a2441",
	"Yellow" : "f8c718",
	"Green" : "157D26",
	"Pink" : "ffc0cb",
	"Dark Tan" : "8A7553",
	"Dark Brown" : "2e0f06",
}

var metallic_material_data = {
	"Chrome Gold": "DFC176",
	"Chrome Silver": "CECECE",
	"Chrome Antique Brass": "B8925C",
	"Chrome Black": "1B2A34",
	"Chrome Blue": "6C96BF",
	"Chrome Green": "3CB371",
	"Chrome Pink": "AA4D8E",
	"Pearl White": "F6F3EC",
	"Pearl Very Light Gray": "D4D2CD",
	"Pearl Very Light Grey": "D4D2CD",
	"Pearl Light Gray": "A0A0A0",
	"Pearl Light Grey": "A0A0A0",
	"Flat Silver": "8E9496",
	"Bionicle Silver": "A59287",
	"Pearl Dark Gray": "3E3C39",
	"Pearl Dark Grey": "3E3C39",
	"Pearl Black": "282725",
	"Pearl Light Gold": "DEAC66",
	"Pearl Gold": "A68031",
	"Reddish Gold": "E7891B",
	"Bionicle Gold": "B9752F",
	"Flat Dark Gold": "83724F",
	"Reddish Copper": "D57036",
	"Copper": "AC6C53",
	"Bionicle Copper": "985750",
	"Pearl Sand Blue": "5686AE",
	"Pearl Sand Purple": "B5A1BA",
	"Metallic Silver": "C0C0C0",
	"Metallic Green": "899B5F",
	"Metallic Gold": "BB9442",
	"Metallic Copper": "A77768",
	"Milky White": "F4F4F4",
}


var basic_loaded_materials = {}
var texture_loaded_materials = {}
var load_loaded_materials = {}

var tag_particle_colours = {}

var TagParticleMatte = load("res://Materials/TagParticle.tres")
var FlashOverlay = load("res://Materials/FlashOverlay.tres")

var BasicMatte = load("res://Materials/BasicTestMaterial.tres")
var RoughMatte = load("res://Materials/RoughBasicMaterial.tres")
var MetallicMatte = load("res://Materials/MetallicMaterial.tres")
var AddMatte = load("res://Materials/UnshadedAddMaterial.tres")
var UnshadedMatte = load("res://Materials/UnshadedMaterial.tres")

var texture_loads = {}

func load_texture(path):
	
	if not texture_loads.has(path):
		
		#if !SETTINGS.mobile:
			var image = Image.new()
			image.load(path)
			
			texture_loads[path] = ImageTexture.create_from_image(image)
		#else:
			#texture_loads[path] = load(path)
	
	return texture_loads[path]


var valid_types = [
	"Basic",
	"Preset",
	"MetallicBasic",
	"MetallicPreset",
	"TextureMetallic",
	"TextureMetallicPreset",
	"Texture",
	"TexturePreset",
	"Load",
	"TextureAdd",
	"AddBasic",
	"AddPreset",
]

func set_materials(mesh_data, MeshInstance, mod):
	
	# Load the mtl file and set presets by the name of the material
	
	var materials = {}
	
	for surface_index in mesh_data.get_surface_count():
		var matte_name = mesh_data.get(str("surface_", surface_index, "/name"))
		
		var encoded_name = matte_name.replace("_", " ")
		var pairs_of_variables = encoded_name.split(",")
		
		var matte_data = {}
		
		if valid_types.has(pairs_of_variables[0]):
			
			matte_data.Type = pairs_of_variables[0]
			for pair in pairs_of_variables:
				if pair != pairs_of_variables[0]:
					var pair_as_list = pair.split(":")
					
					matte_data[pair_as_list[0]] = pair_as_list[1]
			
			
			materials[surface_index] = matte_data
	
	
	for matte_id in materials.keys():
		
		var matte_data = materials[matte_id]
		
		var matte = get_matte(matte_data, mod)
		
		MeshInstance.set_surface_override_material(int(matte_id), matte)


func set_char_materials(mesh_data, MeshInstance, mod):
	
	# Load the mtl file and set presets by the name of the material
	
	var materials = {}
	
	
	for surface_index in mesh_data.get_surface_count():
		var matte_name = mesh_data.get(str("surface_", surface_index, "/name"))
		
		var encoded_name = matte_name.replace("_", " ")
		var pairs_of_variables = encoded_name.split(",")
		
		var matte_data = {}
		
		if valid_types.has(pairs_of_variables[0]):
			
			matte_data.Type = pairs_of_variables[0]
			for pair in pairs_of_variables:
				if pair != pairs_of_variables[0]:
					var pair_as_list = pair.split(":")
					
					matte_data[pair_as_list[0]] = pair_as_list[1]
			
			
			materials[surface_index] = matte_data
	
	
	for matte_id in materials.keys():
		
		var matte_data = materials[matte_id]
		
		var matte = get_matte(matte_data, mod)
		
		MeshInstance.set_surface_override_material(int(matte_id), matte)


func get_matte(matte_data, origin_mod):
	
	var config = {}
	
	if matte_data.has("Config"):
		config = matte_data.Config
	
	
	var matte_path = f.get_data_path(matte_data, origin_mod)
	match matte_data.Type:
		"Basic":
			return get_basic_material(matte_data.Albedo, BasicMatte)
		"Texture":
			return get_texture_material(matte_path, BasicMatte)
		
		"Preset":
			return get_preset_basic_material(matte_data.Preset, BasicMatte)
		"TexturePreset":
			return get_texture_material(matte_path, BasicMatte, MATERIALS.get_preset(matte_data.Preset))
		
		"AddBasic":
			return get_basic_material(matte_data.Albedo, AddMatte)
		"AddPreset":
			return get_preset_basic_material(matte_data.Preset, AddMatte)
		"TextureAdd":
			return get_texture_material(matte_path, AddMatte)
		
		"Rough":
			return get_basic_material(matte_data.Albedo, RoughMatte)
		"RoughTexture":
			return get_texture_material(matte_path, RoughMatte, matte_data.Albedo)
		"RoughPreset":
			return get_preset_basic_material(matte_data.Preset, RoughMatte)
		"RoughTexturePreset":
			return get_texture_material(matte_path, RoughMatte, MATERIALS.get_preset(matte_data.Preset))
		
		"MetallicBasic":
			return get_basic_material(matte_data.Albedo, MetallicMatte)
		"TextureMetallic":
			return get_texture_material(matte_path, MetallicMatte)
		"MetallicPreset":
			return get_preset_basic_material(matte_data.Preset, MetallicMatte)
		"TextureMetallicPreset":
			return get_texture_material(matte_path, MetallicMatte, MATERIALS.get_preset(matte_data.Preset))
		
		"Load":
			return get_loaded_material(matte_path, config)


func get_preset(preset):
	return material_data.get(preset)

func get_texture_material(texture, matte, albedo="ffffff"):
	
	var reference = texture+albedo+str(matte)
	
	if texture_loaded_materials.has(reference):
		return texture_loaded_materials.get(reference)
	else:
		var new_matte = matte.duplicate()
		
		new_matte.albedo_texture = load_texture(texture)
		new_matte.albedo_color = albedo
		
		texture_loaded_materials[reference] = new_matte
		
		return new_matte

func get_texture_normal_material(texture, normal, matte, albedo="ffffff"):
	var reference = texture+albedo+normal+str(matte)
	
	if texture_loaded_materials.has(reference):
		return texture_loaded_materials.get(reference)
	else:
		var new_matte = matte.duplicate()
		
		new_matte.albedo_texture = load_texture(texture)
		new_matte.normal_enabled = true
		new_matte.normal_texture = load_texture(normal)
		new_matte.albedo_color = albedo
		
		texture_loaded_materials[reference] = new_matte
		
		return new_matte


func get_tag_part_material(colour):
	if tag_particle_colours.has(colour):
		return tag_particle_colours.get(colour)
	else:
		var new_matte = TagParticleMatte.duplicate()
		
		new_matte.albedo_color = colour
		
		tag_particle_colours[colour] = new_matte
		
		return new_matte


func get_loaded_material(path, config={}):
	if load_loaded_materials.has(path+str(config)):
		return load_loaded_materials.get(path+str(config))
	else:
		
		var new_matte = l.get_load(path).duplicate()
		
		for c in config:
			new_matte.set(c, config.get(c))
		
		load_loaded_materials[path+str(config)] = new_matte
		
		return new_matte


func get_basic_material(colour, matte):
	
	if basic_loaded_materials.has(str(colour, " ", matte)):
		return basic_loaded_materials.get(str(colour, " ", matte))
	else:
		var new_matte = matte.duplicate()
		
		new_matte.albedo_color = colour
		
		basic_loaded_materials[str(colour, " ", matte)] = new_matte
		
		return new_matte

func get_preset_basic_material(preset_colour, matte):
	
	var data = material_data
	if matte == MetallicMatte:
		data = metallic_material_data
	
	if data.has(preset_colour):
		return get_basic_material(data.get(preset_colour), matte)
	else:
		printerr("ERROR: preset material "+preset_colour+" does not exist")
		return
