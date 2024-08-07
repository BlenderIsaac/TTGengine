extends Camera3D

@onready var cam = self
var cam_speed = 1
var mouseDelta = Vector2()
var mouse_sensitivity = 10.0
var controlling = false


func _input(event):
	if event is InputEventMouseMotion:
		mouseDelta = event.relative
	
	if event is InputEventMouseButton:
		if event.button_index == 4:
			cam_speed += .03
		if event.button_index == 5:
			cam_speed -= .03
		
		cam_speed = clamp(cam_speed, .03, 3)


func _process(delta):
	
	child_tick(delta)
	
	if Input.is_action_pressed("ui_up"):
		cam.translate_object_local(Vector3(0, 0, -cam_speed))
	if Input.is_action_pressed("ui_down"):
		cam.translate_object_local(Vector3(0, 0, cam_speed))
	if Input.is_action_pressed("ui_left"):
		cam.translate_object_local(Vector3(-cam_speed, 0, 0))
	if Input.is_action_pressed("ui_right"):
		cam.translate_object_local(Vector3(cam_speed, 0, 0))
	if Input.is_action_pressed("q"):
		cam.translate_object_local(Vector3(0, -cam_speed, 0))
	if Input.is_action_pressed("e"):
		cam.translate_object_local(Vector3(0, cam_speed, 0))
	
	if Input.is_action_just_pressed("right_click"):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		controlling = true
	if Input.is_action_just_pressed("unlock"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		controlling = false
	
	if controlling == true:
		cam.rotation.x -= deg_to_rad(mouseDelta.y * mouse_sensitivity * delta)
		cam.rotation.x = deg_to_rad(clamp(rad_to_deg(cam.rotation.x), -90, 90))
		cam.rotation.y -= deg_to_rad(mouseDelta.x * mouse_sensitivity * delta)
	
	mouseDelta = Vector2()



func child_tick(_delta):
	pass


func deg2radvec3(vec3):
	return Vector3(deg_to_rad(vec3.x), deg_to_rad(vec3.y), deg_to_rad(vec3.z))


