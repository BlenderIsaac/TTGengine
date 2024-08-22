extends CharacterBody3D

# decides whether or not we are being controlled
@export var AI = false

# Some references
@onready var anim = $Mesh/AnimationPlayer
@onready var nav_agent = $Agent
@onready var modulate_anim = $Modulation
@onready var audio = $AudioPlayer

# player variables
@export var player = false
@export var player_number = -1
@export var control_type = "keyboard"
@export var controller_number = 0

@export var base_state = ""

# variable scaling
@export var var_scale = 4.1

# flash value that character meshes borrows from
@export var flash_value = Vector4()
var meshes_to_modulate = []

var collision_scene = "CharacterCollision.tscn"

var current_rig = "NoRig.tscn"
var subrig = null

var char_spawn = false
var char_spawn_index = 0

var origin_mod

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

# the keys pressed that control us
var keys = {
	'Up' : 'W',
	'Down' : 'S',
	'Left' : 'A',
	'Right' : 'D',
	'Special': 'H',
	'Jump' : 'G',
	'Fight' : 'F',
	'Tag' : 'T',
	'ChangeLeft' : 'R',
	'ChangeRight' : 'Y',
}

# Our current binded controller buttons
var controller_buttons = {
	'Special' : 1,
	'Jump' : 0,
	'Fight' : 2,
	'Tag' : 3,
	'ChangeLeft' : 9,
	'ChangeRight' : 10,
}

# variables to do with respawn wait
var respawn_left = 3.0
var respawn_wait = 3.0

# the other characters pushing on us
var bodys_pushing = []
var push_strength = 20

# our movement state
# Probably change variable name
var movement_state

# the character we are currently
var current_path = "" #TODO: Find a better way than using this
var current_filename = ""

# our current velocity, move direction, knockback velocity, and pushed velocity
var char_vel = Vector3()
var push_vel = Vector3()
var knock_vel = Vector3()

# respawn variable
var respawn_point = Vector3()

# aim_pos - where projectiles aim
var aim_pos = Vector3(0, 0.9, 0)

# health variables
var max_hit_points = 4.0
var hit_points = 4.0

# the lerp angles for mesh turning
var mesh_angle_to = 0.0

# These things make so the functions key_just_pressed and key_just_unpressed work
var keys_pressed_last_frame = []
var buttons_pressed_last_frame = []

var PHYSkeys_pressed_last_frame = []
var PHYSbuttons_pressed_last_frame = []

# These are the keys that can be used with key_just_pressed and key_just_unpressed
var keys_pressed_checking = ["Fight", "Jump", "Pause", "ChangeLeft", "ChangeRight", "Tag", "Special"]

# This is the history of where we can respawn
var respawn_history = []

# This is the weapon we currently are using
var weapon_prefix = ""

# These are some variables to do with AI distance - TODO: should be within an AI logic instead
var AI_desired_distance = 4
var AI_max_distance = 6

# Test target variable
var target = null

# if we have just been tagged
var just_tagged = false

# if we have just been dropped in
var just_dropped = false

# This function is called when this character is first added to the scene
func _ready():
	
	# Define some velocity settings
	set_up_direction(Vector3.UP)
	set_floor_stop_on_slope_enabled(true)
	set_max_slides(4)
	set_floor_max_angle(PI/3)
	
	# set the keys according to settings.gd
	setup_keys()
	
	# Update the health Hud
	if player:
		update_HUD()
		if AI:
			hit_points = max_hit_points
		
		update_camera_target()
	
	# reset our movement_state to the base movement state
	reset_movement_state()


