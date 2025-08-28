extends CharacterBody3D
class_name Character

var section : Section

var will_respawn := false

# Some references
var anim : AnimationPlayer
var nav_agent : NavigationAgent3D# = $Agent
var modulate_anim : AnimationPlayer# = $Modulation
var audio : AudioPlayer# = $AudioPlayer
var tail : RayCast3D# = $Tail
var tailcast : ShapeCast3D# = $TailCast
var collision
var pushaway_collision
var rig
var rig_class := "NoRig"
var armature
var skeleton : Skeleton3D

var input_vector := Vector2(0, 0)

# variable scaling
@export var var_scale := 4.1

# flash value that character meshes borrows from
@export var flash_value := Color()
var meshes_to_modulate = []

var char_spawn = false
var char_spawn_index = 0

var char_name = "NULL"

# variables for root vel
var prev_pose = Vector3()

# icon storage
var icon = null

# initial sounds for audio
var initial_sounds = {
	"FallApart" : {
		"cSoundsPath" : ["FALLAPART01.WAV", "FALLAPART02.WAV", "FALLAPART03.WAV", "FALLAPART04.WAV"]
	},
	"CharacterSwitch" : {
		"cSoundsPath" : ["TOGGLECHAR.WAV"]
	},
	"CharacterTag" : {
		"cSoundsPath" : ["SWCHAR.WAV"]
	},
	"HeartCollect" : {
		"cSoundsPath" : ["HEART.WAV"]
	},
	"CoinCollect" : {
		"cSoundsPath" : ["COIN1.WAV", "COIN2.WAV"]
	},
	"BlueCoinCollect" : {
		"cSoundsPath" : ["COINBLUE.WAV"]
	}
}

# variables to do with respawn wait
var respawn_left = 3.0
var respawn_wait = 3.0

# invincibility frames post damage
var iframes_left = 0.0

# the other characters pushing on us
var bodys_pushing = []
var push_strength = 20

# our movement state
# Probably change variable name
var movement_state

var movement_logics = {}
var jump_logics = {}
var action_logics = {}
var attribute_logics = {}
var interaction_logics = {}

var animations = {}
var sounds = {}

var identity
var alignment

var weapons = {}

# our current velocity, move direction, knockback velocity, and pushed velocity
var char_vel = Vector3()
var push_vel = Vector3()
var knock_vel = Vector3()

# respawn variable
var respawn_point = Vector3()

var logic_switched_vars = {}

# aim_pos - where projectiles aim
var aim_pos = Vector3(0, 0.9, 0)

signal health_changed
signal death

# health variables
var max_hit_points = 4.0:
	set(value):
		max_hit_points = value
		emit_signal("health_changed")
var hit_points = 4.0:
	set(value):
		hit_points = value
		health_ratio_accurate = false
		emit_signal("health_changed")
var ai_hit_points = 4.0
var health_ratio = 0.0
var health_ratio_accurate = false
var hearts_per_row = -1
var heart_x_offset = 30

# the lerp angles for mesh turning
var mesh_angle_to = 0.0

# This is the history of where we can respawn
var respawn_history = []

# This function is called when this character is first added to the scene
func _ready():
	
	# Define some velocity settings
	set_up_direction(Vector3.UP)
	set_floor_stop_on_slope_enabled(true)
	set_max_slides(4)
	set_floor_max_angle(PI/3)


func _process(_delta):
	
	skeleton.position = -get_root_pos()
	
	if iframes_left > 0.0:
		iframes_left -= _delta
	
	# delete the oldest point in respawn_histroy if there are more than ten of them
	if respawn_history.size() > 9:
		respawn_history.remove_at(0)
	
	if position.y <= section.death_height:
		die()
	
	# every frame, loop through all the meshes we 
	# want to change colour apon taking damage/respawn/switching character
	for mesh in meshes_to_modulate:
		# set their flash colour to the current flash_value,
		# which is derived from the $Modulation AnimationPlayer
		mesh.set("instance_shader_parameters/my_color", Vector4(
			flash_value.r, flash_value.g, flash_value.b, flash_value.a))
	
	
	# if we are dead work toward us undeadening
	if dead:
		respawn_left -= _delta
		# if we are ready to respawn then do so
		if respawn_left <= 0:
			respawn()
	else:
		# if we aren't dead then run all the logics process, and the current movement_state's logic
		for logic in $Logic.get_children():
			if logic.has_method("inclusive_process"):
				if logic.online:
					logic.inclusive_process(_delta)
			
			if movement_state == logic.name:
				
				if logic.has_method("exclusive_process"):
					if logic.online:
						logic.exclusive_process(_delta)


