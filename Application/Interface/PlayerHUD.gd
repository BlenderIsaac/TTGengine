extends Node2D
class_name PlayerHUD

#@export_tool_button("Update Positions") var call : Callable = Callable(self, "update_positions")
@export_enum("LEFT", "RIGHT") var horizontal : String = "LEFT"
@export_enum("UP", "DOWN") var vertical : String = "UP"

var d_i_p_pos = Vector2(58, 30)
var coin_pos = Vector2(74, -13)
var money_text_pos = Vector2(25.02, -17.98)
var heart_pos = Vector2(75.6, 17.6)

var player : Player


func update_positions():
	var x = 1 if horizontal == "LEFT" else -1
	var y = 1 if vertical == "UP" else -1
	
	$DropInPrompt.position = Vector2(d_i_p_pos.x * x, d_i_p_pos.y * y)
	$MoneyParent.position = Vector2(coin_pos.x * x, coin_pos.y * y)
	$MoneyParent/Money.position.x = money_text_pos.x * x
	$HeartParent.position = Vector2(heart_pos.x * x, heart_pos.y * y)
	
	$HeartParent.mltply = x
	$HeartParent.update_heart_visuals()
	
	match horizontal:
		"LEFT":
			
			$DropInPrompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			$MoneyParent/Money.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		"RIGHT":
			$DropInPrompt.position.x -= $DropInPrompt.size.x
			$MoneyParent/Money.position.x -= $MoneyParent/Money.size.x
			
			$DropInPrompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			$MoneyParent/Money.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	
	match vertical:
		"UP":
			pass
		"DOWN":
			$DropInPrompt.position.y -= $DropInPrompt.size.y
