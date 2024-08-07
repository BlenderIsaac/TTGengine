
#########################################
## Curve Obj Importer                   #
## Copyright (C) 2023 B1er0l14m         #
#########################################

class_name CurveObjImport


static func import_curve(path):
	var file = FileAccess.open(path, FileAccess.READ)
	
	var parent_node = Node3D.new()
	
	var current_curve = null
	
	while !file.eof_reached():
		var line = file.get_line()
		
		if line.begins_with("mtllib"):
			var new_name = line.trim_prefix("mtllib ").trim_suffix(".mtl")
			
			parent_node.name = new_name
		elif line.begins_with("o"):
			current_curve = Path3D.new()
			parent_node.add_child(current_curve)
			
			current_curve.name = line.trim_prefix("o ")
			current_curve.curve = Curve3D.new()
			
		elif line.begins_with("v"):
			if current_curve:
				
				var vector_array = line.trim_prefix("v ").split(" ")
				
				var vector = Vector3(float(vector_array[0]), float(vector_array[1]), float(vector_array[2]))
				
				current_curve.curve.add_point(vector)
	
	file.close()
	
	return parent_node


