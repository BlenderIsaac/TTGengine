extends RigidBody3D
class_name HeartPickup


# Instead of using an area to detect pickups, it should loop through the characters and see if
# they can pickup the health. Then only check that list. Also make collision exceptions.

var rotate_speed = 5

func _process(delta):
	$Mesh.rotation.y += rotate_speed*delta


func _on_pickup_range_body_entered(body):
	if body is Character:
		if not body.dead:
			body.emit_signal("pickup_collided", self)


func _on_animation_player_animation_finished(_anim_name):
	queue_free()


func _on_timer_timeout():
	$PickupRange/AreaCol.shape.radius = 0.553
	$PickupRange/AreaCol.disabled = false
