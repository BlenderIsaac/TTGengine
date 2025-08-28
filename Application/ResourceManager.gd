extends Node
class_name ResourceManagerClass

var loaded_resources : Dictionary = {}
var current_mod : String
var audio_loader : AudioLoader

func _ready():
	audio_loader = AudioLoader.new()

#region Load Dirs

class LoadDir:
	func get_dir():
		return ""

class ModFolderLoadDir extends LoadDir:
	var mod : String = ""
	
	func get_mod():
		if mod != "":
			return mod
		
		return ResourceManager.current_mod
	
	func get_dir():
		return super() + SettingsManager.mod_path + "/" + get_mod() + "/"


class ResLoadDir extends LoadDir:
	func get_dir():
		return "res://"


class LevelsFolderLoadDir extends ModFolderLoadDir:
	func get_dir():
		return super() + "levels/"

class LevelsSharedFolderLoadDir extends LevelsFolderLoadDir:
	func get_dir():
		return super() + "shared/"

class LevelFolderLoadDir extends LevelsFolderLoadDir:
	var level : String
	
	func _init(_level):
		level = _level
	
	func get_dir():
		return super() + "leveldata/" + level + "/"

class SectionFolderLoadDir extends LevelFolderLoadDir:
	var section : String
	
	func _init(_level, _section):
		super(_level)
		section = _section
	
	func get_dir():
		return super() + section + "/"

class CharactersFolderLoadDir extends ModFolderLoadDir:
	func get_dir():
		return super() + "characters/"

class CharFolderLoadDir extends CharactersFolderLoadDir:
	func get_dir():
		return super() + "chars/"

class CharactersRigFolderLoadDir extends CharactersFolderLoadDir:
	func get_dir():
		return super() + "rigs/"

class CharactersSoundFolderLoadDir extends CharactersFolderLoadDir:
	func get_dir():
		return super() + "sounds/"

class CharactersCollisionsFolderLoadDir extends CharactersFolderLoadDir:
	func get_dir():
		return super() + "collisions/"

class CharactersModelsFolderLoadDir extends CharactersFolderLoadDir:
	func get_dir():
		return super() + "models/"

class CharactersGltfsFolderLoadDir extends CharactersFolderLoadDir:
	func get_dir():
		return super() + "gltfs/"

class CharactersAnimsFolderLoadDir extends CharactersFolderLoadDir:
	func get_dir():
		return super() + "anims/"

class CharactersMaterialsFolderLoadDir extends CharactersFolderLoadDir:
	func get_dir():
		return super() + "materials/"

#endregion
#region Textures

class TextureLoadDetails:
	var dir : LoadDir
	var file : String
	
	func _init(_dir : LoadDir, _file : String):
		dir = _dir
		file = _file
	
	func gen():
		return load(dir.get_dir() + file)

class LevelTextureLoadDetails extends TextureLoadDetails:
	func _init(_file, _level):
		dir = LevelFolderLoadDir.new(_level)
		file = _file

#endregion
#region Waveforms (.obj)

var obj_meshes = {}

func load_obj(path : LoadDir, file : String):
	var id = path.get_dir() + file
	if !obj_meshes.has(id):
		var new_obj = load(path.get_dir() + file + ".obj")
		
		obj_meshes[id] = new_obj
	
	return obj_meshes.get(id)


#endregion
#region Materials

class MaterialLoadDetails:
	var base_material = "basic"
	var color = "ffffff"
	var preset_color : String
	var metallic_preset_color : String
	
	var texture : TextureLoadDetails
	var normal_texture : TextureLoadDetails
	
	# for LOAD materials
	var load_path : LoadDir
	var load_file : String
	
	func get_color():
		if metallic_preset_color:
			return ResourceManager.material_data[metallic_preset_color]
		
		if preset_color:
			return ResourceManager.material_data[preset_color]
		
		return color
	
	func get_common_elements():
		return {"m" : base_material, "c" : get_color()}
	
	func get_unique_id():
		var id = get_common_elements()
		
		if base_material in ["flash overlay"]:
			return base_material
		
		if base_material == "load":
			id["lp"] = load_path.get_dir()
			id["lf"] = load_file
		
		if texture:
			id["t"] = texture
		
		if normal_texture:
			id["nt"] = texture
		
		return id
	
	func gen():
		if base_material == "load":
			return load(load_path.get_dir() + load_file)
		
		var matte : StandardMaterial3D = ResourceManager.material_types[base_material].duplicate()
		matte.albedo_color = get_color()
		
		if texture:
			matte.albedo_texture = texture.gen()
		
		if normal_texture:
			matte.normal_enabled = true
			matte.normal_texture = normal_texture.gen()
		
		return matte

