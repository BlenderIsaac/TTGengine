extends "res://Scripts/TriggerAnim.gd"

@export var panel_size = 1.0
var paths = ["SWLEVER.WAV"]

var active = true
var panel_reset_time = 1.0
var reseting = false

var audio
var activate_anim : AnimationPlayer
var reset_anim : AnimationPlayer

var toggled = false

func extends_ready():
	add_to_group("Panel")
	
	activate_anim = get_anim(props.ACTIVATE)
	activate_anim.play(props.ACTIVATE)
	activate_anim.seek(0.0, true)
	activate_anim.stop()
	
	reset_anim = get_anim(props.RESET)
	
	audio = l.generate("res://Scripts/AudioPlayer.tscn")
	add_child(audio)
	
	audio.add_sound(paths, "PullLever", "Ahsoka Show") # TODO: Change once added to a mod


func is_triggering():
	
	if !activate_anim.is_playing() and !reset_anim.is_playing():
		
		# if we have been pulled
		if active == false:
			
			if not reseting:
				reset_anim.play(props.RESET)
				reseting = true
				
				toggled = !toggled
			else:
				reseting = false
				active = true
	
	
	return toggled


func activate():
	get_anim(props.ACTIVATE).play(props.ACTIVATE)
	active = true


