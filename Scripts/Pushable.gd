extends CharacterBody3D

var box_push_path = ""#"leveldata/RescueTheWitch/LaserRoom/BoxPath.obj"
var box_push_path_config = {}

var mesh_path = ""#"leveldata/RescueTheWitch/LaserRoom/Box.obj"
var col_path = ""#"leveldata/RescueTheWitch/LaserRoom/BoxCol.obj"

var mod = ""#"Ahsoka Show"

var mesh_config = {}
var col_config = {}

var gravity = 9.8
var box_weight = 1.0

func _ready():
	
	add_to_group("Pushable")
	
	var level = Levels.current_level
	
	var full_box_push_path = SETTINGS.mod_path+"/"+mod+"/levels/"+box_push_path
	var box_push_col = level.generate_col(full_box_push_path, box_push_path_config)
	
	var box_push_static = StaticBody3D.new()
	box_push_static.add_child(box_push_col)
	
	box_push_static.set_collision_layer_value(1, false)
	box_push_static.set_collision_mask_value(1, false)
	
	box_push_static.set_collision_layer_value(12, true)
	box_push_static.set_collision_mask_value(12, true)
	
	get_parent().call_deferred("add_child", box_push_static)
	
	
	var full_mesh_path = SETTINGS.mod_path+"/"+mod+"/levels/"+mesh_path
	var full_col_path = SETTINGS.mod_path+"/"+mod+"/levels/"+col_path
	
	var mesh = level.generate_mesh(full_mesh_path, mesh_config)
	var col = level.generate_convex_col(full_col_path, col_config)
	
	add_child(mesh)
	add_child(col)


func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	move_and_slide()
	
	velocity.x = lerp(velocity.x, 0.0, delta*60*0.1)
	velocity.z = lerp(velocity.z, 0.0, delta*60*0.1)
