extends MeshInstance3D

#var box_push_path = {}#""#"leveldata/RescueTheWitch/LaserRoom/BoxPath.obj"
#var box_push_path_config = {}

var props
var attr
var gltf
#var mesh_path = {}
#var col_path = {}

#var mod = ""#"Ahsoka Show"

#var mesh_config = {}
#var col_config = {}

var boxes = []

var being_ns_lifted = false

var gravity = 6*4.1
var box_weight = 1.0

var aim_pos = Vector3(0, 1, 0)


func _ready():
	
	for obj_name in props.BOXES.split(";"):
		
		var push_obj = gltf.get_node(obj_name)
		
		# create push outline
		var box_push_col = generate_col(mesh)
		var box_push_static = StaticBody3D.new()
		box_push_static.add_child(box_push_col)
		
		box_push_static.set_collision_layer_value(1, false)
		box_push_static.set_collision_mask_value(1, false)
		
		box_push_static.set_collision_layer_value(12, true)
		box_push_static.set_collision_mask_value(12, true)
		add_child(box_push_static)
		
		var aabb = push_obj.mesh.get_aabb()
		
		var box_body = CharacterBody3D.new()
		boxes.append(box_body)
		box_body.add_to_group("Pushable")
		box_body.set_meta("weight", box_weight)
		var box_col = CollisionShape3D.new()
		var box_shape = BoxShape3D.new()
		box_shape.size = aabb.size
		box_col.shape = box_shape
		
		box_body.set_collision_layer_value(2, true)
		box_body.set_collision_layer_value(12, true)
		
		box_body.set_collision_mask_value(2, true)
		box_body.set_collision_mask_value(12, true)
		
		add_child(box_body)
		box_body.position = push_obj.position
		
		push_obj.get_parent().remove_child(push_obj)
		box_body.add_child(push_obj)
		push_obj.position = Vector3()
		push_obj.position -= (aabb.size/2)+aabb.position
		box_body.add_child(box_col)
		push_obj.mesh = null
	
	
	mesh = null


func _physics_process(delta):
	for box in boxes:
		if being_ns_lifted == true: # change for when the box is being lifted
			ns_lifted(box, delta)
		else:
			if not box.is_on_floor():
				box.velocity.y -= gravity * delta
			
			#box = CharacterBody3D.new()
			for col_idx in box.get_slide_collision_count():
				var col = box.get_slide_collision(col_idx)
				var collider = col.get_collider()
				if collider.is_in_group("Pushaway"):
					if collider is CharacterBody3D:
						
						if snapped(col.get_angle(), 0.0001) == snapped(PI/2, 0.0001):
							collider.generic_knockback(Vector3(0, 0, -1).rotated(Vector3.UP, col.get_angle()))
						
						elif col.get_angle() == 0:
							if collider.has_method("take_damage"):
								collider.take_damage(10, self)
			
			
			
			box.move_and_slide()
			
			box.velocity.x = lerp(box.velocity.x, 0.0, delta*60*0.1)
			box.velocity.z = lerp(box.velocity.z, 0.0, delta*60*0.1)


func generate_col(a_mesh):
	
	var shape = a_mesh.create_trimesh_shape()
	
	var c = CollisionShape3D.new()
	
	c.shape = shape
	
	return c


# NIGHTSISTER stuff

var lift_release_time = 6.0

var lift_release_delay = 0.0

var lift_height = 1.5

var initial_position = 0.0

func ns_lift():
	being_ns_lifted = true
	lift_release_delay = lift_release_time
	initial_position = position

func ns_lifted(box, delta):
	
	var pos_to = initial_position.y+lift_height
	var up_vely = ((pos_to-position.y)*5)+1
	
	box.velocity.x = lerp(box.velocity.x, 0.0, delta*60*0.05)
	box.velocity.z = lerp(box.velocity.z, 0.0, delta*60*0.05)
	
	box.velocity.y = up_vely
	box.move_and_slide()
	
	if lift_release_delay <= 0:
		being_ns_lifted = false
	
	lift_release_delay -= delta
