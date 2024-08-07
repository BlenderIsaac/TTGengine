extends RigidBody3D

var collected = false
var collected_player_number = -1
var type = "Silver"
var infinite = false

var stud_data = {
	"Blue" : ["3e76fb", true],
	"Purple" : ["7339ff", true],
}

var emitting = false


func _ready():
	
	# When it spawns in we set the animation to the type the stud is
	$Sprite.animation = type
	
	$Sprite.frame = randi_range(0, 31)
	
	$PickupDelay.wait_time += randf_range(-.2, .2)
	$PickupDelay.start()
	
	if not infinite:
		$AnimationPlayer.play("die")


func set_type(t):
	var f = $Sprite.frame
	type = t
	$Sprite.animation = t
	$Sprite.frame = f


func _on_area_body_entered(body):
	if collected == false:
		if body.is_in_group("Character"):
			if body.player and not body.AI:
				collect(body)


func collect(character):
	if ["Blue", "Purple", "Pink"].has(type):
		character.audio.play("BlueCoinCollect")
	else:
		character.audio.play("CoinCollect")
	
	collected_player_number = character.player_number
	collected = true


func _process(_delta):
	if stud_data.has(type):
		get_node("BlueStudGlow").emitting = stud_data.get(type)[1]
		get_node("BlueStudGlow").color = stud_data.get(type)[0]
	else:
		get_node("BlueStudGlow").emitting = false
	
	# check if we have been collected
	if collected == true:
		
		if infinite:
			Levels.i_am_dead(self)
		
		# stop the animation
		$AnimationPlayer.stop()
		
		# create a connection to the coin visual
		var sprite = $Sprite
		
		# make so the sprite can be seen when behind things
		sprite.no_depth_test = true
		# get the pos of the sprite position
		var pos = sprite.global_position
		
		# just in case the stud is currently transparent make so the stud is opaque
		sprite.modulate = "ffffffff"
		
		# get the current camera
		var cam = get_tree().get_first_node_in_group("GAMECAM")
		# remove the sprite from ourselves
		remove_child(sprite)
		# get the OnUI node child and add the sprite as a child of OnUI
		cam.get_node("OnUI").add_child(sprite)
		# set the sprites position to the position we recorded (just in case it changed)
		sprite.global_position = pos
		
		# get the value of the stud
		var value = f.stud_value.get(type)
		# get the hud and add the money in memory
		#get_tree().get_first_node_in_group("LEVELROOT").add_money(collected_player_number, value)
		
		# set all the metadata that the camera needs to know in order to animate the Sprite3D
		sprite.set_meta("PickupPos", pos-cam.global_position)
		sprite.set_meta("Value", value)
		sprite.set_meta("CharacterNumber", collected_player_number)
		sprite.set_meta("Type", type)
		
		# kill this rigid body
		queue_free()


func _on_animation_player_animation_finished(_anim_name):
	if collected == false:
		queue_free()


func _on_pickup_delay_timeout():
	$PickupRange/AreaCol.shape.radius = 1.5
	$PickupRange/AreaCol.disabled = false