func _process(_delta):
	
	#Engine.time_scale = 1.0
	#$Label3D.text = movement_state#anim.current_animation
	
	# delete the oldest point in respawn_histroy if there are more than ten of them
	if respawn_history.size() > 9:
		respawn_history.reverse()
		respawn_history.resize(10)
		respawn_history.reverse()
	
	var level = get_tree().get_first_node_in_group("LEVELROOT")
	if level:
		if position.y <= level.death_height:
			die()
	
	# every frame, loop through all the meshes we 
	# want to change colour apon taking damage/respawn/switching character
	for mesh in meshes_to_modulate:
		# set their flash colour to the current flash_value,
		# which is derived from the $Modulation AnimationPlayer
		mesh.set("instance_shader_parameters/my_color", flash_value)
	
	# Tagging and Switching code
	# first make sure we are a player and currently being controlled
	if player:
		if not AI:
			
			# declare some variables for the outcome
			var change = false # whether the player has decided to change their character
			var reverse = false # whether the change is backwards or not
			
			# set these variables based off whether we press ChangeLeft or ChangeRight
			if key_just_pressed("ChangeLeft"):
				change = true
				reverse = true # if we change left set reverse to true
			if key_just_pressed("ChangeRight"):
				change = true
			
			# check if our current logic doesn't want us to change
			
			if get_movement_state().has_method("can_switch"):
				if get_movement_state().can_switch() == false:
					change = false
			
			# later add a check here to see if the level is in freeplay
			
			#var char_can_change = false
			#
			#if Levels.level_state.Mode == "Freeplay":
				#char_can_change = true
			
			# if the player has decided to change then do so
			if change == true and Levels.level_state.Mode == "Freeplay":
				
				# This is a temporary bit of code that gets all the files in the mods/character folder
				# Once freeplay is added this needs to be changed to an internal list of current freeplay
				# characters
				#var _chars = DirAccess.get_files_at(SETTINGS.mod_path+"/"+origin_mod+"/characters/chars")
				
				var chars = Levels.player_team.duplicate()
				
				# If reverse is true, flip the _chars 
				if reverse:
					chars.reverse()
				
				# Declare some variables to do with finding the character that is next
				var found = false # whether we have been found within the dir yet
				var new_char_file = null # The file path to the new character
				var new_char_mod = null
				
				# loop through all the character paths
				for char_data in chars:
					
					var char_file = char_data.Path
					var char_mod = char_data.Mod
					
					# if we have found ourselves within the dir last iteration,
					# that means that this iteration the next character is this one
					if found:
						# set new_char to the current iterated character path and break the loop
						new_char_file = char_file
						new_char_mod = char_mod
						break
					else:
						# Just to make sure we switch to something,
						# set this new_char to be this character as a backup
						if new_char_file == null:
							new_char_file = char_file
							new_char_mod = char_mod
						
						# if the char_path plus the name of the charactor is the same as our
						# current character filename, set found to true.
						# Next round the iteration will read that found is true and set the next character
						# to be the next character we possess.
						if SETTINGS.mod_path+"/"+char_mod+"/characters/chars/"+char_file == current_path:
							found = true
				
				# Play the character switch sound effect
				$AudioPlayer.play("CharacterSwitch")
				
				# Restart the switch particles and play them again
				$SwitchParticles.restart()
				$SwitchParticles.emitting = true
				
				# use the change character function to switch into the new character
				change_character_to_file(new_char_file, new_char_mod)
				
				# Stop the modulation AnimationPlayer and play DropIn
				# DropIn is also used when a character... drops in.
				get_node("Modulation").stop()
				get_node("Modulation").play("DropIn")
				
				var Parent = get_hud()
				Parent.get_node("Icon/NameAnim").stop()
				Parent.get_node("Icon/NameAnim").play("DropIn")
			
			
			var can_tag = true
			if get_movement_state().has_method("can_tag"):
				if get_movement_state().can_tag() == false:
					can_tag = false
			
			# If we have pressed Tag, use the find_tag() function
			# The reason we aren't using the key_just_pressed() function
			# is so that if you are slightly out of range of a character it keeps checking
			# until you are in range.
			# To prevent switching rapidly back and forth the just_tagged variable exists,
			# which is set to true after successfully tagging and blocks anymore tags from
			# taking place.
			if key_press("Tag") and can_tag:
				if not dead:
					var tag = find_tag()
					
					# If the tag exists and we haven't just_tagged someone then tag that character
					if tag != null and just_tagged == false:
						$AudioPlayer.play("CharacterTag")
						tag_character(tag)
			else:
				# If we have stopped pressing the tag key reset just_tagged
				just_tagged = false
	
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
	
	
	# make sure this is at the bottom of the _process(delta) function.
	for key_checked in keys_pressed_checking:
		
		# KEYBOARD
		var has_key = keys_pressed_last_frame.has(key_checked)
		
		if key_press(key_checked, "keyboard"):
			if not has_key:
				keys_pressed_last_frame.append(key_checked)
		else:
			if has_key:
				keys_pressed_last_frame.erase(key_checked)
		
		# CONTROLLER
		var has_button = buttons_pressed_last_frame.has(key_checked)
		
		if key_press(key_checked, "controller"):
			if not has_button:
				buttons_pressed_last_frame.append(key_checked)
		else:
			if has_button:
				buttons_pressed_last_frame.erase(key_checked)



func _physics_process(_delta):
	
	# if we aren't dead, on the floor and our tail raycast is colliding...
	if not dead:
		if is_on_floor():
			if $Tail.is_colliding():
				# ...then check that the collision point distance to our position is less than 0.1...
				if is_instance_valid($Tail.get_collider()):
					if $Tail.get_collision_point().distance_to(position) < 0.1:
						# ...and if so check if the ground we are standing on is respawnable...
						if $Tail.get_collider().is_in_group("respawnable"):
							
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
	
	# The physics version of keys_just_pressed/unpressed
	for key_checked in keys_pressed_checking:
		
		# KEYBOARD
		var has_key = PHYSkeys_pressed_last_frame.has(key_checked)
		
		if key_press(key_checked, "keyboard"):
			if not has_key:
				PHYSkeys_pressed_last_frame.append(key_checked)
		else:
			if has_key:
				PHYSkeys_pressed_last_frame.erase(key_checked)
		
		# CONTROLLER
		var has_button = PHYSbuttons_pressed_last_frame.has(key_checked)
		
		if key_press(key_checked, "controller"):
			if not has_button:
				PHYSbuttons_pressed_last_frame.append(key_checked)
		else:
			if has_button:
				PHYSbuttons_pressed_last_frame.erase(key_checked)
	
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
	
	if movement_state == base_state:
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
	
	if $Mesh/AnimationPlayer.get_animation_library("").has_animation(anim_name):
		$Mesh/AnimationPlayer.get_animation_library("").remove_animation(anim_name)
	
	$Mesh/AnimationPlayer.get_animation_library("").add_animation(anim_name, new_anim)


# A function for setting the material of a particular piece
func set_material(part_name, id, material):
	# Declare a variable with a reference to the part we are changing the material of
	var MESH = get_node_or_null("Mesh/Armature/Skeleton3D/"+part_name)
	
	if MESH:
		# Set the material based on the id
		MESH.set_surface_override_material(id, material)


# A function that should be called anytime the keys are changed
func setup_keys():
	# Retrieve the settings from SETTINGS and set your keys and controller_buttons
	keys = SETTINGS.player_keys[player_number]
	controller_buttons = SETTINGS.player_controller_buttons[player_number]
	
	# Update the HUD
	update_HUD()


