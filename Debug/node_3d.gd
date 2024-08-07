extends Node3D



func _process(_delta):
	
	var look_toward = Basis.looking_at($Bullet.position-$Char.position).get_euler()
	var current_rotation = $Bullet.rotation
	
	var difference = abs(f.angle_to_angle(look_toward.y, current_rotation.y)/PI)
	
	print(difference)
