extends "res://Logic/LOGIC.gd"

# Logic Type: WEAPON
# Contains: Sword Helpers

var our_prefix = "Gun"
var Extras = null
var GunTipNode = null

var weapon_mesh_path = {"cModelsPath" : "Blaster"}
var weapon_materials = {
	"0": {
		"Type": "Preset",
		"Preset": "Black"
	},
	"1": {
		"Type": "Preset",
		"Preset": "Red"
	}
}

var bullet_mesh_path = "bullet.obj"
var bullet_materials = {
	"0": {
		"Type": "Load",
		"cMaterialsPath": "GlowyBaseMaterial.tres",
		"Config": {"albedo_color": "ffffff"}
	},
	"1": {
		"Type": "Load",
		"cMaterialsPath": "GlowyBaseMaterial.tres",
		"Config": {"albedo_color": "ff0000"}
	}
}

var gun_tip_offset = Vector3(0, .35, -.5)

var cooldown_max = 0.4
var ai_cooldown_max = 1
var cooldown_remaining = 0.0

var gun_snap_range = 100.0
var gun_snap_cone = 0.8

var knockback = 2

var valid_logics = ["Base", "Jump"]
var valid_jump_states = ["Jump", "Jetpack"]

var cols = ["BulletCollision.tscn"]
var scrpt = "bullet.gd"

func _ready():
	reset_cooldown()
	spawn_objects()
	
	if C.AI:
		cooldown_remaining = randf_range(0, ai_cooldown_max*2)

func _process(_delta):
	if C.weapon_prefix == our_prefix:
		Extras.show()
	else:
		Extras.hide()


func spawn_objects():
	
	Extras = BoneAttachment3D.new()
	var mesh_instance = MeshInstance3D.new()
	GunTipNode = Node3D.new()
	Extras.add_child(mesh_instance)
	
	if weapon_mesh_path != {}:
		var mesh_path = f.get_data_path(weapon_mesh_path)
		
		var weapon_mesh = o.get_obj(mesh_path)
		
		mesh_instance.mesh = weapon_mesh
		
		for matte in weapon_materials.keys():
			mesh_instance.set_surface_override_material(int(matte), MATERIALS.get_matte(weapon_materials.get(matte), C.origin_mod))
	
	Extras.add_child(GunTipNode)
	GunTipNode.position = gun_tip_offset
	
	get_node("../../Mesh/Armature/Skeleton3D").add_child(Extras)
	
	mesh_instance.material_overlay = MATERIALS.FlashOverlay
	C.meshes_to_modulate.append(mesh_instance)
	
	Extras.hide()
	Extras.bone_idx = 19

func reset_cooldown():
	if not C.AI:
		cooldown_remaining = cooldown_max
	else:
		cooldown_remaining = ai_cooldown_max

func reset():
	Extras.free()

func shoot(rot, target):
	
	if anim.current_animation == our_prefix+"Idleloop":
		anim.play(our_prefix+"Shoot")
	elif anim.current_animation == our_prefix+"Activate":
		anim.play(our_prefix+"Shoot", 0)
	
	audio_player.play("Shoot")
	
	spawn_bullet(rot, target)
	reset_cooldown()


var bullet_splat_color = "ff3224"
func spawn_bullet(rot, target):
	var origination = get_gun_tip()
	
	var new_bullet = generate_bullet_scene()
	C.get_parent().add_child(new_bullet)
	new_bullet.rotation = rot
	new_bullet.position = origination
	new_bullet.who_shot_me = C
	new_bullet.knockback = knockback
	new_bullet.target = target
	new_bullet.splat_color = bullet_splat_color
	
	if target and is_instance_valid(target):
		warn_target(target)


func generate_bullet_scene():
	var bullet_parent = Area3D.new()
	var bullet_script = l.get_load(SETTINGS.mod_path+"/"+C.origin_mod+"/characters/scripts/"+scrpt)
	
	var m = MeshInstance3D.new()
	bullet_parent.add_child(m)
	m.name = "Mesh"
	
	var loaded_mesh = o.get_obj(SETTINGS.mod_path+"/"+C.origin_mod+"/characters/models/"+bullet_mesh_path)
	
	m.mesh = loaded_mesh
	
	bullet_parent.set_script(bullet_script)
	
	bullet_parent.set_collision_mask_value(2, true)
	
	# create collisions
	for col in cols:
		var new_col = l.get_load(SETTINGS.mod_path+"/"+C.origin_mod+"/characters/collisions/"+col).instantiate()
		
		bullet_parent.add_child(new_col)
	
	for material in bullet_materials.keys():
		m.set_surface_override_material(int(material), MATERIALS.get_matte(bullet_materials.get(material), C.origin_mod))
	
	bullet_parent.add_to_group("projectile")
	
	return bullet_parent


func warn_target(target):
	if target.has_method("warn"):
		target.warn("projectile", [self])


