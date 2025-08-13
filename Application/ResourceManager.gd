extends Node
class_name ResourceManagerClass

var loaded_resources : Dictionary = {}
var current_mod : String

#region Base

class ModFolderLoadDetails:
	var mod : String
	
	func get_mod():
		if mod:
			return mod
		
		return ResourceManager.current_mod
	
	func get_path():
		return SettingsManager.mod_path + "/" + get_mod() + "/"

class LevelFolderLoadDetails extends ModFolderLoadDetails:
	var from_shared = false
	
	func _init(_from_shared = false):
		from_shared = _from_shared
	
	func get_path():
		if from_shared:
			return super() + "levels/shared/"
		return super() + "levels/leveldata/"

#endregion
#region Materials

class MaterialLoadDetails:
	var metallic = false

func load_material(details : MaterialLoadDetails):
	pass

#endregion
#region GLTFs

class GltfLoadDetails extends LevelFolderLoadDetails:
	var level : String
	var section : String
	
	func _init(_level, _section, _from_shared = false):
		super(_from_shared)
		level = _level
		section = _section
	
	func get_path():
		return super() + "{0}/{1}/{1}.glb".format([level, section])

func load_gltf(details : GltfLoadDetails):
	var gltf = GLTFDocument.new()
	var gltf_state = GLTFState.new()
	var path = details.get_path()
	var snd_file = FileAccess.open(path, FileAccess.READ)
	var fileBytes = PackedByteArray()
	fileBytes = snd_file.get_buffer(snd_file.get_length())
	
	gltf.append_from_buffer(fileBytes, "base_path?", gltf_state)
	var node = gltf.generate_scene(gltf_state)
	
	return node

#endregion
#region TTGLs

class TtglLoadDetails extends LevelFolderLoadDetails:
	var level : String
	var section : String
	
	func _init(_level, _section, _from_shared = false):
		super(_from_shared)
		level = _level
		section = _section
	
	func get_path():
		return super() + "{0}/{1}/{1}.ttgl".format([level, section])

func load_ttgl(details : TtglLoadDetails):
	var file = FileAccess.get_file_as_string(details.get_path())
	return file.split("\n")

#endregion
#region RES:// loads
func load_file(path, extension):
	return load("res://" + path + "." + extension)

func load_scene(path):
	return load_file(path, "tscn")

func create_scene(path, position, parent):
	var scene = load_scene(path)
	path.position = position
	parent.add_child(path)
	return scene

func load_script(path):
	return load_file(path, "gd")

func load_tres(path):
	return load_file(path, "tres")

#endregion
#region JSONs

func load_level_json(level_name):
	var path = LevelFolderLoadDetails.new().get_path() + "{0}/{0}.json".format([level_name])
	var string = FileAccess.get_file_as_string(path)
	var json = JSON.parse_string(string)
	return json

#endregion