var material_loads = {}

var material_types = {
	"basic" : load("res://Materials/BasicTestMaterial.tres"),
	"rough" : load("res://Materials/RoughBasicMaterial.tres"),
	"metallic" : load("res://Materials/MetallicMaterial.tres"),
	"add" : load("res://Materials/UnshadedAddMaterial.tres"),
	"unshaded" : load("res://Materials/UnshadedMaterial.tres"),
	"tag particle" : load("res://Materials/TagParticle.tres"),
	"flash overlay" : load("res://Materials/FlashOverlay.tres")
}

func load_material(details : MaterialLoadDetails):
	var id = details.get_unique_id()
	if not id in material_loads:
		material_loads[id] = details.gen()
	
	return material_loads[id]

#endregion
#region Sounds

class SoundLoadDetails:
	var path : LoadDir
	var file : String
	
	var mod : String
	
	func _init(_path : LoadDir, _file : String):
		path = _path
		file = _file
	
	func get_unique_id():
		return path.get_dir() + file
	
	func gen():
		return ResourceManager.audio_loader.loadfile(path.get_dir() + file)


var sound_loads = {}
func load_sound(details : SoundLoadDetails):
	var id = details.get_unique_id()
	if not id in sound_loads:
		sound_loads[id] = details.gen()
	
	return sound_loads[id]


#endregion
#region Characters

class CharacterDetails:
	
	var identity# : Character.CharacterIdentity
	var alignment# : Character.CharacterAlignment
	
	var health : int
	var ai_health : int
	
	var sounds = {}# : SoundLibrary?
	var animations = {}# : AnimationLibrary?
	var model_attachments = []# : Character.ModelAttachment
	
	var materials = {}# Dictionary of ModelMaterial?
	var rig_class : String
	var rig : CharacterRigLoadDetails
	
	var movement_logics = {}# : Dictionary of MovementLogics
	var jump_logics = {}
	var action_logics = {}
	var attribute_logics = {}
	var interaction_logics = {}
	
	var weapons = {}# Dictionary of Character.Weapon
	
	var collision : ColLoadDetails
	
	var icon_details : TextureLoadDetails
	
	func gen():# -> Character:
		# create a new character
		var character = ResourceManager.load_scene("Character/Character").instantiate()
		
		gen_to(character)
		
		return character
	
	func gen_array(list):
		var new_list = []
		for element in list:
			new_list.append(element.gen())
		return new_list
	
	func gen_dict(dict):
		var new_dict = {}
		for element in dict.keys():
			new_dict[element] = dict[element].gen()
		return new_dict
	
	func gen_to(character : Character):
		#character emits pre gen signal?
		character.movement_logics = gen_dict(movement_logics)
		character.jump_logics = gen_dict(jump_logics)
		character.action_logics = gen_dict(action_logics)
		character.attribute_logics = gen_dict(attribute_logics)
		character.interaction_logics = gen_dict(interaction_logics)
		
		character.weapons = gen_dict(weapons)
		character.sounds = sounds
		character.animations = animations
		
		character.max_hit_points = health
		character.ai_hit_points = ai_health
		
		character.nav_agent = character.get_node("Agent")
		character.modulate_anim = character.get_node("Modulation")
		character.audio = character.get_node("AudioPlayer")
		character.tail = character.get_node("Tail")
		character.tailcast = character.get_node("TailCast")
		
		if icon_details:character.icon = icon_details.gen()
		if rig:
			var rig_gen = rig.gen()
			character.add_child(rig_gen)
			character.set_mesh(rig_gen)
			character.rig_class = rig_class
		
		if collision:
			var col_gen = collision.gen()
			character.collision = col_gen
			character.add_child(col_gen)
			character.tailcast.shape = col_gen.shape
			
			var p_col_gen = collision.gen_expanded()
			character.get_node("Pushaway").add_child(p_col_gen)

