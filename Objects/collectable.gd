extends Area3D

@export var model_path = "Models/Minikit"
@export var model_ext = "glb"

@export var material_dict = {
	"Minikit_001" : {
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
}
@export var material_array = []

@export_enum("Minikit", "RedBrick") var type = "Minikit"

var mesh : Node3D

# Called when the node enters the scene tree for the first time.
func _ready():
	var path = ResourceManager.ResLoadDir.new()
	var load_details = ResourceManager.ModelLoadDetails.new()
	load_details.dir = path
	load_details.ext = model_ext
	load_details.file = model_path
	load_details.material_dict = get_material_dict()
	load_details.material_array = get_material_array()
	var model = load_details.gen()
	add_child(model)
	mesh = model

var rotate_speed = 1.0

# Called evey frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	mesh.rotation.y = fmod(mesh.rotation.y + (rotate_speed * delta), PI*2)

func get_material_dict():
	pass

func get_material_array():
	pass

func _on_body_entered(body):
	if body is Character:
		if not body.dead:
			body.emit_signal("pickup_collided", self)
	#if body.is_in_group("Character"):
		#if !body.dead and body.player and !body.AI:
			###Levels.i_am_dead(self)
			#
			#var _proj_pos = Vector2()
			#var cam : Camera3D = get_tree().get_first_node_in_group("GAMECAM")
			#
			#_proj_pos = cam.unproject_position(global_position)
			#
			###Interface.collectable_found(proj_pos, type)
			#queue_free()
