extends "res://Logic/LOGIC.gd"

var valid_logics = ["Base"]

var magic_delay = 0.0
var magic_delay_max = 0.5

var magic_target = null

var magic_colour = "86e27a"

var target_logic = "MagicLifted.gd"
var target_logic_path = "MagicLifted.gd"

var go_up_time = 0.5

func _ready():
	ensuremagicOutline_exists()

func inclusive_physics(_delta):
	ensuremagicOutline_exists()
	var magic_outline = get_node("MagicOutline")
	magic_outline.hide()
	
	if !C.AI and !C.dead:
		
		
		if !C.movement_state == "NightsisterMagic":
			
			if C.key_press("Special") and C.is_on_floor() and valid_logics.has(C.movement_state):
				check_magic()
			
			if object_valid(magic_target) and magic_target.is_on_floor():
				magic_outline.show()
				magic_outline.global_position = magic_target.global_position + get_aim_pos(magic_target)
				
				if C.key_press("Special") and C.is_on_floor() and valid_logics.has(C.movement_state):
					C.set_movement_state("NightsisterMagic")
			else:
				magic_target = null
		
		if C.is_in_base_movement_state():
			if magic_delay > magic_delay_max:
				check_magic()
			
			magic_delay += _delta


func initiate():
	anim.play(C.weapon_prefix+"MagicLift")
	magic_delay = 0.0


func exclusive_physics(_delta):
	ensuremagicOutline_exists()
	var magic_outline = get_node("MagicOutline")
	magic_outline.show()
	
	if anim.current_animation_position/anim.current_animation_length >= go_up_time:
		
		if object_valid(magic_target):
			
			var dist = (magic_target.global_position + get_aim_pos(magic_target)).distance_to(magic_outline.global_position)
			
			if dist < 1.0:
				if !magic_target.is_in_group("Character") or !magic_target.movement_state == "MagicLifted":
					
					ensuremagicOutline_exists()
					
					# TODO: fix here
					var rot_to_magic = Basis.looking_at(C.global_position-magic_target.global_position).get_euler().y+PI
					C.mesh_angle_to = rot_to_magic
					
					C.mesh_angle_lerp(_delta, 0.3)
					
					base_state.freeze()
					
					var valid = false
					if magic_target.is_in_group("Character"):
						
						if can_use_ability_on_target(magic_target):
							valid = true
							if !magic_target.anim.has_animation("MagicLifted"):
								var path = SETTINGS.mod_path+"/"+C.origin_mod+"/characters/anims/nightsister/MagicLiftedloop.res"
								var new_anim = l.get_load(path)
								
								magic_target.add_animation("MagicLifted", new_anim)
							
							magic_target.set_movement_state("MagicLifted")
					else:
						if "being_ns_lifted" in magic_target:
							magic_target.ns_lift()
							valid = true
					
					
					if valid == true:
						var sister_lift = l.get_load("res://TEMP/NightSisterLift.tscn").instantiate()
						sister_lift.position = magic_target.position
						sister_lift.lifted = magic_target
						C.get_parent().add_child(sister_lift)
						magic_delay = magic_delay_max
		
		
		anim.queue(C.weapon_prefix+"Idleloop")
		
		magic_target = null
		get_node("MagicOutline").hide()
		
		C.reset_movement_state()
		
		#if !C.key_press("Special") or !is_instance_valid(magic_target) or !magic_target or magic_target.dead:
			#anim.play(C.weapon_prefix+"Idleloop", .2)
			#magic_target = null
			#get_node("MagicOutline").hide()
			#C.reset_movement_state()

func check_magic():
	
	ensuremagicOutline_exists()
	var magic_outline = get_node("MagicOutline")
	var magic_anim = magic_outline.get_node("Anim")
	
	var magic = update_magic()
	
	if !magic == magic_target:
		magic_target = magic
		
		if magic:
			
			var magic_colour_2 = Color(magic_colour)
			magic_colour_2.h = Color(magic_colour).h+(randf()*.05)
			
			var Mesh1 = magic_outline.get_node("Mesh1")
			var Mesh2 = magic_outline.get_node("Mesh2")
			
			Mesh1.modulate = Color(magic_colour)
			Mesh2.modulate = magic_colour_2
		
		magic_anim.stop()
		magic_anim.play("ForceTurnOn")
	
	if not magic:
		magic_target = null
	
	magic_delay = 0.0


