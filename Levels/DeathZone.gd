extends Area3D


func _ready():
	connect("body_entered", _on_body_entered)
	set_collision_mask_value(2, true)
	set_collision_layer_value(2, true)

func _on_body_entered(body):
	if body.is_in_group("Character"):
		if !body.dead:
			body.die()