func _physics_process(_delta):
	
	# if we aren't dead, on the floor and our tail raycast is colliding...
	# we are checking for respawns
	if not dead:
		if will_respawn:
			if is_on_floor():
				if tail.is_colliding():
					# ...then check that the collision point distance to our position is less than 0.1...
					if is_instance_valid(tail.get_collider()):
						if tail.get_collision_point().distance_to(position) < 0.1:
							# ...and if so check if the ground we are standing on is respawnable...
							#RayCast3D.new().get_collider()
							
							if standing_on("respawnable"):
								
								# ...and if all that is true set respawn point to our position
								# respawn_point is backup respawn position
								respawn_point = position
								
								# append our position to respawn history if respawn history is empty
								if respawn_history.is_empty():
									respawn_point = position
									respawn_history.append(position)
								
								# if the latest respawn_history is far enough away from our position
								# append the position onto the back of respawn_history
								if respawn_history.back().distance_to(position) > 3:
									respawn_point = position
									respawn_history.append(position)
		
		
		# set knock_vel, this is calculating the knockback
		
		# if the length is greater than .01 then lerp the knockback down
		if knock_vel.length() > .01:
			knock_vel.x = lerp(knock_vel.x, 0.0, 0.1*_delta*60)
			knock_vel.z = lerp(knock_vel.z, 0.0, 0.1*_delta*60)
			knock_vel.y = lerp(knock_vel.y, 0.0, 0.1*_delta*60)
		else:
			# if the length is smaller than .01 reset knock_vel
			knock_vel = Vector3()
		
		
		# calculate push velocity, or push_vel for short
		push_vel = Vector3() # reset push_vel
		for pusher in bodys_pushing:
			
			# make sure the pusher isn't dead
			if not pusher.dead:
				# p_pos and s_pos are the Vector2 positions of the character and the pusher
				var p_pos = Vector2(pusher.global_position.x, pusher.global_position.z)
				var s_pos = Vector2(global_position.x, global_position.z)
				
				# this is the difference between them
				var diference = p_pos-s_pos
				
				# this is the difference normalized multiplied by the push_strength
				var vel = diference.normalized()*push_strength
				
				# If we get the diameter of the collision shape then we can get how powerful to make the push
				var diameter = $Pushaway/Col.shape.radius*2
				var strength = abs(diference.length()-diameter)/diameter
				
				# multiply vel by strength
				vel *= strength
				
				# add vel to push_vel
				push_vel += -Vector3(vel.x, 0, vel.y)
		
		
		# Let all the logics have their incluive physics, and one their exclusive physics
		for logic in $Logic.get_children():
			if logic.has_method("inclusive_physics"):
				if logic.online:
					logic.inclusive_physics(_delta)
			
			if movement_state == logic.name:
				if logic.has_method("exclusive_physics"):
					if logic.online:
						logic.exclusive_physics(_delta)
	
	# setup this for the next frame
	prev_pose = get_root_pos()

# Navigation function for NavLinks
var ai_to = Vector3()
var ai_from = Vector3()
var current_link = null
func _on_agent_link_reached(details):
	
	# some variables derived from details
	var link = details.owner # the NavLink node that we are jumping across
	var location = details.link_entry_position # The location of this side of the link
	var location_to = details.link_exit_position # the location of the other side of the link
	
	# Using our function get_logic_for_nav() we find the best logic for this navigation link
	var logic = get_logic_for_nav(details)
	
	# If we find that logic then we set our movement state to that logic
	
	#if movement_state == base_state:
	if logic:
		set_movement_state(logic.logic_name())
		
		# Also we set all our logic variables to the new ones
		ai_to = location_to
		ai_from = location
		current_link = link
	else:
		ai_to = global_position
		ai_from = global_position
		current_link = null


func add_animation(anim_name:String, new_anim:Animation):
	# Add the animation to the generic animation library
	
	if anim.get_animation_library("").has_animation(anim_name):
		anim.get_animation_library("").remove_animation(anim_name)
	
	anim.get_animation_library("").add_animation(anim_name, new_anim)


# A function for setting the material of a particular piece
func set_material(part_name, id, material):
	# Declare a variable with a reference to the part we are changing the material of
	var MESH = skeleton.get_node_or_null(part_name)
	
	if MESH:
		# Set the material based on the id
		MESH.set_surface_override_material(id, material)


