extends "res://Logic/LOGIC.gd"

var current_grapple = null
var grapple_speed = 3.3

var gun_tip_logic = "ProjectileWeapon"

var our_prefix = "Gun"

var valid_logics = ["Base"]

func _ready():
	nav_agent.set_navigation_layer_value(5, true)

func inclusive_physics(_delta):
	if not C.movement_state == "Grapple":
		if Zipup:
			Zipup.hide()
	
	if C.key_press("Special") and C.is_on_floor() and valid_logics.has(C.movement_state) and !C.AI:
		# Check for valid grapple spots here
		var grapple = find_grapple()
		
		# if we have found a grapple
		if grapple:
			current_grapple = grapple
			
			C.set_movement_state("Grapple")


func initiate():
	
	audio_player.play("GrappleAttach")
	audio_player.start_loop("GrappleLoop")
	
	base_state.freeze()
	
	if C.AI:
		var grapple = find_grapple()
		
		# if we have found a grapple
		if grapple:
			current_grapple = grapple


func exclusive_physics(_delta):
	# if we have been set to force the weapon to come out
	# set the characters weapon prefix to our prefix
	C.weapon_prefix = our_prefix
	
	anim.play("Grappleloop", .3)
	
	# if the grapple exists continue
	if current_grapple:
		var diff = (current_grapple.grappling_to) - C.global_position
		var diff_norm = diff.normalized()*grapple_speed*C.var_scale*_delta*60
		
		C.mesh_angle_to = Basis.looking_at(C.global_position-current_grapple.grappling_to).get_euler().y + PI
		
		C.set_velocity(diff_norm)
		C.move_and_slide()
		
		update_zipup()
		
		# add another velocity thing to do x and z velocity? knockback?
		C.char_vel.y = diff.y
		if diff.length() < .3:
			cut_grapple()
			audio_player.play("GrappleDetach")
			audio_player.end_loop("GrappleLoop")
	else:
		# otherwise just reset movement state
		cut_grapple()
	
	C.mesh_angle_lerp(_delta, 0.3)


func has_nav(details):
	var link = details.owner
	if link.is_in_group("LinkGrapple"):
		return true
	return false


func update_zipup():
	ensure_zipup_exists()
	
	var MS = C.get_logic(gun_tip_logic)
	
	if MS:
		var tip = MS.get_gun_tip()
		Zipup.global_position = tip
		
		var from = Zipup.global_position
		var to = current_grapple.zipup_end
		
		Zipup.look_at_from_position(from, to)
		Zipup.get_node("zipup_chain").scale.y = from.distance_to(to)*10
		Zipup.get_node("zipup_chain").position.z = -from.distance_to(to)/2
		Zipup.show()


var Zipup = null
func ensure_zipup_exists():
	if not Zipup:
		Zipup = Node3D.new()#l.get_load("res://Logic/zipup.tscn").instantiate()
		
		var MeshInstance = MeshInstance3D.new()
		var M = BoxMesh.new()
		
		M.size = Vector3(0.07, 0.1, 0.07)
		var Matte = MATERIALS.get_loaded_material("ZipupChain.tres", C.origin_mod)
		M.material = Matte
		
		MeshInstance.mesh = M
		Zipup.add_child(MeshInstance)
		
		MeshInstance.rotation_degrees.x = 90
		Zipup.name = "zipup"
		MeshInstance.name = "zipup_chain"
		
		Zipup.hide()
		add_child(Zipup)


func cut_grapple():
	current_grapple = null
	if Zipup:
		Zipup.hide()
	anim.play(our_prefix+"Fallloop", .1)
	C.reset_movement_state()


func find_grapple():
	# the best grapple we have found
	var best_grapple = null
	for local_grapple in get_tree().get_nodes_in_group("Grapple"):
		
		# the distance to the current grapple in the loop
		var local_dist = C.global_position.distance_to(local_grapple.global_position)
		
		# the maximum distance we can be away from the grapple before it is unusable
		var max_dist = local_grapple.grapple_size
		
		# if we are close enough to the grapple
		if local_dist <= max_dist:
			# This is the point where this grapple is a valid grapple to use
			if best_grapple:
				# The distance to the best grapple
				var best_dist = best_grapple.global_position.distance_to(C.global_position)
				
				# if the local grapple is closer than the best grapple
				if local_dist < best_dist:
					# set the best grapple to the current grapple, as it is closer
					best_grapple = local_grapple
				
			else:
				# if this is the first grapple, then set best_grapple to it
				best_grapple = local_grapple
	
	# return the best grapple we found
	return best_grapple

