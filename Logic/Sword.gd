extends "res://Logic/LOGIC.gd"

# Logic Type: WEAPON
# Contains: Sword Helpers

var weapon_cols = ["LightsaberCollision.tscn"]

var weapon_bone = 19

var is_gltf = false
var gltf_anim = null

var weapon_mesh_path = {}
var weapon_gltf_path = {}
var weapon_materials = {
	"0": {
		"Type": "Preset",
		"Preset": "Dark Bluish Grey"
	},
	"1": {
		"Type": "Preset",
		"Preset": "White"
	},
	"2": {
		"Type": "Basic",
		"Albedo": "00ff00"
	},
}
var our_prefix = "Sword"
var in_lightsaber = []
#var ray_hit_this_frame = []
var SwordExtras

func _ready():
	spawn_objects()

func _process(_delta):
	if C.weapon_prefix == our_prefix:
		#SwordExtras.show()
		pass
	else:
		SwordExtras.hide()

func draw_weapon(overide=false):
	
	if C.weapon_prefix == "" or overide == true:
		C.weapon_prefix = our_prefix
		
		audio_player.play("SaberOn")
		audio_player.start_loop("SaberLoop")
		
		if C.is_on_floor():
			anim.play(our_prefix+"Activate", .3)
		
		if is_gltf:
			gltf_anim.play("Activate")
			gltf_anim.queue("On_loop")

func store_weapon(overide=false):
	
	if C.weapon_prefix == our_prefix or overide == true:
		
		audio_player.end_loop("SaberLoop")
		audio_player.play("SaberOff")
		anim.play(our_prefix+"Deactivate", .3)
		C.weapon_prefix = ""
		
		if is_gltf:
			gltf_anim.play("Deactivate")
			gltf_anim.queue("Off_loop")


func reset():
	SwordExtras.free()
	TestHurt.free()
	for ray in hurt_rays:
		ray.free()
	hurt_rays = []

var weapon_length = 1.7
var rays_num = 4
var hurt_rays = []
func spawn_rays():
	for num in rays_num:
		
		var ray = RayCast3D.new()
		
		ray.enabled = true
		#ray.set_collision_mask_value(1, false)
		ray.set_collision_mask_value(2, true)
		
		add_child(ray)
		hurt_rays.append(ray)


var Hurt_nums = 4
func spawn_inbetween_hurts():
	for num in Hurt_nums:
		
		for weapon_col in weapon_cols:
			var Col = l.get_load(SETTINGS.mod_path+"/"+C.origin_mod+"/characters/collisions/"+weapon_col).instantiate()
			Col.top_level = true
			Col.name = "Col_"+str(weapon_col)+"_"+str(num)
			
			add_child(Col)
			Col.top_level = true

var TestHurt:Area3D = null
func spawn_test_hurt():
	TestHurt = Area3D.new()
	
	TestHurt.set_collision_layer_value(1, false)
	
	TestHurt.set_collision_mask_value(1, false)
	TestHurt.set_collision_mask_value(2, true)
	
	mesh.get_node("Armature/Skeleton3D").add_child(TestHurt)
	
	TestHurt.name = "TestHurt"
	
	for weapon_col in weapon_cols:
		var Col = l.get_load(SETTINGS.mod_path+"/"+C.origin_mod+"/characters/collisions/"+weapon_col).instantiate()
		Col.name = "Col"
		TestHurt.add_child(Col)
	
	TestHurt.connect("body_entered", _on_test_hurt_body_entered)
	TestHurt.connect("body_exited", _on_test_hurt_body_exited)


