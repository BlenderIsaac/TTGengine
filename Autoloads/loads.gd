extends Node

var loads = {}


func get_load(path):
	if not loads.has(path):
		loads[path] = load(path)
	
	return loads[path]

func generate(path):
	return get_load(path).instantiate()

var exceptions = ["vec3", "array"]
func get_var_from_str(value):
	
	if typeof(value[1]) == typeof(""):
		match value[0]:
			"int":
				return value[1].to_int()
			"str":
				return value[1]
			"dict":
				return value[1]
			"float":
				return float(value[1])
			"bool":
				return get_bool_from_string(value[1])
			"color_hex":
				return Color(value[1])
			_:
				if !exceptions.has(value[0]):
					print(value[0] + " doesn't exist")
				return str_to_var(value[1])
	
	return value[1]


func get_bool_from_string(b):
	if ["true", "t", "yes"].has(b.to_lower()):
		return true
	return false


func snapped_vec2(vec2, value):
	return Vector2(snapped(vec2.x, value), snapped(vec2.y, value))
