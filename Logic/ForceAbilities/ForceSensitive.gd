extends "res://Logic/LOGIC.gd"

var valid_logics = ["Base"]

var force_delay = 0.0
var force_delay_max = 5.5

var force_target = null

var current_charge = 0.0
var max_charge = 1.0
var predicted_pos = Vector3()

#var selected_ability = null

var force_abilities = {
	"Up" : {
		"Target" : "ForcePushed",
		"TargetPath" : "ForceAbilities/ForcePushed.gd",
		"Self" : "ForcePush",
		"Icon" : "ForcePush.png",
		"ChargeUp" : 1.0,
	},
	"Right" : {
		"Target" : "ForceMindTricked", 
		"TargetPath" : "ForceAbilities/ForceMindTricked.gd",
		"Self" : "ForceMindTrick",
		"Icon" : "ForceMindTrick.png",
		"ChargeUp" : 0.5,
	}
}

var force_colour = Color.BLUE

func _ready():
	ensureForceOutline_exists()

func inclusive_physics(_delta):
	#C.get_node("Label3D").text = str(current_charge)
	
	if C.movement_state != "ForceSensitive":
		current_charge = 0.0
		
		if C.key_just_pressed("Special") and !force_target:
			force_delay = force_delay_max
	
	# make sure the outline exists and get a reference to it and the animation. then hide it
	ensureForceOutline_exists()
	var force_outline = get_node("ForceOutline")
	var force_anim = force_outline.get_node("Anim")
	force_outline.hide()
	
	force_outline.charge = current_charge/max_charge
	
	# if we are still alive and not dead
	if !C.AI and !C.dead:
		
		## This block here positions the force outline position and checks if we press special and visually shows which forces are avaliable
		# If we have a force target and they are valid and not dead
		if generic_check_force_validity(force_target):#force_target and is_instance_valid(force_target) and !force_target.dead and global_position.distance_squared_to(force_target.global_position) < force_dist*force_dist:
			force_outline.show()
			if current_charge > 0.0:
				force_outline.global_position = predicted_pos
			else:
				force_outline.global_position = force_target.global_position + force_target.aim_pos
			
			# disable the ones that don't work if its a force box
			if force_target.is_in_group("Character"):
				var valid_abilities = force_target_valid_abilities_list(force_target)
				
				for slot in force_abilities.keys():
					var data = force_abilities.get(slot)
					
					if !valid_abilities.has(data.Self):
						force_outline.get_node(slot).transparency = 0.8
					else:
						force_outline.get_node(slot).transparency = 0.0
			
			# We set our movement state to ForceSensitive and get ready to pick a power
			if C.key_press("Special") and C.is_on_floor() and valid_logics.has(C.movement_state):
				C.set_movement_state("ForceSensitive")
				current_charge = 0.0
				#selected_ability = null
		else:
			force_target = null
		
		
		## This block here deals with the visuals (updated every second) of the force outlines
		# If we are not currently using the force and are in our base state
		if C.is_in_base_movement_state():
			if force_delay > force_delay_max:
				var force = update_force()
				
				if !force == force_target:
					force_target = force
					
					if force:
						
						# get colours
						var slot_colour = force_colour.lightened(.5)
						slot_colour[3] = 0.3
						
						var force_colour_1 = force_colour
						force_colour_1[3] = 0.1
						
						var force_colour_2 = force_colour
						force_colour_2[3] = 0.1
						force_colour_2.h = force_colour.h+(randf()*.05)
						
						# hide all abilities
						for child in force_outline.get_children():
							if child.is_in_group("ForceSlot"):
								child.hide()
						
						var charge_colour = force_colour
						
						var Mesh1 = force_outline.get_node("Mesh1")
						var Mesh2 = force_outline.get_node("Mesh2")
						var Charge = force_outline.get_node("Charge")
						
						Mesh1.modulate = force_colour_1
						Mesh2.modulate = force_colour_2
						Charge.set_instance_shader_parameter("albedo", Color(charge_colour))
						
						if !force_target.is_in_group("ForceObject"):
							force_outline.scale = Vector3(1, 1, 1)
							
							# load icons into sprite3ds
							for slot in force_abilities.keys():
								var data = force_abilities.get(slot)
								var slot_node = force_outline.get_node(slot)
								
								var image = MATERIALS.load_texture(SETTINGS.mod_path+"/"+C.origin_mod+"/characters/textures/"+data.Icon)
								
								slot_node.modulate = slot_colour
								slot_node.transparency = 0
								slot_node.texture = image
								slot_node.show()
							
						else:
							force_outline.scale = Vector3(force_target.force_size, force_target.force_size, force_target.force_size)
					
					force_anim.stop()
					force_anim.play("ForceTurnOn")
				
				if not force:
					force_target = null
				
				force_delay = 0.0
			
			force_delay += _delta