class CharacterLoadDetails extends CharacterDetails:
	var path : LoadDir
	var file : String
	
	enum {
		SELF,
		DICT,
		CLASS_DICT,
		ARRAY,
		STRING,
		INTEGER,
		FLOAT,
		BOOL,
		VECTOR2,
		VECTOR3,
		LOGIC,
		ANIM,
		SOUNDS,
		SOUND,
		MATTE,
		TEXTURE,
		NORMAL_TEXTURE,
		COMMAND,
		RIG,
		BOX_COL,
		CAPSULE_COL,
		PATH,
	}
	var var_ids = {
		"d" : DICT,
		"cd" : CLASS_DICT,
		"a" : ARRAY,
		"s" : STRING,
		"i" : INTEGER,
		"f" : FLOAT,
		"b" : BOOL,
		"v2" : VECTOR2,
		"v3" : VECTOR3,
		"logic" : LOGIC,
		"anim" : ANIM,
		"c" : COMMAND,
		"rig" : RIG,
		"box_col" : BOX_COL,
		"capsule_col" : CAPSULE_COL,
		"matte" : MATTE,
		"path" : PATH,
		"sound" : SOUND,
		"sounds" : SOUNDS,
		"tex" : TEXTURE,
	}
	func id(split):
		if split == null:
			return SELF
		return var_ids[split[0]]
	
	
	func _init(_path : LoadDir, _file : String):
		path = _path
		file = _file
	
	
	func load_details():
		update(file)
	 
	
	func update(c_name):
		
		var file_access = FileAccess.open(path.get_dir() + c_name + ".ttgc", FileAccess.READ)
		
		var obj_stack = []
		var data_stack = []
		while !file_access.eof_reached():
			var line = file_access.get_line()
			if line.begins_with("#") or line == "":
				continue
			
			var trimmed = line.strip_edges()
			var split = trimmed.split(" ")
			var indent = line.count("\t")
			
			while len(obj_stack) > 0 and indent < len(obj_stack):
				# pop last item of stack and apply it
				set_var_on_object(
					data_stack.pop_back(), 
					obj_stack.pop_back(),
					null if data_stack.is_empty() else data_stack.back(),
					self if obj_stack.is_empty() else obj_stack.back()
									)
			
			#debug print("\n", line)
			
			if var_ids[split[0]] == COMMAND:
				#debug printt("apply this command", split)
				apply_command(split)
			else:
				#if is_nester_object(split):
					if split[-1] == ">":
						var parent = self if obj_stack.is_empty() else obj_stack.back()
						var nester = parent.get(split[1])
						obj_stack.append(nester)
					else:
						var has_name = true if data_stack.is_empty() else id(data_stack.back()) not in [ARRAY, CLASS_DICT]
						var data_starts_at = 2 if has_name else 1
						obj_stack.append(get_value(split, data_starts_at))
					#debug print("this is a nester object, indent avaliable")
					data_stack.append(split)
				#else:
				#	var parent = obj_stack.back() if len(obj_stack) > 0 else self
				#	set_var_on_object(split, null, null if data_stack.is_empty() else data_stack.back(), parent)
		
		file_access.close()
		
		#debug print("\nobject stack ", obj_stack)
		while !obj_stack.is_empty():
			#debug print("final deindentation")
			set_var_on_object(
				data_stack.pop_back(), 
				obj_stack.pop_back(),
				null if data_stack.is_empty() else data_stack.back(),
				self if obj_stack.is_empty() else obj_stack.back()
								)
		
		#breakpoint
	
	
	func get_value(split, data_starts_at):
		match id(split):
			STRING:
				return str(" ".join(split.slice(data_starts_at)))
			INTEGER:
				return int(split[data_starts_at])
			FLOAT:
				return float(split[data_starts_at])
			BOOL:
				return str(split[data_starts_at]).to_lower() == "true"
			RIG:
				return CharacterRigLoadDetails.new(split[data_starts_at])
			VECTOR2:
				return Vector2(
					float(split[0 + data_starts_at]),
					float(split[1 + data_starts_at])
					)
			VECTOR3:
				return Vector3(
					float(split[0 + data_starts_at]), 
					float(split[1 + data_starts_at]), 
					float(split[2 + data_starts_at])
					)
			DICT:
				return {}
			CLASS_DICT:
				return {}
			ARRAY:
				return []
			LOGIC:
				return TTGCLogicLoadDetails.new(split.slice(data_starts_at))#script_name, logic_name)
			ANIM:
				return TTGCAnimationLoadDetails.new(split.slice(data_starts_at))
			BOX_COL:
				return BoxColLoadDetails.new()
			CAPSULE_COL:
				return CapsuleColLoadDetails.new()
			MATTE:
				return TTGCMaterialLoadDetails.new(split.slice(data_starts_at))
			SOUNDS:
				return TTGCSoundsLoadDetails.new(split.slice(data_starts_at))
			SOUND:
				return TTGCSoundLoadDetails.new(split[data_starts_at])
			TEXTURE:
				return TTGCTextureLoadDetails.new(split.slice(data_starts_at))
			PATH:
				return translate_path(split.slice(data_starts_at))
			_:
				assert(false, "object " + str(split) + " is invalid")
		
		return null
	
	var path_translated = {
		"b" : LoadDir,
		"m" : ModFolderLoadDir,
		"s" : CharactersSoundFolderLoadDir,
		"a" : CharactersAnimsFolderLoadDir,
	}
	
	
	func translate_path(data):
		var path = path_translated[data[0]].new()
		return path
	
	
	func set_var_on_object(split, obj, parent_line, parent):
		if id(split) in [ARRAY, CLASS_DICT, DICT]:
			update_list(split, obj, parent)
			return
		
		var parent_type = id(parent_line)
		var has_name = parent_type not in [ARRAY, CLASS_DICT]
		var data_starts_at = 2 if has_name else 1
		var value = get_value(split, data_starts_at)
		
		if value != null:
			if parent_type == ARRAY:
				parent.append(value)
			else:
				print(split)
				parent[split[1]] = value
			return
		
		match parent_type:
			ARRAY:
				parent.append(obj)
			CLASS_DICT:
				parent[obj.name] = obj
			_:
				parent[split[1]] = obj
	
	
	func update_list(data, elements, obj):
		var current = obj.get(data[1])
		
		if len(data) < 3 or data[2] == "=":
			current.assign(elements)
			return
		
		var operation = data[2]
		
		match operation:
			">":
				return # changes have already been made
			"-":
				#debug print("erase elements ", elements, " from list ", current)
				erase_elements_from_list(elements, current)
			"+":
				#debug print("add elements ", elements, " to list ", current)
				add_elements_to_list(elements, current)
	
	
	func erase_elements_from_list(elements, list):
		if list is Dictionary:
			for element_name in elements.keys():
				list.erase(element_name)
		elif list is Array:
			for element_name in elements:
				list.erase(element_name)
	
	
	func add_elements_to_list(elements, list):
		if list is Dictionary:
			for element_name in elements.keys():
				list[element_name] = elements[element_name]
		elif list is Array:
			for element in elements:
				list.append(element)
	
	
	func apply_command(split):
		match split[1]:
			"copy":
				update(split[2])

