extends Node3D

var online:bool = true
var defaults = {}

func logic_name():
	
	var script_path = get_script().get_path()
	var script_ext = script_path.get_extension()
	var logic = script_path.get_file().trim_suffix(script_ext).trim_suffix(".")
	
	return logic

@onready var audio_player = get_parent().get_parent().get_node("AudioPlayer")
@onready var anim:AnimationPlayer = get_node("../../Mesh/AnimationPlayer")
@onready var C = get_parent().get_parent()
@onready var mesh = get_node("../../Mesh")
@onready var nav_agent:NavigationAgent3D = get_node("../../Agent")
@onready var var_scale = C.var_scale
@onready var base_state = C.get_base_movement_state()

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


