extends Area3D

var mattes = {
	0 : {
		"Type" : "Preset",
		"Preset" : "White",
	},
	1 : {
		"Type" : "Preset",
		"Preset" : "Dark Bluish Grey",
	},
	2 : {
		"Type" : "Preset",
		"Preset" : "Red", # Glowing
	},
	3 : {
		"Type" : "Preset",
		"Preset" : "Light Bluish Grey",
	},
	4 : {
		"Type" : "Preset",
		"Preset" : "Black"
	},
	5 : {
		"Type" : "Preset",
		"Preset" : "Green", # Glowing
	},
}

# Called when the node enters the scene tree for the first time.
func _ready():
	load_materials()

var rotate_speed = 1.0

# Called evey frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$Mesh.rotation.y += rotate_speed*delta
	$Mesh.rotation.y = fmod($Mesh.rotation.y, PI*2)


func load_materials():
	for idx in mattes.keys():
		var matte_data = mattes[idx]
		
		var material = MATERIALS.get_modless_matte(matte_data)
		$Mesh.set_surface_override_material(idx, material)


func _on_body_entered(body):
	if body.is_in_group("Character"):
		if !body.dead and body.player and !body.AI:
			Levels.i_am_dead(self)
			
			var proj_pos = Vector2()
			var cam : Camera3D = get_tree().get_first_node_in_group("GAMECAM")
			
			proj_pos = cam.unproject_position(global_position)
			
			Interface.minikit_found(proj_pos)
			queue_free()



















var h = 0