class TTGCAnimationLoadDetails extends AnimationLoadDetails:
	func _init(data):
		print("create anim with ", data)
		name = data[0]
		file = data[0]
		path = CharactersAnimsFolderLoadDir.new()

class TTGCMaterialLoadDetails extends MaterialLoadDetails:
	func _init(data):
		match data[0]:
			"preset":
				preset_color = data[1]
			"basic":
				color = data[1]

class TTGCSoundLoadDetails extends SoundLoadDetails:
	func _init(_file):
		file = _file
		path = CharactersSoundFolderLoadDir.new()

class TTGCSoundsLoadDetails:
	var sounds = []
	var name : String
	
	func _init(data):
		name = data[0]
		
		for sound in data.slice(1):
			sounds.append(TTGCSoundLoadDetails.new(sound))
	
	func gen():
		return sounds

class TTGCTextureLoadDetails extends TextureLoadDetails:
	func _init(data):
		pass

class TTGCLogicLoadDetails extends LogicLoadDetails:
	func _init(data):
		var sc_name = data[0]
		var logic_name = null
		var has_custom_name = len(data) > 1
		if has_custom_name:
			logic_name = data[1]
		
		super(sc_name, logic_name)

class LogicLoadDetails:
	var name : String
	var script_name : String
	
	func _init(_script_name, _name = null):
		script_name = _script_name
		if _name != null:
			name = _name
		else:
			name = script_name
	
	func gen():
		pass

