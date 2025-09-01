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

var gravity = -6.0

# variable scaling
@export var var_scale := 4.1

# flash value that character meshes borrows from
@export var flash_value := Color(1.0, 1.0, 1.0, 0.0)
var meshes_to_modulate = []
var flash_material : Material

#var char_spawn = false
#var char_spawn_index = 0

var details : ResourceManager.CharacterLoadDetails

# variables for root vel
var prev_pose = Vector3()

# icon storage
var icon = null

# character sounds for audio
var character_sounds = {
	"FallApart" : ["FALLAPART01.WAV", "FALLAPART02.WAV", "FALLAPART03.WAV", "FALLAPART04.WAV"],
	"CharacterSwitch" : ["TOGGLECHAR.WAV"],
	"CharacterTag" : ["SWCHAR.WAV"],
	"HeartCollect" : ["HEART.WAV"],
	"CoinCollect" : ["COIN1.WAV", "COIN2.WAV"],
	"BlueCoinCollect" : ["COINBLUE.WAV"],
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
var current_logic : Logic :
	set(value):
		if current_logic:
			current_logic.exit()
		
		current_logic = value
		current_logic.enter()
	get():
		return current_logic

var logics = {}
var base_logic : Logic

var sounds = {}

var model_attachments = []

var identity
var alignment

var weapons = {}
var current_weapon# : Weapon

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
signal damaged(damage : f.Damage)
signal revive
signal death
@warning_ignore("unused_signal")
signal pre_switch
@warning_ignore("unused_signal")
signal post_switch

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

var sfx_index = 0
func anim_started():
	sfx_index = 0

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
	flash_material.set_shader_parameter("my_color", Vector4(
		flash_value.r,
		flash_value.g,
		flash_value.b,
		flash_value.a
		))
	
	# if we are dead work toward us undeadening
	if dead:
		respawn_left -= _delta
		# if we are ready to respawn then do so
		if respawn_left <= 0:
			respawn()

func _physics_process(delta):
	
	# sound effects
	var animation = get_anim()
	if animation:
		
		if animation.get_meta("has_sfx") == true:
			var sfx_times = animation.get_meta("sfx")
			if sfx_times.size() > sfx_index:
				var next = sfx_times[sfx_index]
				if anim.current_animation_position > next[1]:
					sfx_index += 1
					audio.play(next[0])
	
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
			knock_vel = knock_vel.lerp(Vector3.ZERO, 0.1*delta*60)
		else:
			# if the length is smaller than .01 reset knock_vel
			knock_vel = Vector3.ZERO
		
		
		# calculate push velocity, or push_vel for short
		push_vel = Vector3.ZERO # reset push_vel
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
				var diameter = pushaway_collision.get_child(0).shape.radius*2
				var strength = abs(diference.length()-diameter)/diameter
				
				# multiply vel by strength
				vel *= strength
				
				# add vel to push_vel
				push_vel += -Vector3(vel.x, 0, vel.y)
		
		# gravity
		
		if is_on_floor():
			if char_vel.y < -0.1:
				char_vel.y = -0.1
		else:
			char_vel.y += gravity * delta * var_scale
		
		# Reset movement
		if is_on_ceiling():
			if char_vel.y > 0.0:
				char_vel.y = 0.0
		
		set_velocity(push_vel + knock_vel + char_vel)
		
		move_and_slide()
		mesh_angle_lerp(delta, 0.2)
	
	# setup this for the next frame
	prev_pose = get_root_pos()

func get_anim():
	if anim.current_animation == "":
		return null
	
	return anim.get_animation(anim.current_animation)

# Navigation function for NavLinks
var ai_to = Vector3()
var ai_from = Vector3()
var current_link = null
func _on_agent_link_reached(link_deets):
	
	# some variables derived from details
	var link = link_deets.owner # the NavLink node that we are jumping across
	var location = link_deets.link_entry_position # The location of this side of the link
	var location_to = link_deets.link_exit_position # the location of the other side of the link
	
	# Using our function get_logic_for_nav() we find the best logic for this navigation link
	var logic = get_logic_for_nav(link_deets)
	
	# If we find that logic then we set our movement state to that logic
	
	#if movement_state == base_state:
	if logic:
		current_logic = logic
		
		# Also we set all our logic variables to the new ones
		ai_to = location_to
		ai_from = location
		current_link = link
	else:
		ai_to = global_position
		ai_from = global_position
		current_link = null


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
	rig = mesh
	armature = mesh.get_node("Armature")
	skeleton = mesh.get_node("Armature/Skeleton3D")
	anim = mesh.get_node("AnimationPlayer")
	
	for child in skeleton.get_children():
		if child is MeshInstance3D:
			if child.visible:
				child.material_overlay = flash_material
				meshes_to_modulate.append(child)
				bits.append(child)

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
	for bit_node in bits:
		
		var bit = generate_bit(bit_node)
		
		# Append that bit to the dropped_bits variable
		dropped_bits.append(bit)
		
		# Put the bit on a different collision layer so it doesn't collide with anything except
		# the enviroment
		bit.set_collision_layer_value(1, false)
		#bit.set_collision_mask_value(1, false)
		#bit.set_collision_layer_value(4, true)
		
		# Add the bit to the scene again
		section.add_child(bit)
		
		# randomize rotational and positional velocity
		var rand_torque = Vector3(randf_range(-3, 3), randf_range(-3, 3), randf_range(-3, 3))
		var rand_vel = Vector3(randf_range(-3, 3), randf_range(-3, 3), randf_range(-3, 3))
		
		# apply the rotational and positional velocity, adding our current movement to the positional velocity as well
		bit.apply_torque(rand_torque)
		bit.apply_impulse(rand_vel + (knock_vel) + char_vel + push_vel)


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
	
	emit_signal("revive")


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
func get_logic_for_nav(nav_deets):
	
	# Loop through the logics using get_logics()
	for logic in logics.values():
		# Check if the logic has the method nav - if it 
		# doesn't then it isn't for navigation so we skip it
		if logic.has_method("has_nav"):
			# We give the details of the NavLink to the logic, 
			# and the logic decides whether it can be used
			if logic.has_nav(nav_deets):
				
				# if it can return it
				return logic
	
	# If there's no way of using the NavLink return null
	# If exceptions to NavLinks are ever added in the future 
	#add here that there is an exception added for this navLink
	return null

func take_damage(damage:f.Damage):
	
	assert(damage.iframes is float)
	
	# make sure we can actually take damage
	if not is_invincible():
		
		for logic in logics:
			if logic.consume_damage(damage):
				return
		
		if damage.amount > 0:
			# Play the flash animation and then queue reset
			modulate_anim.stop()
			modulate_anim.play("FlashAnims/Flash")
			iframes_left = damage.iframes
			modulate_anim.queue("FlashAnims/RESET")
		
		# Change our health by the amount of damage, just negative
		change_health(-damage.amount)
		knock_vel += damage.knockback
		
		emit_signal("damaged")


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


func find_opponent(max_angle, max_range, dist_weight = 1, angle_weight = 2, _friend_penalty = 3):
	# add raycast
	
	var possibilities = []
	
	for destroyable in get_tree().get_nodes_in_group("AttackLockOn"):
		
		var can_be_targeted = true
		
		if not destroyable == self and can_be_targeted:
			var target_pos2 = destroyable.global_position
			var self_pos2 = global_position
			var dist = target_pos2.distance_squared_to(self_pos2)
			
			if dist <= max_range * max_range:
				
				var rot_dir = Basis.looking_at(target_pos2-self_pos2, Vector3.UP).get_euler().y
				
				var angle_to = abs(f.angle_to_angle(mesh_angle_to, rot_dir))
				
				if angle_to <= max_angle:
					
					possibilities.append(TargetData.new(destroyable, (angle_to/max_angle), dist/max_range))
	
	
	var most_desirable = null
	for opponent : TargetData in possibilities:
		
		#if opponent.d.is_in_group("Character"):
			#
			## if opponent is in the party
			#if opponent.d.player:
				#desirability *= friend_penalty
		
		if not most_desirable:
			most_desirable = opponent
		else:
			# if there is something to compare to
			var their_des = opponent.get_desirability(angle_weight, dist_weight)
			var our_des = opponent.get_desirability(angle_weight, dist_weight)
			
			if our_des < their_des:
				most_desirable = opponent
	
	return most_desirable


class TargetData:
	var object
	var angle : float
	var distance : float
	var desirability : float
	
	
	func _init(_object, _angle, _distance):
		object = _object
		angle = _angle
		distance = _distance
	
	func get_desirability(angle_weight, distance_weight):
		if not desirability:
			desirability = (distance * distance_weight) + (angle * angle_weight)
		
		return desirability


# function to check if we are currently invincible
func is_invincible():
	if dead:
		return true
	
	if iframes_left > 0.0:
		return true
	
	if modulate_anim.current_animation == "FlashAnims/respawn":
		return true
	
	return false


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


func reset_logic():
	current_logic = base_logic

@warning_ignore("unused_parameter")
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
		var deets = ResourceManager.MaterialLoadDetails.new()
		
		node.set_surface_override_material(int(matte_no), ResourceManager.load_material(deets))###Materials.get_matte(materials.get(matte_no), origin_mod))
	
	
	var flash_overlay_details = ResourceManager.MaterialLoadDetails.new()
	flash_overlay_details.base_material = "flash overlay"
	
	node.material_overlay = ResourceManager.load_material(flash_overlay_details)
	
	# Make so it will change colour when flash_value is changed
	meshes_to_modulate.append(node)


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
