extends Node

var loads = {}


func get_load(path):
	if not loads.has(path):
		loads[path] = load(path)
	
	return loads[path]

func generate(path):
	return get_load(path).instantiate()


func snapped_vec2(vec2, value):
	return Vector2(snapped(vec2.x, value), snapped(vec2.y, value))
