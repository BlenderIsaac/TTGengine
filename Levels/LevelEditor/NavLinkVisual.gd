extends Node3D

@onready var FROM = $FROM
@onready var TO = $TO
@onready var LINE = $LINE
@onready var GROUPS = $FROM/GROUPS

var finished = false

var bidirectional = false
var groups = []

func _ready():
	update_line()

func _process(_delta):
	
	if finished == false:
		
		var pos = get_object_under_mouse()
		if pos:update_TO(pos.position)
		
		if Input.is_action_just_pressed("Click"):
			get_parent().get_parent().current_nav_link = null
			
			#var update_pos = (TO.global_position+FROM.global_position)/2
			
			#position = update_pos
			
			get_parent().get_parent().links.append(
				{
					"POS" : position,
					"FROM" : FROM.position,
					"TO" : TO.position,
					"GROUPS" : groups,
					"BIDI" : bidirectional,
				}
			)
			
			finished = true
		
		if Input.is_action_just_pressed("esc"):
			get_parent().get_parent().current_nav_link = null
			queue_free()

var height = 0.1

func update(pos, from, to, new_groups, bidi):
	global_position = pos
	FROM.position = from
	TO.position = to
	groups = new_groups
	bidirectional = bidi
	
	finished = true
	
	update_visuals()
	update_line()

func update_TO(to):
	TO.global_position = to+Vector3(0, height, 0)
	
	update_line()

func update_visuals():
	
	if !bidirectional:TO.hide()
	else:TO.show()
	
	var fancy_text = ""
	
	for group in groups:
		fancy_text += group+"\n"
	
	GROUPS.text = fancy_text

func update_line():
	LINE.position = FROM.position
	
	if TO.position.distance_to(FROM.position) > .01:
		LINE.show()
		LINE.look_at(TO.global_position, Vector3.UP)
	else:
		LINE.hide()
	
	LINE.scale.z = -FROM.position.distance_to(TO.position)*2.5

func get_object_under_mouse():
	var cam = get_viewport().get_camera_3d()
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_from = cam.project_ray_origin(mouse_pos)
	var ray_to = ray_from + cam.project_ray_normal(mouse_pos) * 1000
	var space_state = get_world_3d().direct_space_state
	var selection = space_state.intersect_ray(PhysicsRayQueryParameters3D.create(ray_from, ray_to))
	return selection
