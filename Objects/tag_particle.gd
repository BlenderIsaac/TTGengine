extends Node3D

var target = null
var speed = 6.0
var randomization = Vector3()

func _process(delta):
	if target:
		
		var difference = (target.aim_pos + target.position + randomization) - position
		
		if difference.length() <= speed*delta:
			target = null
			$Trail.emitting = false
			$Blob.hide()
			
			$DeathTimer.wait_time = $Trail.lifetime
			$DeathTimer.start()
		
		difference = difference.normalized()
		
		position += difference*speed*delta
		
		speed += .1


func _on_death_timer_timeout():
	queue_free()