func initiate():
	force_delay = 0.0


var prev_key
func exclusive_physics(_delta):
	
	base_state.gen_gravity(_delta)
	C.set_velocity(C.char_vel+C.push_vel+C.knock_vel)
	C.move_and_slide()
	
	if force_target:
		## This activates when we are focused on a target, ready to select a force power to use on them
		
		ensureForceOutline_exists()
		
		# look at our target
		var rot_to_force = Basis.looking_at(C.global_position-force_target.global_position).get_euler().y+PI
		C.mesh_angle_to = rot_to_force
		C.mesh_angle_lerp(_delta, 0.3)
		
		base_state.freeze()
		
		# IF THE OBJECT IS A CHARACTER
		if !force_target.is_in_group("ForceObject"):
			anim.play("ForceStatic", .2)
			
			# if any force power has been selected
			var any_key_pressed = false
			
			# loop through the keys to check if they are pressed
			for key in force_abilities.keys():
				var key_pressed = false
				
				if C.control_type == "keyboard":
					if C.key_press(key):
						key_pressed = true
				elif C.control_type == "controller":
					key_pressed = C.controller_direction_pressed(key)
				
				if key_pressed:
					#print("yo")
					any_key_pressed = true
					var ability_data = force_abilities.get(key)
					
					var force_ability = ability_data.Self
					var target_ability = ability_data.Target
					var target_ability_path = ability_data.TargetPath
					var chargeup = ability_data.get("ChargeUp", 1.0)
					var ab_range = ability_data.get("Range", 1.0)
					var ab_vel_proj = ability_data.get("VelocityPredict", true)
					
					if can_use_ability_on_target(force_target, force_ability, target_ability, target_ability_path):
						
						#var target_consequence = force_abilities.get(key).Target
						#force_target.get_logic(target_consequence).opponent = C
						#force_target.set_movement_state(target_consequence)
						
						if !key==prev_key:
							current_charge = 0.0
						
						max_charge = chargeup
						if chargeup == 0.0:
							C.get_logic(force_ability).force_target = force_target
							C.set_movement_state(force_ability)
							
							C.knock_out_key(key)
							
							force_delay = force_delay_max
						else:
							if current_charge == 0.0:
								predicted_pos = force_target.global_position + force_target.aim_pos
								
								if ab_vel_proj:
									predicted_pos += force_target.velocity*chargeup
							
							current_charge += _delta
							
							var close_enough = predicted_pos.distance_squared_to(force_target.global_position + force_target.aim_pos) < ab_range*ab_range
							if current_charge >= chargeup:
								if close_enough:
									C.get_logic(force_ability).force_target = force_target
									C.set_movement_state(force_ability)
									C.knock_out_key(key)
								else:
									force_target = null
								
								force_delay = force_delay_max
						
						
						
						prev_key = key
						break
					else:
						force_target = null
						C.reset_movement_state()
			
			if !any_key_pressed:
				current_charge = 0.0
		else:
			anim.play("ForceUse", .2)
			force_target.forcing = true
		
		
		## This block resets us to base movement state we cancel or the target dies or is invalid
		if !is_instance_valid(force_target) or !force_target or force_target.dead:
			
			if is_instance_valid(force_target) and force_target.is_in_group("ForceObject"):
				force_target.forcing = false
			
			anim.play(C.weapon_prefix+"Idleloop", .2)
			force_target = null
			#selected_ability = null
			get_node("ForceOutline").hide()
			C.reset_movement_state()
		
		
		# I changed this but I'm not exactly sure what it will effect
		if !C.key_press("Special"):
			
			if is_instance_valid(force_target) and force_target.is_in_group("ForceObject"):
				
				force_target.forcing = false
			
			anim.play(C.weapon_prefix+"Idleloop", .2)
			#selected_ability = null
			get_node("ForceOutline").hide()
			C.reset_movement_state()
	else:
		C.reset_movement_state()