class AnimationLoadDetails:
	var speed : float = 1.0
	var key_frames : Dictionary = {}
	var path : LoadDir
	var file : String
	var name : String
	
	func gen():
		pass

class CharFolderCharacterLoadDetails extends CharacterLoadDetails:
	func _init(character_name):
		path = CharFolderLoadDir.new()
		file = character_name


#endregion
#region GLTFs

class GltfLoadDetails:
	var dir : LoadDir
	var file : String
	
	func _init(_dir : LoadDir, _file : String):
		dir = _dir
		file = _file
	
	func get_path():
		return dir.get_dir() + file + ".glb"
	
	func gen():
		var gltf = GLTFDocument.new()
		var gltf_state = GLTFState.new()
		var path = get_path()
		var snd_file = FileAccess.open(path, FileAccess.READ)
		var fileBytes = PackedByteArray()
		fileBytes = snd_file.get_buffer(snd_file.get_length())
		
		gltf.append_from_buffer(fileBytes, "base_path?", gltf_state)
		var node = gltf.generate_scene(gltf_state)
		
		return node

class LevelGltfLoadDetails extends GltfLoadDetails:
	func _init(_level, _section):
		dir = SectionFolderLoadDir.new(_level, _section)
		file = _section

class CharacterRigLoadDetails extends GltfLoadDetails:
	func _init(rig_name : String):
		dir = CharactersRigFolderLoadDir.new()
		file = rig_name
	
	func gen():
		var rig = super()
		rig.name = "Mesh"
		return rig

#endregion
#region TTGLs

class TtglLoadDetails:
	var dir : SectionFolderLoadDir
	var path : String
	
	func _init(_level, _section):
		dir = SectionFolderLoadDir.new(_level, _section)
	
	func get_path():
		return dir.get_dir() + dir.section + ".ttgl"
	
	func gen():
		var file = FileAccess.get_file_as_string(get_path())
		return file.split("\n")

#endregion
#region RES:// loads
func load_file(path, extension):
	return load("res://" + path + "." + extension)

func load_scene(path):
	return load_file(path, "tscn")

func create_scene(path, position, parent):
	var scene = load_scene(path).instantiate()
	scene.position = position
	parent.add_child(scene)
	return scene

func load_script(path):
	return load_file(path, "gd")

func load_tres(path):
	return load_file(path, "tres")

#endregion
#region JSONs

func load_level_json(level):
	var path = LevelFolderLoadDir.new(level).get_dir() + level + ".json"
	var string = FileAccess.get_file_as_string(path)
	var json = JSON.parse_string(string)
	return json

#endregion
#region COLLISION

class ColLoadDetails:
	var offset
	var push_margin = 0.1
	
	func gen():
		var col = CollisionShape3D.new()
		col.name = "Collision"
		col.position = offset
		return col
	
	func gen_expanded():
		var col = CollisionShape3D.new()
		col.name = "PushawayCollision"
		col.position = offset
		return col

class BoxColLoadDetails extends ColLoadDetails:
	var size : Vector3
	
	func gen():
		var col = super()
		var shape = BoxShape3D.new()
		shape.size = size
		col.shape = shape
		return col
	
	func gen_expanded():
		var col = super()
		var shape = BoxShape3D.new()
		shape.size = size + push_margin
		col.shape = shape
		return col

class CapsuleColLoadDetails extends ColLoadDetails:
	var radius : float
	var height : float
	
	func gen():
		var col = super()
		var shape = CapsuleShape3D.new()
		shape.height = height
		shape.radius = radius
		col.shape = shape
		return col
	
	func gen_expanded():
		var col = super()
		var shape = CapsuleShape3D.new()
		shape.height = height + (push_margin * 2)
		shape.radius = radius + push_margin
		col.shape = shape
		return col

#endregion

var material_data = {
	# basic colors
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
	
	# metallic
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

# idk what this is
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