func dispose_audio_player():
	var audio_player = $AudioPlayer
	
	audio_player.name = str(self.name, "_DisposedAudio")
	remove_child(audio_player)
	get_parent().add_child(audio_player)
	audio_player.global_position = global_position
	audio_player.disposed = true
	
	
	var new_AudioPlayer = load("res://Scripts/AudioPlayer.tscn").instantiate()
	add_child(new_AudioPlayer)
	
	audio = new_AudioPlayer
	new_AudioPlayer.sound_effects = audio_player.sound_effects
	for logic in get_logics():
		logic.audio_player = new_AudioPlayer
	
	new_AudioPlayer.name = "AudioPlayer"


func standing_on(group):
	
	if !tailcast.is_colliding():
		return false
	
	var collider = tailcast.get_collider(0)
	
	if !is_instance_valid(collider):
		return false
	
	var shape_id = tailcast.get_collider_shape(0) # The shape index in the collider.
	if collider.has_method("shape_find_owner"):
		var owner_id = collider.shape_find_owner(shape_id) # The owner ID in the collider.
		var shape = collider.shape_owner_get_owner(owner_id)
		
		return shape.is_in_group(group)
	
	return false

func set_mesh(mesh):
	print("set mesh")
	rig = mesh
	armature = mesh.get_node("Armature")
	skeleton = mesh.get_node("Armature/Skeleton3D")
	anim = mesh.get_node("AnimationPlayer")

func get_root_pos():
	#var root = $Mesh/Armature/Skeleton3D/ROOT
	var pos = skeleton.get_bone_global_pose_no_override(0).origin
	return pos


func get_root_vel(start, end):
	
	var root_vel = Vector3()
	
	var bone_pos = get_root_pos()-prev_pose
	var anim_progress = anim.current_animation_position/anim.current_animation_length
	
	if anim_progress >= start and anim_progress <= end:
		
		root_vel = bone_pos.rotated(Vector3.UP, rig.rotation.y)
	
	return root_vel


# a function that holds a generic lerping to the facing of mesh_angle_to
func mesh_angle_lerp(delta, weight):
	rig.rotation.y = lerp_angle(rig.rotation.y, mesh_angle_to, weight*delta*60)
	rig.rotation.y -= deg_to_rad(int(rad_to_deg(rig.rotation.y)/360)*360)


# Variables to control how high and far studs fly out when we drop them
var stud_spread = 4
var stud_max_height = 6.0
var stud_min_height = 1.0

func drop_stud(type):
	# Create a new stud
	var stud = ResourceManager.create_scene("Objects/Stud", global_position+Vector3(0, 1, 0), section)
	# Set the type of the stud
	stud.set_type(type)
	
	# Randomize a y velocity value between the min and max stud velocity height
	var rand_vel_up = randf_range(stud_min_height, stud_max_height)
	# Randomize a variable for a direction the stud will
	# fly and normalize it to make it equal in all direcitons
	var rand_vel_top = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	# Multiply the directional velocity by the stud spread
	rand_vel_top = rand_vel_top*stud_spread
	
	# create a final variable combining all the random values
	var final_rand_vel = Vector3(rand_vel_top.x, rand_vel_up, rand_vel_top.y)
	
	# Set the studs velocity to that final variable
	stud.linear_velocity = final_rand_vel

# Variables to control how high and far a heart's velocity will be
var heart_spread = 2.0
var heart_max_height = 3.0
var heart_min_height = 1.5

func drop_heart():
	
	# Create a new heart
	var heart = ResourceManager.create_scene("Objects/Heart", global_position+Vector3(0, 1, 0), section)
	
	# Randomize a value between the min and max height for the heart velocity
	var rand_vel_up = randf_range(heart_min_height, heart_max_height)
	# Randomize a value for the direction the heart's velocity and make it equal in all directions
	var rand_vel_top = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	# Multiply that value by the heart_spread variable
	rand_vel_top = rand_vel_top*heart_spread
	# Create a final variable that combines all the random values
	var final_rand_vel = Vector3(rand_vel_top.x, rand_vel_up, rand_vel_top.y)
	
	# Set the hearts velocity to that final variable
	heart.linear_velocity = final_rand_vel

# This is a variable that stores what the bits are
var bits = []