var force_dist = 20
var force_FOV = .4
func update_force():
	
	# the best force we have found
	var best_force = null
	for local_force in get_tree().get_nodes_in_group("Character")+get_tree().get_nodes_in_group("ForceObject"):
		
		if !local_force == C and !local_force.dead:
			
			if local_force.position.distance_squared_to(C.position) <= force_dist*force_dist:
				
				# the distance to the current force in the loop
				var angle_to = get_angle_to_angle_force(local_force)
				var local_desire = get_desire(local_force)
				
				# if we are facing the forceable
				if angle_to < force_FOV:
					if is_force_valid(local_force):
						# This is the point where this force is a valid force to use
						if best_force:
							# The desirability of best_force
							var best_desire = get_desire(best_force)
							
							# if the local force is closer than the best force
							if local_desire < best_desire:
								# set the best force to the current force, as it is closer
								best_force = local_force
						else:
							# if this is the first force, then set best_force to it
							best_force = local_force
	
	# return the best force we found
	return best_force

func generic_check_force_validity(force_object):
	#print('where is this being checked?')
	
	if !force_object:
		return false
	
	if !is_instance_valid(force_object):
		return false
	
	if global_position.distance_squared_to(force_target.global_position) >= force_dist*force_dist:
		return false
	
	if force_object.is_in_group("Character"):
		if force_object.dead:
			return false
	
	if !is_force_valid(force_object):
		return false
	
	return true


#func uninitiate():
	#for key in force_abilities.keys():
		#
		#if C.control_type == "keyboard":
			#if C.key_press(key):
				#C.knock_out_key(key)


func is_force_valid(force_object):
	
	if force_object.is_in_group("ForceObject"):
		
		if force_object.nogo == null:
			return true
		
		for slide_idx in range(0, C.get_slide_collision_count()):
			var collide = C.get_slide_collision(slide_idx)
			if collide.get_collider() == force_object.nogo:
				return false
		
		return true
	
	if force_target_valid_abilities_list(force_object).size() > 0:
		return true
	
	return false


func force_target_valid_abilities_list(force_object):
	var valid_abilities_list = []
	
	for ability_data in force_abilities.values():
		var force_ability = ability_data.Self
		var target_ability = ability_data.Target
		var target_ability_path = ability_data.TargetPath
		
		if can_use_ability_on_target(force_object, force_ability, target_ability, target_ability_path):
			valid_abilities_list.append(force_ability)
	
	return valid_abilities_list


func target_viable_for_ability(target, ability):
	
	if ability.has_method("target_viable"):
		if !ability.target_viable(target):
			return false
	
	return true


func can_use_ability_on_target(target, ability_name, target_ability_name, target_ability_path):
	var logics = target.get_logics_list()
	
	var t_viable = target_viable_for_ability(target, C.get_logic(ability_name))
	
	if t_viable:
		if logics.has(target_ability_name):
				return true
		
		if target_can_be_given_logic(target, ability_name):
			target.add_logic(SETTINGS.get_logic_base_dir(C.origin_mod)+target_ability_path)
			return true
	
	return false


func target_can_be_given_logic(target, ability_name):
	
	# resolve force immunity first
	if target.has_logic("ForceImmunity"):
		if target.get_logic("ForceImmunity").abilities_immune.has(ability_name):
			return false
		
		if target.get_logic("ForceImmunity").auto_immune:
			if target.get_logic("ForceImmunity").valid_abilities.has(ability_name):
				return true
			return false
	
	# get the animations the ability needs
	var ability_anims = get_ability_target_anims(ability_name)
	
	# resolve adding the logic if the rig is right (correlated to the ability)
	if ability_needs_rig(ability_name):
		var ability_rigs = get_ability_rigs(ability_name)
		var target_rig = target.current_rig
		
		if ability_rigs.has(target_rig):
			var anims = f.merge_arrays(ability_anims.Required, ability_anims.Other)
			patch_up_targets_anims(target, anims)
			return true
		else:
			# resolve that maybe the target has provided a custom animation
			var target_anim = target.anim
			var anim_list = target_anim.get_animation_list()
			
			# make sure every anim we need is accounted for
			
			for ability_anim in ability_anims.Required:
				if !anim_list.has(ability_anim.Name):
					return false
	
	
	return true


