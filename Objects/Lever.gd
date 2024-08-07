extends "res://Scripts/TriggerAnim.gd"

@export var lever_size = 1.0
var paths = ["SWLEVER.WAV"]

var active = true
var lever_reset_time = 1.0
var reseting = false

var audio
var pull_anim : AnimationPlayer
var reset_anim : AnimationPlayer

var toggled = false

func extends_ready():
	add_to_group("Lever")
	
	pull_anim = get_anim(props.PULL_ANIM)
	pull_anim.play(props.PULL_ANIM)
	pull_anim.seek(0.0, true)
	pull_anim.stop()
	
	reset_anim = get_anim(props.RESET_ANIM)
	
	audio = l.generate("res://Scripts/AudioPlayer.tscn")
	add_child(audio)
	
	audio.add_sound(paths, "PullLever", "Ahsoka Show") # TODO: Change once added to a mod


func is_triggering():
	
	if !pull_anim.is_playing() and !reset_anim.is_playing():
		
		# if we have been pulled
		if active == false:
			
			if not reseting:
				reset_anim.play(props.RESET_ANIM)
				reseting = true
				
				toggled = !toggled
			else:
				reseting = false
				active = true
	
	
	return toggled


func pull():
	active = false
	
	get_anim(props.PULL_ANIM).play(props.PULL_ANIM)