# A function to spawn the lego bits that a character drops apon death
func drop_bits():
	
	# Create a list of all the bits that were just dropped - so we can add a collision exception later
	var dropped_bits = []
	
	# Loop through all our bits
	for bit_name in bits:
		# Get the bit
		var bit_node = get_node_or_null(bit_name)
		
		# If it exists, run the generate_bit() function to transform the bit_node to have physics
		if bit_node:
			var bit = generate_bit(bit_node)
			
			# Append that bit to the dropped_bits variable
			dropped_bits.append(bit)
			
			# Put the bit on a different collision layer so it doesn't collide with anything except
			# the enviroment
			bit.set_collision_layer_value(1, false)
			bit.set_collision_layer_value(4, true)
			
			# Add the bit to the scene again
			get_parent().add_child(bit)
			
			# randomize rotational and positional velocity
			var rand_torque = Vector3(randf_range(-3, 3), randf_range(-3, 3), randf_range(-3, 3))
			var rand_vel = Vector3(randf_range(-3, 3), randf_range(-3, 3), randf_range(-3, 3))
			
			# apply the rotational and positional velocity, adding our current movement to the positional velocity as well
			bit.apply_torque(rand_torque)
			bit.apply_impulse(rand_vel + (knock_vel) + char_vel + push_vel)
	
	
	# make so the bits don't collide with any other bits
	for bit in dropped_bits:
		for bit2 in dropped_bits:
			bit.add_collision_exception_with(bit2)


func generate_bit(bit):
	# Duplicate the mesh
	var mesh_drop = bit.duplicate()
	# Create a new rigid body
	var rigid = RigidBody3D.new()
	# create a collision node and a collision shape to go with the rigid body
	var col = CollisionShape3D.new()
	var col_shape = BoxShape3D.new()
	
	# Get the AABB of the mesh, the AABB is the bounding box of the mesh
	var aabb = mesh_drop.mesh.get_aabb()
	
	# Set the duplicated mesh's name to "Mesh"
	mesh_drop.name = "Mesh"
	
	# Set the shape of the collision node to the new box collision shape we made
	col.shape = col_shape
	# Set the size of the box collision shape to the size of the bounding box
	col_shape.size = aabb.size
	
	# Set the position of collision to the position of the AABB position
	col.position = aabb.position + aabb.size/2
	
	# Add the mesh and collision node to the rigid body's children
	rigid.add_child(col)
	rigid.add_child(mesh_drop)
	
	# Set position and rotation of the bit
	rigid.position = bit.global_position
	rigid.rotation.y = bit.global_rotation.y
	
	# set the script of the rigid body - this script makes it flash and delete after a while
	rigid.set_script(ResourceManager.load_script("Scripts/VisualDeath"))
	
	# use the RigidBody function setup() to initiate the rigid body
	rigid.setup()
	
	# Set the physics material override to make it bouncy
	rigid.physics_material_override = ResourceManager.load_tres("Materials/BitsPhysicsMaterial")
	
	# reset the mesh_drop's flash_value - otherwise if we die while flashing the colour is carried over
	if mesh_drop.get("instance_shader_parameters/my_color"):
		mesh_drop.set("instance_shader_parameters/my_color", Vector4())
	
	# return the rigid body - NOTE: it's not added to the scene yet
	return rigid


# A variable to store whether or not we are currently dead
var dead = false

func die():
	
	# We only want to die once, so make sure we are currently alive
	if not dead:
		
		# set our health to 0, just in case it wasn't already
		hit_points = 0
		
		# Explode into a million pieces
		drop_bits()
		
		# Reset the animation to IdleLoop
		anim.play("Idleloop")
		
		# Play all the audio and clear the current loops
		audio.play("Death")
		audio.play("FallApart")
		audio.clear_loops()
		
		# Dispose our audio player
		dispose_audio_player()
		
		# Drop a heart based on the random chance of 50%
		var rand_chance = .5
		var no_hearts = 0 # a variable to store how many hearts we drop
		
		# This was a test to have enemies drop multple hearts but it grows rarer and rarer
		randomize()
		if randf_range(0, 1) < rand_chance:
			no_hearts += 1
		
		while no_hearts > 0:
			drop_heart()
			no_hearts -= 1
		
		# If we are not a player (IE an enemy) then delete
		if !will_respawn:
			section.i_am_dead(self)
			
			emit_signal("death")
			
			queue_free()
		else:
			# player death
			
			# set up our respawn timer
			respawn_left = respawn_wait
			# set ourselves to be dead so this script doesn't trigger again
			dead = true
			# Run the freeze function which sets us to not be moving, and without collision
			death_freeze()
			
			emit_signal("death")
			
			# Set our position back to the respawn point. The good thing about this
			# is that we don't need to do anything with the camera targeting.
			position = get_respawn_point()
		
		# Tell all our logics that want to hear that we have just died
		trigger_logics("die")


