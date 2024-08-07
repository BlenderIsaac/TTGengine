extends Control


func _process(delta):
	
	if !WHEEL.is_pressed():
		point.position = Vector2()

@onready var WHEEL = $HBoxContainer/VBoxContainer/BottomLeft/Sprite2D/Wheel
@onready var point = $HBoxContainer/VBoxContainer/BottomLeft/Sprite2D/Point
func _input(event):
	
	if(event is InputEventScreenTouch or event is InputEventScreenDrag) and WHEEL.is_pressed():
		var center = WHEEL.global_position
		var diff = (event.position - center)
		if diff.length() < WHEEL.shape.radius:
		
			point.position = diff.normalized()*min(diff.length(), WHEEL.shape.radius*.8)
			#print(angle)
			#var orig_angle = ship.rotation - (PI/2.0)
			#ship.rotation_dir += sign(angle - orig_angle)