func can_shoot():
	if cooldown_remaining <= 0:
		return true
	return false


func test_shoot():
	
	var opponent = find_opponent()
	var rot = Vector3(0, C.mesh_angle_to+PI, 0)
	
	if opponent:
		rot = get_gun_rot_to_char(opponent)
	
	shoot(rot, opponent)



func get_rot_to_char(c):
	var targetPos = c.aim_pos+c.global_position
	
	# Get the direction vector from the source to the target
	var direction = (C.global_position-targetPos).normalized()
	
	# Calculate the rotation that points from the source to the target
	
	var rotationBasis = Basis.looking_at(direction, Vector3(0, 1, 0))
	var rot = rotationBasis.get_euler()
	
	return rot


func get_gun_rot_to_char(c):
	var targetPos = c.aim_pos+c.global_position
	
	# Get the direction vector from the source to the target
	var direction = (get_gun_tip() - targetPos).normalized()
	
	# Calculate the rotation that points from the source to the target
	var rotationBasis = Basis.looking_at(direction, Vector3(0, 1, 0))
	var rot = rotationBasis.get_euler()
	
	return rot


func update_ray(t):
	var rc = get_ray_cast()
	
	rc.global_position = get_gun_tip()
	rc.target_position = (t.aim_pos+t.global_position) - get_gun_tip()
	
	rc.force_raycast_update()


func draw_weapon():
	if C.weapon_prefix == "":
		C.weapon_prefix = our_prefix
		if C.is_on_floor():
			audio_player.play("GunOut")
			anim.play(our_prefix+"Activate", .3)


func store_weapon():
	if C.weapon_prefix == our_prefix:
		audio_player.play("GunIn")
		anim.play(our_prefix+"Deactivate", .3)
		C.weapon_prefix = ""


func inclusive_physics(_delta):
	
	if not C.AI:
		# Make sure we can shoot in this current logic state
		if valid_logics.has(C.movement_state):
			if check_logics_validity(C.movement_state):
				# Turning on/off current weapon
				if C.PHYSkey_just_pressed("Fight"):
					
					if C.weapon_prefix == our_prefix:
						if can_shoot():
							test_shoot()
					
					draw_weapon()
				
				if C.key_press("Special"):
					if C.is_in_base_movement_state():
					#if anim.current_animation == our_prefix+"Idleloop":
						store_weapon()
	
	cooldown_remaining -= _delta


func check_logics_validity(l_name):
	var logic = get_parent().get_node(l_name)
	
	if l_name == "Jump":
		if !valid_jump_states.has(logic.current_jumping_logic):
			return false
	
	if !C.generic_can_draw_weapon():
		return false
	
	return true


var dist_weight = 1
var angle_weight = 2
var player_penalty = 3

func find_opponent():
	# add raycast
	
	var in_cone = []
	
	for destroyable in get_tree().get_nodes_in_group("AttackLockOn"):
		
		var can_be_targeted = true
		
		if destroyable.has_method("can_be_targeted"):
			if not destroyable.can_be_targeted():
				can_be_targeted = false
		
		if not char_not_obstructed(destroyable):
			can_be_targeted = false
		
		if not destroyable == C and can_be_targeted:
			var target_pos2 = destroyable.global_position
			var self_pos2 = C.global_position
			
			var rot_dir = Basis.looking_at(target_pos2-self_pos2, Vector3.UP).get_euler().y
			
			var rot_to = abs(f.angle_to_angle(C.mesh_angle_to, rot_dir))
			
			if rot_to <= gun_snap_cone:
				var dist = target_pos2.distance_to(self_pos2)
				in_cone.append({"d" : destroyable, "rot_to" : rot_to, "dist" : dist})
	
	
	var most_desirable = null
	var backup = null
	for opponent in in_cone:
		if opponent.dist <= gun_snap_range:
			
			var desirability = (opponent.dist/gun_snap_range*dist_weight) + (opponent.rot_to/gun_snap_cone*angle_weight)
			
			if opponent.d.is_in_group("Character"):
				
				if opponent.d.player:
					desirability *= player_penalty
			
			opponent["desirability"] = desirability
			
			if not backup:
				backup = opponent
				most_desirable = opponent
			else:
				# if there is something to compare to
				var their_des = most_desirable.desirability
				var our_des = desirability
				
				if our_des < their_des:
					most_desirable = opponent
					backup = opponent
	
	var final_descision
	
	if most_desirable:
		final_descision = most_desirable.d
	elif backup:
		final_descision = backup.d
	
	return final_descision

func WEAPON_AI():
	pass

func char_not_obstructed(c):
	update_ray(c)
	if RayCast.is_colliding():
		if not RayCast.get_collider() == c:
			return false
	
	return true


var RayCast = null
func get_ray_cast():
	if not RayCast:
		RayCast = RayCast3D.new()
		add_child(RayCast)
	
	return RayCast


func get_gun_tip():
	return GunTipNode.global_position
