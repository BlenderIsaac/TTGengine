extends Node3D

var online : bool = true
var defaults = {}

func logic_name():
	
	var script_path = get_script().get_path()
	var script_ext = script_path.get_extension()
	var logic = script_path.get_file().trim_suffix(script_ext).trim_suffix(".")
	
	return logic

var audio_player
var anim:AnimationPlayer
var C
var mesh
var nav_agent:NavigationAgent3D
var var_scale
var base_state
var tail
var tailcast

func establish_connections(c):
	C = c
	audio_player = C.get_node("AudioPlayer")
	mesh = C.get_node("Mesh")
	anim = mesh.get_node("AnimationPlayer")
	nav_agent = C.get_node("Agent")
	var_scale = C.var_scale
	base_state = C.get_base_movement_state()
	tail = C.get_node("Tail")
	tailcast = C.get_node("TailCast")

#func exclusive_physics(_delta):
#	pass
#func inclusive_physics(_delta):
#	pass
#func exclusive_process(_delta):
#	pass
#func inclusive_process(_delta):
#	pass
#func reset():
#	pass
#func switched():
#	pass
#func dropped_inout():
#	pass
#func die():
#	pass
#func revive():
#	pass
