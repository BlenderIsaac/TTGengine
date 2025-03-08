extends "res://Scripts/TriggerAnim.gd"

var dead = false

var aim_pos = Vector3()

var forcing = false

var force_size = 1.0
var nogo = null

func extends_ready():
	if "NOGO" in props:
		if props.NOGO != "":
			nogo = gltf.get_node(props.NOGO).get_meta("ColBody")
	
	force_size = float(props.get("FORCE_SIZE", 1.0))
	add_to_group("ForceObject")


func _process(delta):
	super._process(delta)
	forcing = false


func is_triggering():
	return forcing
