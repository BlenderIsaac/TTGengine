extends Node

var gltf = null
var props
var attr

var base_anim_plyr = null
var anim_nodes = {}

var untrigger_wait = 1.0
var delay = 0.0
var playing = false

var current_animation

var anim_time = 0.0

var anim_data = {
	"Default" : "",
	"Trigger" : "",
	"UnTrigger" : "",
}

var incremental = false
var increment_pause = 0.1
var increment = 0.0

var one_shot = false
var triggered = false
var toggle = false

var lbl = null
func _ready():
	lbl = Label3D.new()
	add_child(lbl)
	lbl.position.y += 3
	
	anim_data.Default = props.DEFAULT
	anim_data.Trigger = props.START
	anim_data.UnTrigger = props.END
	untrigger_wait = float(props.TIME)
	one_shot = bool(int(props.ONE_SHOT))
	toggle = bool(int(props.TOGGLE))
	incremental = bool(int(props.get("INCREMENTAL", false)))
	
	base_anim_plyr = gltf.get_node("AnimationPlayer")
	
	anim_play("Default")
	extends_ready()

# extends functions
func extends_ready():pass
func is_triggering():return false


func _process(_delta):
	
	if anim_time > 0:
		anim_time -= _delta
	else:
		playing = false
	
	var triggering = is_triggering()
	lbl.text = str(triggering)
	
	if !incremental:
		if triggering:
			#print("yo")
			delay = untrigger_wait
			if current_animation == "Default":
				anim_play("Trigger")
		else:
			if !one_shot:
				if !playing:
					if current_animation == "Trigger":
						
						if delay <= 0:
							anim_play("UnTrigger")
							
							
							
						else:
							delay -= _delta
	else:
		if triggering:
			increment = clamp(increment+_delta, 0.0, 1.0)
			anim_seek("Trigger", increment)
			
			if increment == 1.0:delay = untrigger_wait
		else:
			var untrigger = true
			if (increment >= 1.0 and one_shot):
				untrigger = false
			
			if delay > 0.0:
				delay -= _delta
				untrigger = false
			
			if untrigger:
				increment = clamp(increment-_delta, 0.0, 1.0)
				anim_seek("UnTrigger", increment)
	
	triggered = !playing and (triggering or (!triggering and delay > 0))
	
	if current_animation == "UnTrigger" and not playing:
		anim_play("Default")


func anim_play(anim_type): # Default, Trigger or UnTrigger
	
	var anim_name = anim_data[anim_type]
	current_animation = anim_type
	
	if anim_type == "Default":
		playing = false
		if is_null(anim_data[anim_type]):
			var anim = get_anim(anim_data["Trigger"])
			anim.play(anim_data["Trigger"])
			anim.seek(0.0, true)
			anim.stop()
			anim_time = 0.0
		else:
			var anim = get_anim(anim_name)
			anim.play(anim_name)
			anim_time = anim.current_animation_length
	elif anim_type == "UnTrigger":
		
		if is_null(anim_data[anim_type]):
			var anim = get_anim(anim_data["Trigger"])
			anim.play_backwards(anim_data["Trigger"])
			anim_time = anim.current_animation_length
		else:
			var anim = get_anim(anim_name)
			anim.play(anim_name)
			anim_time = anim.current_animation_length
		
		playing = true
	else:
		playing = true
		
		var anim = get_anim(anim_name)
		anim.play(anim_name)
		anim_time = anim.current_animation_length


func anim_seek(anim_type, perc):
	
	var anim_name = anim_data[anim_type]
	current_animation = anim_type
	
	if anim_type == "UnTrigger":
		
		if is_null(anim_data[anim_type]):
			var anim = get_anim(anim_data["Trigger"])
			anim.play_backwards(anim_data["Trigger"])
			anim_time = anim.current_animation_length
			anim.seek(perc*anim_time, true)
			
		else:
			var anim = get_anim(anim_name)
			anim.play(anim_name)
			anim_time = anim.current_animation_length
			anim.seek(perc*anim_time, true)
			
		
		playing = true
	else:
		playing = true
		
		var anim = get_anim(anim_name)
		anim.play(anim_name)
		anim_time = anim.current_animation_length
		anim.seek(perc*anim_time, true)


func is_null(x):
	return x == "" or x == null or x == "None"

# Button1
func get_anim(anim_name):
	if anim_nodes.has(anim_name):
		return anim_nodes[anim_name]
	else:
		var grab_anim = gltf.get_node_or_null("ANIM"+anim_name)
		if grab_anim:
			anim_nodes[anim_name] = grab_anim
		else:
			var new_anim = base_anim_plyr.duplicate()
			
			new_anim.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_PHYSICS
			
			gltf.add_child.call_deferred(new_anim)
			
			new_anim.name = "ANIM"+anim_name
			
			anim_nodes[anim_name] = new_anim
	
	return get_anim(anim_name)