var magic_dist = 20
var magic_FOV = .4
func update_magic():
	
	# the best magic we have found
	var best_magic = null
	for local_magic in get_tree().get_nodes_in_group("Character")+get_tree().get_nodes_in_group("NightsisterMagicObject"):
		
		if !local_magic == C and object_valid(local_magic):
			
			if local_magic.position.distance_to(C.position) <= magic_dist:
				
				if !local_magic.has_method("is_on_floor") or local_magic.is_on_floor():
					
					# the distance to the current magic in the loop
					var angle_to = get_angle_to_angle_magic(local_magic)
					var local_desire = get_desire(local_magic)
					
					# if we are facing the magicable
					if angle_to < magic_FOV:
						# This is the point where this magic is a valid magic to use
						if best_magic:
							# The desirability of best_magic
							var best_desire = get_desire(best_magic)
							
							# if the local magic is closer than the best magic
							if local_desire < best_desire:
								# set the best magic to the current magic, as it is closer
								best_magic = local_magic
						else:
							# if this is the first magic, then set best_magic to it
							best_magic = local_magic
	
	# return the best magic we found
	return best_magic

func target_viable_for_ability(target, ability):
	
	if ability.has_method("target_viable"):
		if !ability.target_viable(target):
			return false
	
	return true


func can_use_ability_on_target(target):
	#var logics = target.get_logics_list()
	
	# add range checks here
	
	if target_can_be_given_logic(target, "NightsisterMagic"):
		target.add_logic(SETTINGS.get_logic_base_dir(C.origin_mod)+target_logic_path)
		return true
	
	return false


func target_can_be_given_logic(target, ability_name):
	
	# resolve magic immunity first
	if target.has_logic("MagicImmunity"):
		if target.get_logic("MagicImmunity").abilities_immune.has(ability_name):
			return false
		
		if target.get_logic("MagicImmunity").auto_immune:
			if target.get_logic("MagicImmunity").valid_abilities.has(ability_name):
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


func exclusive_damage(_amount, _who_from=null):
	C.get_logic("NightsisterMagic").magic_target = null
	C.get_logic("NightsisterMagic").magic_delay = 0.0
	
	C.reset_movement_state()
	C.generic_damage(_amount)


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


func get_desire(magic):
	var angle = get_angle_to_angle_magic(magic)
	var dist = C.global_position.distance_to(magic.global_position)*0.1
	
	return angle+dist


func get_angle_to_angle_magic(magic):
	var rot_y = 0
	if !magic.global_position-C.global_position == Vector3(0, 0, 0):
		rot_y = Basis.looking_at(magic.global_position-C.global_position).get_euler().y
	
	var angle_to = f.angle_to_angle(rot_y, C.mesh_angle_to)/PI
	
	return abs(angle_to)


func ensuremagicOutline_exists():
	if get_node_or_null("MagicOutline") == null:
		var magicOutline = l.get_load(SETTINGS.mod_path+"/"+C.origin_mod+"/characters/scenes/"+"forceoutline.tscn").instantiate()
		var magicOutlineScript = l.get_load(SETTINGS.mod_path+"/"+C.origin_mod+"/characters/scripts/"+"forceoutline.gd")
		var magicOutlineTexture = MATERIALS.load_texture(SETTINGS.mod_path+"/"+C.origin_mod+"/characters/textures/"+"magic.png")
		
		magicOutline.set_script(magicOutlineScript)
		
		magicOutline.get_node("Mesh1").texture = magicOutlineTexture
		magicOutline.get_node("Mesh2").texture = magicOutlineTexture
		
		magicOutline.name = "MagicOutline"
		
		add_child(magicOutline)

func object_valid(obj):
	if obj and is_instance_valid(obj) and (!"dead" in obj or !obj.dead):
		return true
	return false

func get_aim_pos(obj):
	var aim_pos = Vector3(0, 1, 0)
	if "aim_pos" in obj:
		aim_pos = obj.aim_pos
	
	return aim_pos
