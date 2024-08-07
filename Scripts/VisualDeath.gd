extends Node3D

var wait_time = 4

var timer = null

func setup():
	timer = Timer.new()
	
	timer.connect("timeout", kill)
	timer.wait_time = wait_time+randf_range(0, 1)
	
	timer.autostart = true
	
	add_child(timer)

func _process(_delta):
	
	if timer:
		var progress = timer.time_left
		
		if progress < wait_time*.30:
			$Mesh.transparency = sin(timer.time_left*20)

func kill():
	queue_free()