func dispose_audio_player():
	var AudioPlayer = $AudioPlayer
	
	AudioPlayer.name = str(self.name, "_DisposedAudio")
	remove_child(AudioPlayer)
	get_parent().add_child(AudioPlayer)
	AudioPlayer.global_position = global_position
	AudioPlayer.disposed = true
	
	
	var new_AudioPlayer = load("res://Scripts/AudioPlayer.tscn").instantiate()
	add_child(new_AudioPlayer)
	
	audio = new_AudioPlayer
	new_AudioPlayer.sound_effects = AudioPlayer.sound_effects
	for logic in get_logics():
		logic.audio_player = new_AudioPlayer
	
	new_AudioPlayer.name = "AudioPlayer"


# A function to find the camera and add yourself to it's target list
func update_camera_target():
	# Get the camera
	var cam = get_tree().get_first_node_in_group("GAMECAM")
	
	var invalid_cam = true
	var index = 1
	while invalid_cam:
		if cam.is_queued_for_deletion():
			cam = get_tree().get_nodes_in_group("GAMECAM")[index]
			index += 1
		else:
			invalid_cam = false
	
	# Figure out whether we're currently on the list
	var currently_targeted = cam.targets.has(self)
	
	# If we are on the list and we are AI then stop the camera targeting us
	if currently_targeted:
		if AI:
			cam.targets.erase(self)
	# If we are not on the target list and we are a player then add us to the list
	else:
		if not AI:
			cam.targets.append(self)


func warn(type, from_list):
	if AI:
		trigger_logics(str("warning_"+type), from_list)

func get_root_pos():
	#var root = $Mesh/Armature/Skeleton3D/ROOT
	var pos = $"Mesh/Armature/Skeleton3D".get_bone_global_pose_no_override(0).origin
	return pos

func get_root_vel(start, end):
	
	var root_vel = Vector3()
	
	var bone_pos = get_root_pos()-prev_pose
	var anim_progress = anim.current_animation_position/anim.current_animation_length
	
	if anim_progress >= start and anim_progress <= end:
		
		root_vel = bone_pos.rotated(Vector3.UP, $"Mesh".rotation.y)
	
	return root_vel


func controller_direction_pressed(key):
	var joy_vector = get_joy_vector()
	
	match key:
		"Up":
			if joy_vector.z == -1:
				return true
		"Down":
			if joy_vector.z == 1:
				return true
		"Left":
			if joy_vector.x == -1:
				return true
		"Right":
			if joy_vector.x == 1:
				return true
	
	return false


# A function to get the direction we are supposed to be moving based on key/controller inputs
func get_move_dir():
	# A variable to hold the movement direction we are going to return
	var new_move_dir = Vector3()
	
	# If we are keyboard player check through all the keys and add values to new_move_dir
	if control_type == "keyboard":
		if key_press("Up"):
			new_move_dir.z -= 1
		if key_press("Down"):
			new_move_dir.z += 1
		if key_press("Left"):
			new_move_dir.x -= 1
		if key_press("Right"):
			new_move_dir.x += 1
		
		# Normalize new_move_dir to make sure we aren't moving faster than 1.0 in any direction
		new_move_dir = new_move_dir.normalized()
	# If we are a controller player then get the position of the joystick
	elif control_type == "controller":
		
		new_move_dir = get_joy_vector()
		
		# Add a deadzone of .05
		if new_move_dir.length() <= .05:
			new_move_dir = Vector3()
		
		# limit the length of our travel to 1.0 to make sure we don't move faster than that
		new_move_dir = new_move_dir.limit_length(1.0)
	
	# Rotate the move_dir to align with our camera
	new_move_dir = new_move_dir.rotated(Vector3.UP, get_viewport().get_camera_3d().rotation.y)
	
	# return new_move_dir
	return new_move_dir

# a function that holds a generic lerping to the facing of mesh_angle_to
func mesh_angle_lerp(delta, weight):
	
	get_node("Mesh").rotation.y = lerp_angle(get_node("Mesh").rotation.y, mesh_angle_to, weight*delta*60)
	get_node("Mesh").rotation.y -= deg_to_rad(int(rad_to_deg(get_node("Mesh").rotation.y)/360)*360)


# Variables to control how high and far studs fly out when we drop them
var stud_spread = 4
var stud_max_height = 6.0
var stud_min_height = 1.0

