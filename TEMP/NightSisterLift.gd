extends Node3D


var lifted = null

func _ready():
	$Bulb.emitting = true
	$Push.emitting = true

func _process(_delta):
	if lifted and is_instance_valid(lifted):
		if !"dead" in lifted or !lifted.dead:
			
			if lifted.is_in_group("Character") and !lifted.movement_state == "MagicLifted":
				$Push.emitting = false
				$Bulb.emitting = false
				$DeathTimer.start()
			elif "being_ns_lifted" in lifted and lifted.being_ns_lifted == false:
				$Push.emitting = false
				$Bulb.emitting = false
				$DeathTimer.start()
			else:
				if "being_ns_lifted" in lifted:
					position.x = lifted.position.x
					position.z = lifted.position.z
				
				$Push.global_position.y = lifted.position.y
				
				var lifetime = (lifted.position.y-position.y)*0.08
				
				if lifetime <= 0:
					lifetime = 0.01
				
				$Bulb.lifetime = lifetime
		else:
			$Push.emitting = false
			$Bulb.emitting = false
			$DeathTimer.start()
	else:
		$Push.emitting = false
		$Bulb.emitting = false
		$DeathTimer.start()

func _on_death_timer_timeout():
	queue_free()
