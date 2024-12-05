extends CPUParticles3D

var current_mod = ""
var sounds = {
	"BuildFinish" : {
		"cSoundsPath" : ["MK-PICKUP.WAV"]
	}
}



func _ready():
	var audio_player = f.make("res://Scripts/AudioPlayer.tscn", position, self)
	audio_player.add_library(sounds, current_mod)#(["MK-PICKUP.WAV"], "BuildFinish", "Basic Characters")
	audio_player.play("BuildFinish")


func _on_timer_timeout():
	queue_free()