func drop_stud(type):
	# Get a reference to the stud in memory
	var sTUD_pICKUP = l.get_load("res://Objects/Stud.tscn")
	
	# Create a new stud
	var stud = sTUD_pICKUP.instantiate()
	# Add the stud to the scene
	get_parent().add_child(stud)
	# Set the type of the stud
	stud.set_type(type)
	# Set the global position of the stud to our position, just a little higher
	stud.global_position = global_position+Vector3(0, 1, 0)
	
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
	# Get a reference for the heart in memory
	var hEART_pICKUP = l.get_load("res://Objects/HeartPickup.tscn")
	
	# Create a new heart
	var heart = hEART_pICKUP.instantiate()
	# Add the heart to the scene
	get_parent().add_child(heart)
	# Position the heart at our position just a little higher
	heart.global_position = global_position+Vector3(0, 1, 0)
	
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
	rigid.set_script(l.get_load("res://Scripts/VisualDeath.gd"))
	
	# use the RigidBody function setup() to initiate the rigid body
	rigid.setup()
	
	# Set the physics material override to make it bouncy
	rigid.physics_material_override = l.get_load("res://Materials/BitsPhysicsMaterial.tres")
	
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
		if not player:
			if !Levels.char_spawn_dead.has(Levels.level_state.Section):
				Levels.char_spawn_dead[Levels.level_state.Section] = []
			
			Levels.char_spawn_dead[Levels.level_state.Section].append(char_spawn_index)
			
			queue_free()
		else:
			# player death
			
			# set up our respawn timer
			respawn_left = respawn_wait
			# set ourselves to be dead so this script doesn't trigger again
			dead = true
			# Run the freeze function which sets us to not be moving, and without collision
			death_freeze()
			
			# Reset our movement state to base one
			reset_movement_state()
			
			# Drop studs
			var level = get_tree().get_first_node_in_group("LEVELROOT")
			var current_money = level.get_money(player_number)
			var max_drop = 2000 # The amount of studs we will at max drop... in OG TCS it makes you drop half when you are below 2000 right?
			
			if current_money/2 < max_drop:
				max_drop = snappedi(current_money/2, 10)
			
			var drop_types = f.get_stud_values_for_count(max_drop)
			#var has_dropped = 0
			#
			## loop until we have dropped enough money
			#while has_dropped < max_drop and not current_money == 0:
				## Variables for the type of stud we are dropping and the value of that stud
				#var type_drop = null
				#var amount_drop = 0
				#
				## Match the amount of money we have to the types of studs
				#if current_money >= 100000 and max_drop > 100000:
					#type_drop = "Pink"
					#amount_drop = 100000
				#elif current_money >= 10000 and max_drop > 10000: # remove when pink gets added
					#type_drop = "Purple"
					#amount_drop = 10000
				#elif current_money >= 1000 and max_drop > 1000:
					#type_drop = "Blue"
					#amount_drop = 1000
				#elif current_money >= 100 and max_drop > 100:
					#type_drop = "Gold"
					#amount_drop = 100
				#elif current_money >= 10 and max_drop >= 10:
					#type_drop = "Silver"
					#amount_drop = 10
				#
				## If we have found a stud to drop
				#if not type_drop == null:
					## add the amount we just dropped to the sum of what we have dropped
					#has_dropped += amount_drop
					## drop the stud, based on what type the stud is
					#drop_stud(type_drop)
			
			var drop = 0
			for stud in drop_types:
				drop += f.stud_value[stud]
				drop_stud(stud)
			
			level.add_money(player_number, -drop)
			
			# Use our update money function which formats the current stud value nicely
			update_money()
			
			# set our health to 0, just in case it wasn't already
			hit_points = 0
			
			# Update the HUD
			update_HUD()
			
			# Set our position back to the respawn point. The good thing about this
			# is that we don't need to do anything with the camera targeting. The
			# bad thing is the death sound effects play at the place we respawn - 
			# not the place we die.
			position = get_respawn_point()
		
		# Tell all our logics that want to hear that we have just died
		trigger_logics("die")


# A function that compiles all the things that happen when we respawn
func respawn(): # only for players really
	
	# use the un_death_freeze() function to add back collision etc
	un_death_freeze()
	
	# Reset our health to max
	hit_points = max_hit_points
	
	# Update the HUD
	update_HUD()
	
	# reset our animation
	anim.play("Idleloop", 0)
	weapon_prefix = ""
	
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
	# Freeze the base movement state - It has a couple things it wants to do.
	# Maybe change this to trigger logics later? Maybe other logics want to do things like that.
	get_base_movement_state().freeze()
	# Make so the character is no longer visible
	hide()

# A function that compiles some things that happen when we respawn, like collision
func un_death_freeze():
	# Re enable the collision
	$Col.disabled = false
	# Make the character visible
	show()


# Functions to do with movement states/logics

# This function gets our base movement state
func get_base_movement_state():
	return get_logic(get_base_movement_state_name())

# This gets the name of our base movement state
func get_base_movement_state_name():
	return base_state

# This checks whether we are currently in our base movement state
func is_in_base_movement_state():
	if get_base_movement_state_name() == movement_state:
		return true
	return false

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
	if get_node_or_null("Logic/"+state):
		return true
	print("invalid movement state: "+state)
	return false

# This returns the movement state node
func get_movement_state():
	return get_logic(movement_state)

# This sets the movement state to a new state
func set_movement_state(new_state):
	
	# first check if the movement state exists
	if logic_exists(new_state):
		# Then check if it is online - NOTE: online is not a used feature yet
		if get_logic(new_state).online:
			# Set the movement state to this new state
			movement_state = new_state
			# If the movement state has the method initiate(), initiate the movement state
			if get_logic(new_state).has_method("initiate"):
				get_logic(new_state).initiate()

# This function sets us back to our base movement state
func reset_movement_state():
	
	set_movement_state(get_base_movement_state_name())


func get_stud(amount, frame, type):
	gain_money(amount, type, frame)
func gain_money(amount, type, frame):
	get_tree().get_first_node_in_group("LEVELROOT").add_money(player_number, amount)
	get_hud().get_node("InGame/MoneyParent/Anim").play("Juice")
	get_hud().get_node("InGame/MoneyParent/CoinHUD").animation = type
	get_hud().get_node("InGame/MoneyParent/CoinHUD").frame = frame
	# add something here to change colour of thing
	
	update_money()

# This function updates the money in the HUD and formats it with ,
func update_money():
	if get_hud():
		get_hud().get_node("InGame/MoneyParent/Money").text = format_num(str(get_tree().get_first_node_in_group("LEVELROOT").get_money(player_number)))

# This returns the HUD for the player
func get_hud():
	
	# Get the name of the hud
	
	var parent_name = str("Player", player_number, "HUD")
	
	# Get the parent of our hud and return it
	var Parent = Interface.get_node_or_null("Icons/"+parent_name+"/Control")
	return Parent