# A function that compiles all the things that happen when we respawn
func respawn(): # only for players really
	
	# use the un_death_freeze() function to add back collision etc
	un_death_freeze()
	
	# Reset our health to max
	hit_points = max_hit_points
	
	# reset our animation
	anim.play("Idleloop", 0.0)
	###weapon_prefix = ""
	
	# Set our current velocity to nothing
	char_vel = Vector3()
	
	# Play the respawn flash animation (the white flashing one) and queue reset
	modulate_anim.play("FlashAnims/respawn")
	modulate_anim.queue("FlashAnims/RESET")
	
	# Set dead to false so we are able to die again
	dead = false
	
	# Trigger any logics that want to listen that we just respawned
	trigger_logics("revive")


# A function to easily get the point at which we want to respawn
func get_respawn_point():
	# If we can access respawn history do so, and grab the last point
	if respawn_history.size() > 0:
		return respawn_history.back()
	
	# If respawn_history is empty then return respawn_point, which is a backup respawn position
	return respawn_point


# A (in progress) function to determine whether we can be targeted.
# Could be removed in the future
func can_be_targeted():
	# The only current stipulation is that we aren't dead
	if dead:
		return false
	return true


# A function that compiles all the things that happen when we die, including collision and resetting knockback
func death_freeze():
	# It was giving  me errors when I set it to disabled normally, so I'm using call_deferred
	$Col.call_deferred("set", "disabled", true)
	# Reset the knockback
	knock_vel = Vector3()
	
	# Make so the character is no longer visible
	hide()

# A function that compiles some things that happen when we respawn, like collision
func un_death_freeze():
	# Re enable the collision
	$Col.disabled = false
	# Make the character visible
	show()


# Functions to do with movement states/logics

# This is a function that finds the suitable logic for a particular NavLink
func get_logic_for_nav(details):
	
	# Loop through the logics using get_logics()
	for logic in get_logics():
		# Check if the logic has the method nav - if it 
		# doesn't then it isn't for navigation so we skip it
		if logic.has_method("has_nav"):
			# We give the details of the NavLink to the logic, 
			# and the logic decides whether it can be used
			if logic.has_nav(details):
				
				# if it can return it
				return logic
	
	# If there's no way of using the NavLink return null
	# If exceptions to NavLinks are ever added in the future 
	#add here that there is an exception added for this navLink
	return null

# This function returns all our logics
func get_logics():
	return $Logic.get_children()

# This function checks if you have a logic
func has_logic(logic_name):
	var list = get_logics_list()
	
	if list.has(logic_name):
		return true
	
	return false

# This function returns the logic name of all our logics
func get_logics_list():
	var list = []
	for logic in get_logics():
		list.append(logic.logic_name())
	return list

# This can get a movement state based off a name
func get_logic(state):
	return get_node_or_null("Logic/"+state)

# This checks whether a movement state exists - if it doesn't it returns an error
func logic_exists(state):
	if state == null:
		return false
	
	if get_node_or_null("Logic/"+state):
		return true
	print("invalid movement state: "+state)
	return false

# This returns the movement state node
func get_movement_state():
	return get_logic(movement_state)

# This sets the movement state to a new state
func set_movement_state(new_state):
	
	if logic_exists(movement_state):
		if get_logic(movement_state).has_method("uninitiate"):
			get_logic(movement_state).uninitiate()
	
	# first check if the movement state exists
	if logic_exists(new_state):
		## Then check if it is online - NOTE: online is not a used feature yet
		#if get_logic(new_state).online:
			# Set the movement state to this new state
			movement_state = new_state
			# If the movement state has the method initiate(), initiate the movement state
			if get_logic(new_state).has_method("initiate"):
				get_logic(new_state).initiate()


func take_damage(damage:f.Damage):
	
	assert(damage.iframes is float)
	
	# make sure we can actually take damage
	if not is_invincible():
		
		for logic in $Logic.get_children():
			# if a logic has the function inclusive damage we run that
			if logic.has_method("inclusive_damage"):
				logic.inclusive_damage(damage)
		
		# we need to check if we get overwritten by a logic
		var overwritten = false
		for logic in $Logic.get_children():
			
			# If our current logic have exclusive damage then we run that - and also 
			# override the damage we should take
			if movement_state == logic.name:
				if logic.has_method("exclusive_damage"):
					logic.exclusive_damage(damage)
					overwritten = true
		
		# if we didn't overwrite it then we run generic damage
		if overwritten == false:
			generic_damage(damage.amount, damage.iframes)


