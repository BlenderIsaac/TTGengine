extends CPUParticles3D

func _ready():
	$AudioPlayer.add_sound(["MK-PICKUP.WAV"], "BuildFinish", "Basic Characters")
	$AudioPlayer.play("BuildFinish")


func _on_timer_timeout():
	queue_free()
