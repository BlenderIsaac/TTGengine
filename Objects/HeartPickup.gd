extends RigidBody3D


# Instead of using an are to detect pickups, it should loop through the characters and see if
# they can pickup the health. Then only check that list. Also make collision exceptions.

var rotate_speed = 5

func _process(delta):
	$Mesh.rotation.y += rotate_speed*delta


func _on_pickup_range_body_entered(body):
	if body.is_in_group("Character"): # add vehicles in later?
		if body.player:
			if not body.AI:
				body.audio.play("HeartCollect")
				body.change_health(1)
				queue_free()


func _on_animation_player_animation_finished(_anim_name):
	queue_free()


func _on_timer_timeout():
	$PickupRange/AreaCol.shape.radius = 0.553
	$PickupRange/AreaCol.disabled = false
