extends Node
class_name Logic

var script_name : String
var logic_name : String

var C : Character

var audio : AudioPlayer :
	get(): return C.audio
var anim : AnimationPlayer :
	get(): return C.anim
var rig : Node3D :
	get(): return C.rig
var nav_agent : NavigationAgent3D :
	get(): return C.nav_agent
var var_scale : float :
	get(): return C.var_scale
var tail : RayCast3D :
	get(): return C.tail
var tailcast : ShapeCast3D :
	get(): return C.tailcast
var position : Vector3 :
	get(): return C.position
var global_position : Vector3 :
	get(): return C.global_position
var input_vector : Vector2 :
	get(): return C.input_vector

var active = false

func enter():
	active = true

func exit():
	active = false

func consume_damage(_damage):
	return false

func player_input(_button):
	return false

func _physics_process(delta):
	if active:
		exclusive_physics(delta)

func exclusive_physics(delta):
	pass