func patch_up_targets_anims(target, anims):
	
	var target_anim = target.anim
	var anim_list = target_anim.get_animation_list()
	
	for animation in anims:
		if !anim_list.has(animation.Name):
			var anim_path = SETTINGS.mod_path+"/"+C.origin_mod+"/characters/anims/"+animation.Path
			target.add_animation(animation.Name, l.get_load(anim_path))


func exclusive_damage(damage:f.Damage):
	# When damaged also remove our force target
	C.get_logic("ForceSensitive").force_target = null
	C.get_logic("ForceSensitive").force_delay = 0.0
	
	C.reset_movement_state()
	C.generic_damage(damage.amount)


func generic_force_stuff(f_target, delta):
	# get a reference to the outline
	var force_outline = get_node("ForceOutline")
	
	# Check if we are not dead
	if !C.AI and !C.dead:
		
		# If our opponent is still valid then show the outline
		if f_target and is_instance_valid(f_target):
			force_outline.show()
			force_outline.global_position = f_target.global_position + f_target.aim_pos
	
	# Get the angle toward the target and look at them
	var rot_to_force = Basis.looking_at(C.global_position-f_target.global_position).get_euler().y+PI
	C.mesh_angle_to = rot_to_force
	C.mesh_angle_lerp(delta, 0.3)
	
	# Freeze movement from the base state
	base_state.freeze()
	
	# If we stop using the force, the target dies, there is no target, or the target is dead...
	if !C.key_press("Special") or !is_instance_valid(f_target) or !f_target or f_target.dead:
		# then reset our target, go back to idle and the base movement state
		f_target = null
		anim.play(C.weapon_prefix+"Idleloop", .2)
		C.reset_movement_state()


func ability_needs_rig(ability_name):
	var ability = C.get_logic(ability_name)
	
	if "needs_rig" in ability:
		return ability.needs_rig
	
	return false


func get_ability_rigs(ability_name):
	var ability = C.get_logic(ability_name)
	
	if "valid_rigs" in ability:
		return ability.valid_rigs
	
	return []


func get_ability_target_anims(ability_name):
	var ability = C.get_logic(ability_name)
	
	if "target_anims" in ability:
		return ability.target_anims
	
	return {"Required" : [], "Other" : []}


func get_desire(force):
	var angle = get_angle_to_angle_force(force)
	var dist = C.global_position.distance_to(force.global_position)*0.1
	
	return angle+dist


func get_angle_to_angle_force(force):
	var rot_y = 0
	if !force.global_position-C.global_position == Vector3(0, 0, 0):
		rot_y = Basis.looking_at(force.global_position-C.global_position).get_euler().y
	
	var real_move_dir = base_state.last_move_dir
	
	var real_angle = Vector2(-real_move_dir.x, real_move_dir.z).angle()+deg_to_rad(90)
	
	var angle_to = f.angle_to_angle(rot_y, real_angle)/PI
	
	return abs(angle_to)


func ensureForceOutline_exists():
	if get_node_or_null("ForceOutline") == null:
		var ForceOutline = l.get_load(SETTINGS.mod_path+"/"+C.origin_mod+"/characters/scenes/"+"forceoutline.tscn").instantiate()
		var ForceOutlineScript = l.get_load(SETTINGS.mod_path+"/"+C.origin_mod+"/characters/scripts/"+"forceoutline.gd")
		var ForceOutlineTexture = MATERIALS.load_texture(SETTINGS.mod_path+"/"+C.origin_mod+"/characters/textures/"+"force.png")
		
		ForceOutline.set_script(ForceOutlineScript)
		
		ForceOutline.get_node("Mesh1").texture = ForceOutlineTexture
		ForceOutline.get_node("Mesh2").texture = ForceOutlineTexture
		ForceOutline.get_node("Charge").material_override.set_shader_parameter("texture_albedo", ForceOutlineTexture)
		
		add_child(ForceOutline)
