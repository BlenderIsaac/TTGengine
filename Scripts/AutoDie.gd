extends Node

@export var time_left = 3.0

func _process(delta):
	time_left -= delta
	
	if time_left < 0:
		queue_free()
