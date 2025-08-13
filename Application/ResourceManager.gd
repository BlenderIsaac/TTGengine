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
	var character : String
	
	func _init(_character):
		character = _character
	
	func get_dir():
		return super() + "chars/" + character + "/"

class CharactersSoundLoadDir extends CharactersFolderLoadDir:
	func get_dir():
		return super() + "sounds/"

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
	
	var sounds# : SoundLibrary?
	var animations# : AnimationLibrary?
	
	var model_attachments# : Character.ModelAttachment
	
	var materials# Array of ModelMaterial?
	
	var movement_logics# : Array of MovementLogics
	var jump_logics
	var attack_logics
	var special_logics
	var attribute_logics
	var interaction_logics
	
	var weapons# Array of Character.Weapon
	
	var icon_details : TextureLoadDetails
	
	func gen():# -> Character:
		pass

class LoadedCharacterDetails extends CharacterDetails:
	var path : LoadDir
	var file : String
	
	func _init(_path : LoadDir, _file : String):
		path = _path
		file = _file

class LoadedCharFolderCharacterDetails extends LoadedCharacterDetails:
	func _init(character_name):
		path = CharFolderLoadDir.new(character_name)
		file = character_name + ".json"

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
