extends Node3D


func _process(_delta):
	if Input.is_action_just_pressed("Click") and false:
		var m = SoftBody3D.new()
		print("spawn cloak")
		m.mesh = l.get_load("res://TEMP/testcloak.obj")
		
		m.set_collision_mask_value(2, true)
		add_child(m)
		m.position = position


func _on_timer_2_timeout():
	if visible and false:
		var pos = position + f.RandomVector3(-1.0, 1.0, 0.0, 0.0, -1.0, 1.0)
		f.make("res://Objects/Stud.tscn", pos, self)
