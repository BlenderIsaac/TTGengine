extends "res://Logic/LOGIC.gd"

# Logic Type: MOVEMENT STATE
# Contains: Slam movement state

# slam variables
var slam_jumpspeed = 3
var slam_gravity = -15

var slam_range = 3

var our_prefix = "Sword"

var slam_colour = "7aff00"

var knockback = 8.0

var slammed = false

func exclusive_physics(_delta):
	C.get_base_movement_state().freeze()
	
	if C.is_on_floor():
		
		# Reset movement if we have hit the ground
		
		# Check if the animation is over and if it is end lunging
		if !anim.current_animation == "SlamHit" and slammed:
			anim.play(C.weapon_prefix+"Idleloop", 0.2)
			C.reset_movement_state()
		
		# If we have hit the ground play SlamHit and queue base so we know when its over
		if not slammed:#["SlamHit", our_prefix+"Idleloop"].has(anim.current_animation):
			
			for opponent in get_tree().get_nodes_in_group("Attackable"):
				if not opponent == C:
					if opponent.position.distance_to(C.position) < slam_range:
						if abs(opponent.position.y-C.position.y) < .5:
							
							if opponent.has_method("take_knockback"):
								var normalized_distance = (opponent.position-C.position).normalized()
								
								opponent.take_knockback(normalized_distance*knockback)
							
							if opponent.has_method("take_damage"):
								if opponent.position.distance_to(C.position) < slam_range:
									opponent.take_damage(f.Damage.new(1, C))
			
			audio_player.play("SaberSlam")
			anim.play("SlamHit", 0)
			slammed = true
			#anim.queue(our_prefix+"Idleloop")
			
			var slam_particles_reference = l.get_load(SETTINGS.mod_path+"/"+C.origin_mod+"/characters/scenes/Slam.tscn")
			var slam_particles = slam_particles_reference.instantiate()
			
			slam_particles.position = C.position
			
			C.get_parent().add_child(slam_particles)
			
			slam_particles.get_node("Particles").mesh.material = MATERIALS.get_tag_part_material(slam_colour)
			slam_particles.get_node("Decal").modulate = Color(slam_colour)
	
	# Calculate gravity and respawn position
	if not C.is_on_floor():
		C.char_vel.y += slam_gravity*_delta*C.var_scale
	else:
		C.char_vel.y = slam_gravity*_delta*C.var_scale
	
	
	C.set_velocity(C.char_vel)
	C.move_and_slide()


func can_switch():
	if C.is_on_floor():
		return false
	return true


func initiate():
	for opponent in get_tree().get_nodes_in_group("Attackable"):
		if opponent != self:
			if opponent.has_method("warn"):
				opponent.warn("aoe", [self])
	
	slammed = false
	audio_player.play("SlamInitiate")
	anim.play("SlamInitiate")
	anim.queue("Slamloop")
	C.char_vel.y = slam_jumpspeed*C.var_scale


func exclusive_damage(damage:f.Damage):
	
	if damage.from == null:
		C.generic_damage(damage.amount)
	
	elif not C.is_on_floor():
		if damage.from.is_in_group("projectile"):
			damage.from.deflect(C)
	else:
		C.generic_damage(damage.amount)
