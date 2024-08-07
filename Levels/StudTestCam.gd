extends "res://Levels/FreeLookCam.gd"


# All test code
func child_tick(_delta):
	for child in $OnUI.get_children():
		if child.is_in_group("StudVisual"):
			
			var player_HUD = get_node(str("%Player", child.get_meta("CharacterNumber"), "HUD"))
			
			var coin_to_pos = project_position(player_HUD.get_node("Control/MoneyParent/CoinHUD").global_position, 5)
			var coin_speed = .3
			
			var pos_from = child.get_meta("PickupPos")+global_position
			var pos_to = coin_to_pos
			
			var difference = pos_to - child.global_position
			var total = pos_to - pos_from
			
			var progress = (difference.length()/(total.length()+.0001)-1)*-1
			
			var speed = pow(progress, 1.01)+.01
			var max_speed = 2
			
			if speed > max_speed:
				speed = max_speed
			
			child.global_position += difference.normalized()*speed
			
			var distance_to_go = coin_to_pos.distance_to(child.global_position)
			if distance_to_go < speed or progress >= 1:
				var value = child.get_meta("Value", 10)
				
				get_parent().get_stud(value, child.frame)
				child.queue_free()
