extends "res://Logic/LOGIC.gd"

var throw_bone = 13
var thrown_config = {}
var valid_logics = ["Base"]

var time_thrown = .44
var thrown = false

var special_held = false

var last_thrown = null

func inclusive_physics(_delta):
	
	if !C.AI:
		if C.PHYSkey_just_pressed("Special"):
			if special_held == false:
				
				var can_throw = true
				
				# if we have thrown something or that thing we have thrown is valid
				if last_thrown != null or is_instance_valid(last_thrown):
					can_throw = false
				
				if can_throw:
					if C.is_on_floor() and valid_logics.has(C.movement_state):
						# switch the movement states to ours
						C.set_movement_state("ThrowObject")
						anim.play(C.weapon_prefix+"ThrowObject", .3)
						anim.queue("NULL")
						
						thrown = false
				else:
					if last_thrown:
						last_thrown.explode()
						last_thrown = null
				
				special_held = true
		else:
			special_held = false


func exclusive_physics(_delta):
	
	if not C.is_on_floor():
		C.char_vel.y += base_state.air_gravity*_delta*C.var_scale
	else:
		C.char_vel.y = base_state.air_gravity*_delta*C.var_scale
	
	if not anim.current_animation == "NULL":
		var pos = anim.current_animation_position
		
		if pos >= time_thrown and thrown == false:
			thrown = true
			
			# throw detonator
			last_thrown = throw_object()
	else:
		thrown = false
		C.reset_movement_state()
	
	base_state.move_dir_to.x = lerp(base_state.move_dir_to.x, 0.0, .15)
	base_state.move_dir_to.z = lerp(base_state.move_dir_to.z, 0.0, .15)
	
	C.set_velocity(C.char_vel+C.push_vel+C.knock_vel)
	C.move_and_slide()
	
	C.mesh_angle_lerp(_delta, 0.3)


var obj_vel = Vector3(0, 5, -5)
var obj_rotran = Vector3(150, 150, 150)

var scene_path = "ThermalDetonator.tscn"
var script_path = "ThermalDetonator.gd"
var obj_materials = {
	"0": {
		"Type": "Preset",
		"Preset": "Black"
	},
	"1": {
		"Type": "Preset",
		"Preset": "Dark Bluish Grey"
	},
	"2": {
		"Type": "Preset",
		"Preset": "Light Bluish Grey"
	},
#	"3": {
#		"Type": "Preset",
#		"Preset": "Red"
#	}
}

func throw_object():
	var object = l.get_load(SETTINGS.mod_path+"/"+C.origin_mod+"/characters/scenes/"+scene_path).instantiate()
	var script = l.get_load(SETTINGS.mod_path+"/"+C.origin_mod+"/characters/scripts/"+script_path)
	
	object.set_script(script)
	
	C.get_parent().add_child(object)
	
	var angle = C.get_node("Mesh").rotation.y
	var skele : Skeleton3D = C.get_node("Mesh/Armature/Skeleton3D")
	object.transform = skele.get_bone_global_pose(throw_bone).rotated(Vector3.UP, angle)
	object.position += skele.global_position
	object.origin_mod = C.origin_mod
	
	var rot = Vector3(0, 0, 0)
	rot.x = randf_range(-obj_rotran.x, obj_rotran.x)
	rot.y = randf_range(-obj_rotran.y, obj_rotran.y)
	rot.z = randf_range(-obj_rotran.z, obj_rotran.z)
	
	for matte in obj_materials.keys():
		for m in [object.get_node("Normal"), object.get_node("Glow")]:
			m.set_surface_override_material(int(matte), MATERIALS.get_matte(obj_materials.get(matte), C.origin_mod))
	
	object.apply_torque(rot)
	object.apply_central_impulse(obj_vel.rotated(Vector3.UP, angle))
	
	audio_player.play("ThrowObject")
	
	object.thrower = C
	
	return object