# a function that runs the damage flash values and takes off health
func generic_damage(amount, iframes=0.2):
	# If the damage taken was more than nothing (negative values would be adding health, and
	# we don't want to red flash for that)
	if amount > 0:
		# Play the flash animation and then queue reset
		modulate_anim.stop()
		modulate_anim.play("FlashAnims/Flash")
		iframes_left = iframes
		modulate_anim.queue("FlashAnims/RESET")
	
	# Change our healt by the amount of damage, just negative
	change_health(-amount)


func generic_knockback(amount):
	# We can only take knockback if we are alive
	if not dead:
		knock_vel += amount

# A function to add knockback
func take_knockback(amount, _who_from=null):
	
	# if a logic has the function inclusive knockback we run that
	for logic in $Logic.get_children():
		if logic.has_method("inclusive_knockback"):
			logic.inclusive_knockback(amount, _who_from)
	
	# we need to check if we get overwritten by a logic
	var overwritten = false
	for logic in $Logic.get_children():
		
		# If our current logic have exclusive knockback then we run that - and also 
		# override the knockback we should take
		if movement_state == logic.name:
			if logic.has_method("exclusive_knockback"):
				logic.exclusive_knockback(amount, _who_from)
				overwritten = true
	
	# if we didn't overwrite it then we run generic knockback
	if overwritten == false:
		generic_knockback(amount)


# A function for changing health
func change_health(amount):
	# needs to be a global health if character is controlled
	hit_points += amount
	
	# If we run out of health then we die
	if hit_points <= 0:
		
		die()
	else:
		# If we don't die and the amount is less than zero than we play the hurt sound effect
		if amount < 0:
			$AudioPlayer.play("Hurt")
	
	# If we have more health than we should we cap our health to the max health
	if hit_points > max_hit_points:
		hit_points = max_hit_points


# This is an unused variable for auto icons
var current_auto_icon = null

# function to check if we are currently invincible
func is_invincible():
	if dead:
		return true
	
	if iframes_left > 0.0:
		return true
	
	if modulate_anim.current_animation == "FlashAnims/respawn":
		return true
	
	return false


# A function that will trigger a function in any logic that cares to listen
# This is used for events that you want to pass along to a logic, ie Death or Respawning
func trigger_logics(function_name, variables=[]):
	# Loop through the logics using the get_logics() method
	for logic in get_logics():
		# Check if that logic has the method
		if logic.has_method(function_name):
			# If it does then call it
			logic.call(function_name, variables)


var velocity_compute_obstacle = Vector3()
func velocity_computed(safe_velocity:Vector3):
	velocity_compute_obstacle = safe_velocity


var last_location = Vector3()
var next_location = Vector3()
func get_ai_direction(delta):
	var direction = Vector2()
	
	if nav_agent.is_target_reachable() and not nav_agent.is_target_reached():
		
		if not next_location == nav_agent.get_next_path_position():
			last_location = next_location
		
		next_location = nav_agent.get_next_path_position()
		
		direction = f.to_vec2(global_position).direction_to(f.to_vec2(next_location))
		#DebugDraw3D.draw_arrow(position, position+Vector3(direction.x, 0, direction.y), Color.RED)
		#DebugDraw3D.draw_arrow(position, position+Vector3(direction.x, 0, direction.y))
	
	var dodge_left:Vector3 = velocity_compute_obstacle.rotated(Vector3(0, 1, 0), PI/2)
	var dodge_right:Vector3 = velocity_compute_obstacle.rotated(Vector3(0, 1, 0), -PI/2)
	
	var dodge = dodge_left
	var dir_n = Vector3(direction.x, 0, direction.y).normalized()
	
	if dodge_right.normalized().dot(dir_n) > 0:
		dodge = dodge_right
	
	if velocity_compute_obstacle.normalized().dot(dir_n) > 0:
		dodge = dir_n
	
	var movement = (direction + f.to_vec2(dodge)).normalized()
	
	var global_pos2 = f.to_vec2(global_position)
	var target_pos2 = f.to_vec2(next_location)
	var amount_moved_each_frame = 1
	var dist_to_target = (global_pos2.distance_to(target_pos2)/delta)/amount_moved_each_frame
	
	#DebugDraw2D.set_text("Distance To Target", dist_to_target)
	
	if dist_to_target <= 1:
		movement *= dist_to_target
	
	return Vector3(movement.x, 0, movement.y)


