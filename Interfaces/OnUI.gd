extends Node3D

func _process(delta):
	for child in get_children():
		if child.is_in_group("StudVisual"):
			
			var player_number = child.get_meta("CharacterNumber")
			
			var parent_name = str("Player", player_number, "HUD")
			
			# Get the parent of our hud and return it
			var Parent = Interface.get_node("Icons/"+parent_name+"/Control")
			
			var coin_to_pos = get_parent().project_position(Parent.get_node("InGame/MoneyParent/CoinHUD").global_position, 5)
			
			var pos_from = child.get_meta("PickupPos")+get_parent().global_position
			var pos_to = coin_to_pos
			
			var difference = pos_to - child.global_position
			var total = pos_to - pos_from
			
			var progress = (difference.length()/(total.length()+.0001)-1)*-1
			
			var speed = ((abs(progress)*1.005)+.01)*delta*60
			var max_speed = 0.4
			
			if speed > max_speed:
				speed = max_speed
			
			child.global_position += difference.normalized()*speed
			
			var distance_to_go = coin_to_pos.distance_to(child.global_position)
			if distance_to_go < speed or progress >= 1:
				var value = child.get_meta("Value", 10)
				var type = child.get_meta("Type")
				
				# find the player. Do this more efficiently later
				var player = null
				
				for character in get_tree().get_nodes_in_group("Character"):
					if character.player and character.player_number == player_number:
						player = character
						break
				
				player.get_stud(value, child.frame, type)
				
				child.queue_free()

