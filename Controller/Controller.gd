extends Node
class_name CharacterController

var controlling : Character
#var team

func trigger_action(logic):# : Logic):
	pass

func press_button(button : String):
	pass

func set_input_vector(vector : Vector2):
	if controlling:
		controlling.input_vector = vector