# These variables are to do with tagging
var tag_range = 2 # The distance from a character we must at least be in order to tag them
var tag_cone = 1.6 # How many radians our FOV for tagging is
func find_tag():
	
	# first create a list that will contain all the valid peeps
	var in_cone = []
	
	# loop through all the characters
	for taggable in get_tree().get_nodes_in_group("Taggable"):
		
		# A variable that defines whether our current iteration's character can be tagged
		var can_be_tagged = false
		
		# A character can only be tagged if it isn't dead, if it's a player, and if it isn't ourselves
		if not taggable.dead:
			if taggable.player:
				if taggable != self:
					can_be_tagged = true
		
		# if the character can be tagged we move on to see if the character is
		# a. the right distance, and b. in our tagging FOV
		if can_be_tagged:
			
			# the global positions of the current character and the candidate for the taggable character
			var target_pos2 = taggable.global_position
			var self_pos2 = global_position
			
			# the angle toward the taggable character
			var rot_dir = Basis.looking_at(target_pos2-self_pos2, Vector3.UP).get_euler().y
			
			# how different that angle is to our facing angle
			var rot_to = f.angle_to_angle(mesh_angle_to, rot_dir)
			
			# Now we check if that angle is within our "FOV"
			if abs(rot_to) <= tag_cone:
				# If so append it into the in_cone variable
				in_cone.append(taggable)
	
	# loop through all the taggables in the cone
	for taggable in in_cone:
		# make sure the distance to the taggable is within the tag range
		if taggable.global_position.distance_to(global_position) <= tag_range:
			
			# TODO: Add a desirability function here
			
			# return the taggable character
			return taggable
	
	# If nothing else was returned then return nothing
	return null

# A function to reset the modulation of our character
func reset_modulation():
	# Remove all the meshes from meshes_to_modulate
	meshes_to_modulate.clear()
	
	# Loop through all the MeshInstances under the Skeleton3D and set their overlay material to be the flash shader
	# and append them to meshes_to_modulate
	for mesh in skeleton.get_children():
		if mesh is MeshInstance3D:
			var flash_overlay_details = ResourceManager.MaterialLoadDetails.new()
			flash_overlay_details.base_material = "flash overlay"
			
			mesh.material_overlay = ResourceManager.load_material(flash_overlay_details)
			meshes_to_modulate.append(mesh)


# A function to add a logic based off a path, a config, and some vars
func add_logic(logic_path, config={}, switched_vars=[]):
	# Create a new Node for the logic
	var logic_node = Node3D.new()
	# Load the script
	var logic_script = ResourceManager.load_script(logic_path)
	
	# Set the node's script to be the loaded script
	logic_node.set_script(logic_script)
	logic_node.establish_connections(self)
	# Set the name of the logic_node to the logic's name
	logic_node.name = logic_node.logic_name()
	
	# If there is a var that was switched, give it to the logic_node if it wants it
	if switched_vars.has(logic_node.logic_name()):
		if logic_node.has_method("set_switched_var"):
			logic_node.set_switched_var(switched_vars.get(logic_node.logic_name()))
	
	# loop through all the configurations
	for config_name in config.keys():
		# config is name of variable in the logic node
		
		# Figure out whether the variable we are looking for exists within the logic node
		if config_name in logic_node:
			
			# Getting the default variable is currently unused - might remove
			
			# Get the default of the logic node
			var default = logic_node.get(config_name)
			# Record what the default was within the logic node
			logic_node.defaults[config_name] = default
			
			# get the updated variable
			var updated = config.get(config_name)
			
			# Set the variable in the logic node to the updated
			logic_node.set(config_name, f.get_var_from_str(updated))
	
	# Add the logic to the character
	var LogicParent = get_node("Logic")
	LogicParent.add_child(logic_node)
	


