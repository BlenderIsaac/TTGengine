extends StaticBody3D


var aim_pos = Vector3(0, 1.5, 0)
var dead = false
var knock_vel = Vector3(0, 0, 0)
var stud_value = 1000

var audio = null

var sound_mod = "Ahsoka Show"
var sounds = {
		"Destroy" : {
			"SharedPath" : ["EXP_DEBRIS_04.WAV", "EXP_DEBRIS_05.WAV"]
		},
}

func _ready():
	#set_meta("obj_changes", ["dead"])
	add_to_group("AttackLockOn")
	add_to_group("Attackable")
	set_collision_layer_value(2, true)
	audio = f.make("res://Scripts/AudioPlayer.tscn", position+aim_pos, self)
	audio.add_library(sounds, sound_mod)


func take_knockback(amount, _who_from=null):
	knock_vel = amount

var health = 1
func take_damage(damage:f.Damage):
	health -= damage.amount
	if health <= 0:
		die()

func die():
	
	audio.play("Destroy")
	audio.dispose(get_parent())
	
	var studs_dropped = f.get_stud_values_for_count(stud_value)
	for stud in studs_dropped:
		drop_stud(stud)
	
	Levels.i_am_dead(self)
	
	queue_free()


var stud_spread = 4
var stud_max_height = 6.0
var stud_min_height = 1.0

func drop_stud(type):
	var sTUD_pICKUP = l.get_load("res://Objects/Stud.tscn")
	
	var stud = sTUD_pICKUP.instantiate()
	get_parent().add_child(stud)
	stud.set_type(type)
	stud.global_position = global_position+Vector3(0, 1, 0)
	
	var rand_vel_up = randf_range(stud_min_height, stud_max_height)
	var rand_vel_top = Vector2(randf_range(-1, 1), randf_range(-1, 1))
	rand_vel_top = rand_vel_top*stud_spread
	var final_rand_vel = Vector3(rand_vel_top.x, rand_vel_up, rand_vel_top.y)
	
	stud.linear_velocity = final_rand_vel

#
#func drop_bits():
	#
	#
	#var dropped_bits = []
	#var bits = []
	#
	#for b in get_children():
		#if b is MeshInstance3D:
			#b.material_overlay = MATERIALS.FlashOverlay
			#bits.append(b.get_path())
	#
	#for bit_name in bits:
		#var bit_node = get_node_or_null(bit_name)
		#if bit_node:
			#var bit = drop_bit(bit_node)
			#
			#dropped_bits.append(bit)
			#
			#bit.set_collision_layer_value(1, false)
			#bit.set_collision_layer_value(4, true)
			#
			#get_parent().add_child(bit)
			#
			#var rand_torque = Vector3(randf_range(-3, 3), randf_range(-3, 3), randf_range(-3, 3))
			#var rand_vel = Vector3(randf_range(-3, 3), randf_range(-3, 3), randf_range(-3, 3))
			#
			#bit.apply_torque(rand_torque)
			#bit.apply_impulse(rand_vel + (knock_vel))
			#
			#bit.physics_material_override = l.get_load("res://Materials/BitsPhysicsMaterial.tres")
	#
	## make so the bits don't collide with any other bits
	#for bit in dropped_bits:
		#for bit2 in dropped_bits:
			#bit.add_collision_exception_with(bit2)
#
#
#func drop_bit(bit):
	#var mesh_drop = bit.duplicate()
	#var rigid = RigidBody3D.new()
	#var col = CollisionShape3D.new()
	#var col_shape = BoxShape3D.new()
	#
	#var aabb = mesh_drop.mesh.get_aabb()
	#
	#mesh_drop.name = "Mesh"
	#
	#col.shape = col_shape
	#col_shape.size = aabb.size
	#
	#col.position = aabb.position + aabb.size/2
	#
	#rigid.add_child(col)
	#rigid.add_child(mesh_drop)
	#
	#rigid.position = bit.global_position
	#rigid.rotation.y = bit.global_rotation.y
	#
	#rigid.set_script(l.get_load("res://Scripts/VisualDeath.gd"))
	#
	#rigid.setup()
	#
	##if mesh_drop.get("instance_shader_parameters/my_color"):
	##	mesh_drop.set("instance_shader_parameters/my_color", Vector4())
	#
	#return rigid