# This was ripped from online
# from https://ask.godotengine.org/18559/how-to-add-commas-to-an-integer-or-float-in-gdscript
func format_num(num):
	var i : int = num.length() - 3
	while i > 0:
		num = num.insert(i, ",")
		i = i - 3
	return num

# TODO: All the health functions need to be changed to go on a global "Player Num Health"
# But that only takes effect when the character is being controlled
func take_damage(amount, _who_from=null):
	
	# make sure we can actually take damage
	if not is_invincible():
		
		for logic in $Logic.get_children():
			# if a logic has the function inclusive damage we run that
			if logic.has_method("inclusive_damage"):
				logic.inclusive_damage(amount, _who_from)
		
		# we need to check if we get overwritten by a logic
		var overwritten = false
		for logic in $Logic.get_children():
			
			# If our current logic have exclusive damage then we run that - and also 
			# override the damage we should take
			if movement_state == logic.name:
				if logic.has_method("exclusive_damage"):
					logic.exclusive_damage(amount, _who_from)
					overwritten = true
		
		# if we didn't overwrite it then we run generic damage
		if overwritten == false:
			generic_damage(amount)


# a function that runs the damage flash values and takes off health
func generic_damage(amount):
	# If the damage taken was more than nothing (negative values would be adding health, and
	# we don't want to red flash for that)
	if amount > 0:
		# Play the flash animation and then queue reset
		modulate_anim.play("FlashAnims/Flash")
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
	
	# If we are being controlled we will update the HUD
	if not AI:
		update_HUD()

# This is an unused variable for auto icons
var current_auto_icon = null

# This is a function that finds and updates our current HUD
func update_HUD():
	
	# get the pause keys for controllers and keyboards
	var pause_key = keys.get("Pause")
	#var cont_start = controller_buttons.get("Pause")
	
	# get the HUD using the get_hud() function
	var Parent = get_hud()
	
	# if we have found our HUD and we exist as a player
	if Parent != null and player_number != -1:
		
		Parent.get_node("Icon/Name").text = char_name
		
		# If we have an icon then set it as the sprite of the Control/Head on our HUD.
		# If not, don't.
		if icon != null:
			Parent.get_node("Icon/Head").texture = icon
		else:
			Parent.get_node("Icon/Head").texture = null
		
		# Get references to the Heart and DropIn nodes of the HUD
		var HeartParent = Parent.get_node("InGame/HeartParent")
		var DropInPrompt = Parent.get_node("InGame/DropInPrompt")
		
		# First set all the modulation of the hearts to transparent
		HeartParent.get_node("Heart1").modulate = "ffffff50"
		HeartParent.get_node("Heart2").modulate = "ffffff50"
		HeartParent.get_node("Heart3").modulate = "ffffff50"
		HeartParent.get_node("Heart4").modulate = "ffffff50"
		
		# Then set all the hearts we want to be opaque based on hit_points
		if hit_points > 0:
			HeartParent.get_node("Heart1").modulate = "ffffffff"
		if hit_points > 1:
			HeartParent.get_node("Heart2").modulate = "ffffffff"
		if hit_points > 2:
			HeartParent.get_node("Heart3").modulate = "ffffffff"
		if hit_points > 3:
			HeartParent.get_node("Heart4").modulate = "ffffffff"
		
		# Set the drop in prompt text to the correct key
		DropInPrompt.text = str("Press (",pause_key,") or\n(Start) to start")
		
		# If we are AI now then we want to make the HUD transparent, hide the hearts, and show the drop in prompt
		if AI:
			DropInPrompt.show()
			HeartParent.hide()
			Parent.modulate.a = .5
		# If we now being controlled then we do the opposite
		else:
			DropInPrompt.hide()
			HeartParent.show()
			Parent.modulate.a = 1


# function to check if we are currently invincible
func is_invincible():
	if dead or ["FlashAnims/Flash", "FlashAnims/respawn"].has(modulate_anim.current_animation):
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


# AI function that gets the current position of our target
# We don't do this every frame to save on lag
func _on_target_update():
	
	# If we are an AI and we have a target
	if AI and target: 
		
		# Get the position of the target, the y position snapped within 0.01 - why I do this I don't remember
		var tar_pos = Vector3(target.x, snapped(target.y, 0.01), target.z)
		# Store the current position we think that the target is at
		var prev_tar_pos = nav_agent.target_position
		
		# Set the position where we are going to be the position of our target
		nav_agent.target_position = (tar_pos)
		
		# Check if the target is currently reachable, if not, set the target 
		if not nav_agent.is_target_reachable():
			nav_agent.target_position = prev_tar_pos
	
	# ask the current general ai logic something maybe


# a function that simply returns the distance to the current target
# It's so simple that I might remove it in future
func get_distance_to_target():
	return target.distance_to(global_position)


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


