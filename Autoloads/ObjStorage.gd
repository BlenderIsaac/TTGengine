extends Node


var obj_meshes = {}

func get_obj(path):
	if obj_meshes.has(path):
		return obj_meshes.get(path)
	else:
		if !SETTINGS.mobile:
			var new_obj = ObjParse.load_obj(path)
			
			obj_meshes[path] = new_obj
			
			return new_obj
		else:
			var new_obj = load(path)
			
			return new_obj