func spawn_objects():
	
	spawn_test_hurt()
	spawn_rays()
	
	SwordExtras = BoneAttachment3D.new()
	SwordExtras.hide()
	get_node("../../Mesh/Armature/Skeleton3D").add_child(SwordExtras)
	SwordExtras.bone_idx = weapon_bone
	
	if weapon_mesh_path != {}:
		
		var mesh_instance = MeshInstance3D.new()
		SwordExtras.add_child(mesh_instance)
		mesh_instance.material_overlay = MATERIALS.FlashOverlay
		C.meshes_to_modulate.append(mesh_instance)
		
		var mesh_path = f.get_data_path(weapon_mesh_path, C.origin_mod)
		
		var weapon_mesh = o.get_obj(mesh_path)
		
		mesh_instance.mesh = weapon_mesh
		
		for matte in weapon_materials.keys():
			mesh_instance.set_surface_override_material(int(matte), MATERIALS.get_matte(weapon_materials.get(matte), C.origin_mod))
	elif weapon_gltf_path != {}:
		
		var gltf_path = f.get_data_path(weapon_gltf_path, C.origin_mod)
		var gltf = generate_gltf(gltf_path, C.origin_mod)
		
		var all = f.get_all_children(gltf)
		
		for m in all:
			if m is MeshInstance3D:
				
				for matte in weapon_materials.keys():
					m.set_surface_override_material(int(matte), MATERIALS.get_matte(weapon_materials.get(matte), C.origin_mod))
				
				break
		
		SwordExtras.add_child(gltf)
		
		is_gltf = true
		for n in all:
			if n is AnimationPlayer:
				gltf_anim = n
				break
		
		gltf_anim.play("Off_loop")


var prev_trans = Transform3D()
func inclusive_physics(_delta):
	
	
	#Caster.global_position = TestHurt.global_position
	#Caster.target_position = prev_trans.origin
	#Caster.force_shapecast_update()
	
	SwordExtras.hide()
	
	if !C.weapon_prefix == our_prefix:
		if audio_player.has_loop("SaberLoop"):
			store_weapon(true)
	
	var bone_pose = $"../../Mesh/Armature/Skeleton3D".get_bone_global_pose(weapon_bone)
	
	TestHurt.position = bone_pose.origin
	TestHurt.rotation = bone_pose.basis.get_euler()
	
	
	var ray_index = 0
	for ray:RayCast3D in hurt_rays:
		var ray_perc = 0
		if rays_num != 1:
			ray_perc = float(ray_index)/float(rays_num-1)
		
		ray.debug_shape_custom_color = Color.GREEN
		
		var from_pos = TestHurt.global_position + TestHurt.global_transform.basis.y*(weapon_length*ray_perc)
		var to_pos = prev_trans.origin + prev_trans.basis.y*(weapon_length*ray_perc)
		
		ray.global_position = from_pos
		ray.target_position = to_pos-from_pos
		
		ray_index += 1
	
	
	if !C.AI:
		if C.key_just_pressed("Fight"):
			if C.generic_can_draw_weapon():
				draw_weapon()
		
		if C.key_press("Special"):
			if C.is_in_base_movement_state():
				store_weapon()
	
	prev_trans = TestHurt.global_transform

func get_in_rays():
	var ray_hit_this_frame = []
	
	for ray:RayCast3D in hurt_rays:
		
		ray.force_raycast_update()
		if ray.is_colliding():
			
			var body = ray.get_collider()
			if f.is_valid_character(body):
				if not body in ray_hit_this_frame:
					ray_hit_this_frame.append(body)
	
	return ray_hit_this_frame


func get_objs_hit():
	var hitted = in_lightsaber.duplicate()
	
	for hit in get_in_rays():
		if not hit in hitted:
			hitted.append(hit)
	
	return hitted


func generate_gltf(gltf, mod):
	var gltf_document = GLTFDocument.new()
	var gltf_state = GLTFState.new()
	var snd_file = FileAccess.open(gltf, FileAccess.READ)
	var fileBytes = PackedByteArray()
	fileBytes = snd_file.get_buffer(snd_file.get_length())
	
	gltf_document.append_from_buffer(fileBytes, "base_path?", gltf_state)
	var node = gltf_document.generate_scene(gltf_state)
	
	for child in f.get_all_children(node):
		if child is MeshInstance3D:
			MATERIALS.set_char_materials(child.mesh, child, mod)
	
	return node


func WEAPON_AI():
	pass


# Belongs in Sword
func _on_test_hurt_body_entered(body):
	if not in_lightsaber.has(body):in_lightsaber.append(body)
func _on_test_hurt_body_exited(body):
	if in_lightsaber.has(body):in_lightsaber.erase(body)