# A function that tags a character
# The number of particles that spawn when tagging
var tag_part_num = 3
# The spread of the particles
var tag_particle_spread = Vector3(.2, .5, .2)
func tag_character(tag):
	
	# Spawn all the tag particles
	
	# loop for the number of particles
	for i in tag_part_num:
		# Create a new particle
		var tag_particle = l.get_load("res://Objects/tag_particle.tscn").instantiate()
		
		# Set the target of the tag particle
		tag_particle.target = tag
		
		# Generate random coordinates for the particle to be placed at, based off tag_particle_spread
		var tag_x = randf_range(-tag_particle_spread.x, tag_particle_spread.x)
		var tag_y = randf_range(-tag_particle_spread.y, tag_particle_spread.y)
		var tag_z = randf_range(-tag_particle_spread.z, tag_particle_spread.z)
		
		# get the colour of the particle from SETTINGS
		var colour = SETTINGS.player_colours.get(str(player_number))
		
		# Set the material override to the tag particle material - TODO: globalize later into a global particle material
		tag_particle.get_node("Trail").material_override = MATERIALS.get_tag_part_material(colour)
		# Set the position to our position added to the aiming position and the random pos
		tag_particle.position = aim_pos+position+Vector3(tag_x, tag_y, tag_z)
		# Tell the tag_particle where it originated - so it can go to that same position on the tagged character
		# This is so they don't group up while following
		tag_particle.randomization = Vector3(tag_x, tag_y, tag_z)
		
		# Add the tag particle to the scene
		get_parent().add_child(tag_particle)
	
	# Store the current player numbers of us and the tagged character
	var tag_new_number = player_number
	var our_new_number = tag.player_number
	
	var tag_new_control = control_type
	var our_new_control = tag.control_type
	
	var tag_cont_num = controller_number
	var our_cont_num = tag.controller_number
	
	# Flip the numbers
	tag.player_number = tag_new_number
	player_number = our_new_number
	
	# Set the tagged character's just_tagged to true (so they don't loop tagging)
	tag.just_tagged = true
	
	# If the character we are going to is not controlled then toggle AI on both of us
	if tag.AI:
		tag.AI = false
		AI = true
	# If we are both controlled characters then don't do anything but set our just_tagged characters
	else:
		just_tagged = true
	
	# Setup the keys for both of us
	tag.setup_keys()
	setup_keys()
	
	# update the HUD
	tag.update_money()
	update_money()
	
	# Update the camera target on both of us
	tag.update_camera_target()
	update_camera_target()
	
	# update the controller number
	tag.controller_number = tag_cont_num
	controller_number = our_cont_num
	
	# switch the control types
	tag.control_type = tag_new_control
	control_type = our_new_control
	
	# Stop the anim on the tag's Modulation and play DropIn to show the player that they have switched
	tag.get_node("Modulation").stop()
	tag.get_node("Modulation").play("DropIn")
	
	var Parent = tag.get_hud()
	Parent.get_node("Icon/NameAnim").stop()
	Parent.get_node("Icon/NameAnim").play("DropIn")
	
	# set our target position
	ai_to = position
	target = position
	
	# TODO - make so that if we are both controlled it does all the particles and makes both of us play DropIn


# A function to reset the modulation of our character
func reset_modulation():
	# Remove all the meshes from meshes_to_modulate
	meshes_to_modulate.clear()
	
	# Loop through all the MeshInstances under the Skeleton3D and set their overlay material to be the flash shader
	# and append them to meshes_to_modulate
	for mesh in $Mesh/Armature/Skeleton3D.get_children():
		if mesh is MeshInstance3D:
			mesh.material_overlay = MATERIALS.FlashOverlay
			meshes_to_modulate.append(mesh)

