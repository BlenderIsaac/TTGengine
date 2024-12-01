extends MeshInstance3D


var max_dist = 0.8
var active = true

var destroyed = false

var body = null
var collision = null

var props
var attr
var gltf

func _ready():
	
	var idx = 0
	for matte in props.MATERIALS:
		
		set_surface_override_material(idx, matte)
		
		idx += 1
	
	set_meta("obj_changes", ["destroyed"])
	add_to_group("OBJCHANGE")
	add_to_group("SaberWall")
	
	body = StaticBody3D.new()
	add_child(body)
	collision = CollisionShape3D.new()
	body.add_child(collision)
	var box_shape = BoxShape3D.new()
	box_shape.size = get_aabb().size
	collision.position = get_aabb().position+get_aabb().size/2
	
	collision.shape = box_shape
	
	if destroyed:
		destroy()


func destroy():
	hide()
	collision.set_deferred("disabled", true)
	#$Guide.hide()
	active = false
	destroyed = true
	
	remove_from_group("SaberWall")