# This function attaches a model based on a couple arguments
# TODO: add a config so that we can do custom positions
func attach_model(model_path : ResourceManager.LoadDir, model_file : String, attach_no, bone, materials):
	
	# Create a BoneAttachment3D and a mesh
	var attacher = BoneAttachment3D.new()
	var node = MeshInstance3D.new()
	# Load the mesh
	var mesh = ResourceManager.load_obj(model_path, model_file)
	
	# put the nodes together and attach it to the right bone
	skeleton.add_child(attacher)
	attacher.add_child(node)
	attacher.bone_idx = bone
	
	# Set the right name
	attacher.name = "MODELATTACHED_"+str(attach_no)
	
	# Set the mesh node's mesh, and it's name to Mesh
	node.mesh = null
	node.mesh = mesh
	node.name = "Mesh"
	
	# Append it to bits (so that we drop it when we die)
	bits.append("Mesh/Armature/Skeleton3D/"+attacher.name+"/Mesh")
	
	# Loop through the materials and set the material on the mesh
	for matte_no in materials.keys():
		var details = ResourceManager.MaterialLoadDetails.new()
		
		node.set_surface_override_material(int(matte_no), ResourceManager.load_material(details))###Materials.get_matte(materials.get(matte_no), origin_mod))
	
	# Give it the flash material as an overlay
	var flash_overlay_details = ResourceManager.MaterialLoadDetails.new()
	flash_overlay_details.base_material = "flash overlay"
	
	node.material_overlay = ResourceManager.load_material(flash_overlay_details)
	
	# Make so it will change colour when flash_value is changed
	meshes_to_modulate.append(node)


func attach_softbody(model_path, model_file, attach_no, bone, materials, indices, offsets):
	
	# Create a BoneAttachment3D and a mesh
	var attacher = BoneAttachment3D.new()
	var node = SoftBody3D.new()
	# Load the mesh
	var mesh = ResourceManager.load_obj(ResourceManager.ResLoadDir.new(), model_file)#"res://TEMP/testcloak.obj")
	
	# put the nodes together and attach it to the right bone
	skeleton.add_child(attacher)
	attacher.bone_idx = bone
	#get_node("Mesh/Armature/Skeleton3D").add_child(node)
	
	# Set the right name
	attacher.name = "MODELATTACHED_"+str(attach_no)
	
	# Set the mesh node's mesh, and it's name to Mesh
	#node.global_position = attacher.global_position
	
	#attacher.force_update_transform()
	node.set_mesh(mesh)
	#node.name = "SoftBody"
	
	node.set_collision_mask_value(2, true)
	node.set_collision_layer_value(1, false)
	
	#$Mesh/Armature.hide()
	
	for idx in range(indices.size()):
		var pos_array = offsets[idx]
		var pos = Vector3(pos_array[0], pos_array[1], pos_array[2])
		
		node.set_point_pinned(indices[idx], true, NodePath("../Armature/Skeleton3D/"+attacher.name))
		
		node.set("attachments/"+str(idx)+"/offset", pos)
	
	node.linear_stiffness = 0.82
	node.damping_coefficient = 0.07
	node.drag_coefficient = 0.14
	
	node.top_level = true
	rig.add_child(node)
	
	var bone_transform = skeleton.get_bone_global_pose(bone)
	node.position = bone_transform.origin + position
	node.rotation = bone_transform.basis.get_euler() + rig.rotation + Vector3(0, PI, 0)
	node.add_collision_exception_with(self)
	
	# Append it to bits (so that we drop it when we die)
	#bits.append("Mesh/Armature/Skeleton3D/"+attacher.name+"/Mesh")
	
	# Loop through the materials and set the material on the mesh
	for matte_no in materials.keys():
		var details = ResourceManager.MaterialLoadDetails.new()
		
		node.set_surface_override_material(int(matte_no), ResourceManager.load_material(details))###Materials.get_matte(materials.get(matte_no), origin_mod))
	
	
	var flash_overlay_details = ResourceManager.MaterialLoadDetails.new()
	flash_overlay_details.base_material = "flash overlay"
	
	node.material_overlay = ResourceManager.load_material(flash_overlay_details)
	
	# Make so it will change colour when flash_value is changed
	meshes_to_modulate.append(node)

func get_armature_bits():
	var mesh_bits = []
	for mesh in skeleton.get_children():
		if mesh is MeshInstance3D:
			if mesh.visible:
				mesh_bits.append(self.get_path_to(mesh))
	
	return mesh_bits

func anim_started(anim_name):
	trigger_logics("anim_started", [anim_name])

# This function is called when a body enters our personal space
# It adds the body to a pushing list if it meets a couple criteria
func _on_pushaway_body_entered(body):
	if body.is_in_group("Pushaway"):
		if not body == self:
			bodys_pushing.append(body)


# This function is called when a body leaves our personal space (Phew!)
# It is used in this case to remove that body from the pushing list
func _on_pushaway_body_exited(body):
	if bodys_pushing.has(body):
		bodys_pushing.erase(body)