# This function gets data from a character file
func get_character_file_data(c_path):
	# Read the file and get it as a dictionary
	var file = FileAccess.open(c_path, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	
	# Close the file (important)
	file.close()
	
	return data

# This function takes a character file and runs it through the inherit chain
func complete_character_file_data(data, mod):
	
	if data.has("Inherits"):
		var char_path = SETTINGS.mod_path+"/"+mod+"/characters/chars/"+data.Inherits
		
		var inherited_data = complete_character_file_data(get_character_file_data(char_path), mod)
		
		for key in data.keys():
			var value = data.get(key)
			
			if key.begins_with("#"):
				
				if typeof(value) == typeof({}):
					
					# dictionary editing
					for sub_key in value.keys():
						inherited_data[key.lstrip("#")][sub_key] = value.get(sub_key)
				elif typeof(value) == typeof([]):
					for element in value:
						var replace_instead = false
						
						if key == "#Logics":
							var idx = 0
							
							for d in inherited_data.Logics:
								if d.cLogicsPath == element.cLogicsPath:
									replace_instead = true
									inherited_data[key.lstrip("#")][idx] = element
								
								idx += 1
						elif key == "#Animations":
							var idx = 0
							
							for d in inherited_data.Animations:
								if d.Name == element.Name:
									replace_instead = true
									inherited_data[key.lstrip("#")][idx] = element
								
								idx += 1
						
						
						if not replace_instead:
							inherited_data[key.lstrip("#")].append(element)
				
			else:
				inherited_data[key] = value
		
		return inherited_data
	else:
		return data

# This function loads a character from a file and makes us that character
func change_character_to_file(c_file, mod):
	
	var char_path = SETTINGS.mod_path+"/"+mod+"/characters/chars/"+c_file
	
	# Load the data
	var data = complete_character_file_data(get_character_file_data(char_path), mod)
	
	# change us to that data
	change_character(data, char_path, mod)
	
	current_filename = c_file

# This function sets us to a particular character based off data
func change_character(data, c_path, mod): # TODO: We don't need c_path here once we remove current_character_filename
	
	current_filename = ""
	
	$Agent.navigation_layers = 0
	
	origin_mod = mod
	
	# Clear all current audio loops
	$AudioPlayer.clear_loops()
	
	# change name
	if data.has("Name"):
		char_name = data.Name
	
	# add sounds
	$AudioPlayer.clear()
	if data.has("Sounds"):
		
		var all_sounds = initial_sounds.duplicate()
		
		for sound in data.Sounds.keys():
			var value = data.Sounds.get(sound)
			
			all_sounds[sound] = value
		
		for key in all_sounds:
			var value = all_sounds.get(key)
			
			for path_type in value.keys():
				var sound_list = value.get(path_type)
				
				for sound in sound_list:
					$AudioPlayer.add_sound(f.get_data_path({path_type : sound}, origin_mod), key, origin_mod)
		
		#for title in data.Sounds.keys():
			#print(title, data.Sounds.get(title))
			## issue here
			#$AudioPlayer.add_sound(data.Sounds.get(title), title, origin_mod)
			## add config and randomization of sounds
		#for sound in initial_sounds.keys():
			#$AudioPlayer.add_sound(initial_sounds.get(sound), sound, origin_mod)
	
	# Setup the Icon using the MATERIALS autoload
	if data.has("Icon"):
		icon = MATERIALS.load_texture(SETTINGS.mod_path+"/"+origin_mod+"/characters/icons/"+data.Icon)
	else:
		icon = null
	
	# If the data specifies a health for an AI then set our AI_Health to it
	if data.has("AI_Health"):
		if AI:
			hit_points = data.AI_Health
	
	if data.has("Collision"):
		collision_scene = data.Collision
	else:
		collision_scene = "CharacterCollision.tscn"
	
	var current_col = get_node_or_null("Col")
	var current_push_col = get_node_or_null("Pushaway/Col")
	var col_load = l.get_load(SETTINGS.mod_path+"/"+origin_mod+"/characters/collisions/"+collision_scene)
	
	if current_col:
		#current_col.name = "ColDelete"
		current_col.free()
	if current_push_col:
		#current_col.name = "ColPushDelete"
		current_push_col.free()
	
	var new_col = col_load.instantiate()
	var new_push_col = col_load.instantiate()
	
	add_child(new_col)
	new_col.name = "Col"
	
	$Pushaway.add_child(new_push_col)
	new_push_col.name = "Col"
	
	# delete current rig
	var m = get_node_or_null("Mesh")
	var m_rot = Vector3()
	if m:
		m_rot = m.rotation
		
		m.name = "DeletingMesh"
		m.queue_free()
	
	# create rig/subrig
	var rig_name = "GenRig.tscn"
	var subrig_name = null
	
	if data.has("Rig"):
		rig_name = data.Rig
	
	if data.has("SubRig"):
		subrig_name = data.SubRig
	
	current_rig = rig_name
	subrig = subrig_name
	
	if subrig_name != null:
		rig_name = subrig_name
	
	
	
	var rig_path = SETTINGS.mod_path+"/"+origin_mod+"/characters/rigs/"+rig_name
	#var rig# = 
	var rig_instance# = l.get_load(rig_path).instantiate()
	
	if subrig_name.ends_with(".glb"):
		rig_instance = f.generate_gltf(rig_path)
		var rooot = BoneAttachment3D.new()
		m_rot.x = -PI/2
		rooot.bone_idx = 0
		rooot.name = "ROOT"
		rooot.override_pose = true
		rig_instance.get_node("Armature/Skeleton3D").add_child(rooot)
	else:
		m_rot.x = 0
		rig_instance = l.get_load(rig_path).instantiate()
	
	add_child(rig_instance)
	rig_instance.name = "Mesh"
	rig_instance.rotation = m_rot
	
	
	# replace parts
	if data.has("ReplaceParts"):
		for part_name in data.ReplaceParts:
			var new_part_filename = data.ReplaceParts.get(part_name)
			
			var parts_path = SETTINGS.mod_path+"/"+origin_mod+"/characters/rigs/replacers/"+new_part_filename
			var new_part = l.get_load(parts_path).instantiate()
			
			var skeleton = rig_instance.get_node("Armature/Skeleton3D")
			var current_part = skeleton.get_node(part_name)
			
			current_part.name = "DelMe"
			current_part.free()
			
			new_part.name = part_name
			skeleton.add_child(new_part)
			new_part.skeleton = NodePath("..")
	
	anim = $Mesh/AnimationPlayer
	anim.playback_process_mode = 0
	
	# hide particular bits
	if data.has("HideParts"):
		for part in data.HideParts:
			get_node("Mesh/Armature/Skeleton3D/"+part).hide()
	
	# Get the meshes and set bit to it
	bits = get_armature_bits()
	
	# Reset the modulation and create a new list of meshes_to_modulate
	reset_modulation()
	
	# generate models
	if data.has("Models"):
		var attach_no = 0
		for model in data.Models:
			if model.Type == "Model":
				
				var p = f.get_data_path(model, mod)
				attach_model(p, attach_no, int(model.Bone), model.Materials)
				
				attach_no += 1
	
	# add materials
	for part_matt_name in data.Materials.keys():
		var part_matte_data = data.Materials.get(part_matt_name)
		for matte_id in part_matte_data:
			set_material(part_matt_name, int(matte_id), MATERIALS.get_matte(part_matte_data.get(matte_id), origin_mod))
	
	# get the parent of the logics
	var LogicParent = get_node("Logic")
	
	# create the base logic
	base_state = data.BaseState
	
	# I don't know if logic_switched_vars is necessary
	var logic_switched_vars = {}
	# delete all current logics
	for logic in LogicParent.get_children():
		if logic.has_method("get_switched_var"):
			logic_switched_vars[logic.logic_name()] = logic.get_switched_var()
		
		if logic.has_method("reset"):
			logic.reset()
		
		logic.free()
	
	# loop through all the logics and create them
	for logic in data.Logics:
		var config = {}
		if logic.has("Config"):
			config = logic.Config
		
		var data_path = f.get_data_path(logic, mod)
		
		if SETTINGS.use_internal_logics == "true":
			data_path = "res://Logic/" + logic.cLogicsPath
		
		add_logic(data_path, config, logic_switched_vars)
	
	# store current animation
	var anim_player = $Mesh/AnimationPlayer
	
	# Remove a library if one exists and add a new blank one.
	if anim_player.has_animation_library(""):
		anim_player.remove_animation_library("")
	anim_player.add_animation_library("", AnimationLibrary.new())
	
	# add the animations
	if data.has("Animations"):
		for anim_name in data.Animations:
			var new_anim = l.get_load(f.get_data_path(anim_name, mod))
			
			add_animation(anim_name.Name, new_anim)
	
	get_base_movement_state().C = self
	anim_player.play(get_base_movement_state().get_switch_anim(), 0.0)
	anim_player.seek(0.0, true)
	
	# show which character we are
	current_path = c_path
	
	# remove our weapon
	weapon_prefix = ""
	
	# set the movement state to our base state
	reset_movement_state()
	
	# if we are inside the tree and have access to the hud update it
	if is_inside_tree():
		update_HUD()


# A function to add a logic based off a path, a config, and some vars
func add_logic(logic_path, config={}, logic_switched_vars=[]):
	# Create a new Node for the logic
	var logic_node = Node3D.new()
	# Load the script
	var logic_script = l.get_load(logic_path)
	
	# Set the node's script to be the loaded script
	logic_node.set_script(logic_script)
	# Set the name of the logic_node to the logic's name
	logic_node.name = logic_node.logic_name()
	
	# If there is a var that was switched, give it to the logic_node if it wants it
	if logic_switched_vars.has(logic_node.logic_name()):
		if logic_node.has_method("set_switched_var"):
			logic_node.set_switched_var(logic_switched_vars.get(logic_node.logic_name()))
	
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
			logic_node.set(config_name, l.get_var_from_str(updated))
	
	# Add the logic to the character
	var LogicParent = get_node("Logic")
	LogicParent.add_child(logic_node)


# This function attaches a model based on a couple arguments
# TODO: add a config so that we can do custom positions
func attach_model(model_path, attach_no, bone, materials):
	
	# Create a BoneAttachment3D and a mesh
	var attacher = BoneAttachment3D.new()
	var node = MeshInstance3D.new()
	# Load the mesh
	var mesh = o.get_obj(model_path)
	
	# put the nodes together and attach it to the right bone
	get_node("Mesh/Armature/Skeleton3D").add_child(attacher)
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
		node.set_surface_override_material(int(matte_no), MATERIALS.get_matte(materials.get(matte_no), origin_mod))
	
	# Give it the flash material as an overlay
	node.material_overlay = MATERIALS.FlashOverlay
	
	# Make so it will change colour when flash_value is changed
	meshes_to_modulate.append(node)

func get_armature_bits():
	var mesh_bits = []
	for mesh in $Mesh/Armature/Skeleton3D.get_children():
		if mesh is MeshInstance3D:
			if mesh.visible:
				mesh_bits.append(self.get_path_to(mesh))
	
	return mesh_bits

func get_joy_vector():
	var vector_x = Input.get_joy_axis(controller_number, JOY_AXIS_LEFT_X)
	var vector_y = Input.get_joy_axis(controller_number, JOY_AXIS_LEFT_Y)
	
	var joy_vector = Vector3(vector_x, 0, vector_y)
	
	return joy_vector

# Basic function for key being just pressed in the process function
func key_just_pressed(key, override=null):
	var key_currently_pressed = key_press(key, override)
	
	if key_currently_pressed:
		if keys_pressed_last_frame.has(key) and control_type == "keyboard":
			return false
		elif buttons_pressed_last_frame.has(key) and control_type == "controller":
			return false
		else:
			return true
	
	return false

# Basic function for key being just unpressed in the process function
func key_just_unpressed(key, override=null):
	var key_currently_pressed = key_press(key, override)
	
	if not key_currently_pressed:
		if keys_pressed_last_frame.has(key) and control_type == "keyboard":
			return true
		elif buttons_pressed_last_frame.has(key) and control_type == "controller":
			return true
	
	return false

# Basic function to just get when a key is pressed
func key_press(key, override=null):
	
	var local_control_type = control_type
	if override != null:
		local_control_type = override
	
	if local_control_type == "keyboard":
		if Input.is_key_pressed(OS.find_keycode_from_string(keys.get(key))):
			return true
	elif local_control_type == "controller":
		if Input.is_joy_button_pressed(controller_number, controller_buttons.get(key)):
			return true
	
	if SETTINGS.mobile == true:
		for b in get_tree().get_nodes_in_group("AndroidButtons"):
			
			if b.name == key and b.is_pressed():
				return true
	
	return false


# Basic function that checks whether a key was just pressed in the physics process function
func PHYSkey_just_pressed(key, override=null):
	var key_currently_pressed = key_press(key, override)
	
	if key_currently_pressed:
		if PHYSkeys_pressed_last_frame.has(key) and control_type == "keyboard":
			return false
		elif PHYSbuttons_pressed_last_frame.has(key) and control_type == "controller":
			return false
		else:
			return true
	
	return false

# Basic function that checks whether a key was just unpressed in the physics process function
func PHYSkey_just_unpressed(key, override=null):
	var key_currently_pressed = key_press(key, override)
	
	if not key_currently_pressed:
		if PHYSkeys_pressed_last_frame.has(key) and control_type == "keyboard":
			return true
		elif PHYSbuttons_pressed_last_frame.has(key) and control_type == "controller":
			return true
	
	return false


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
