extends Node
class_name CharacterController

var controlling : Character
#var team

@warning_ignore("unused_parameter")
func trigger_action(logic):# : Logic):
	pass

@warning_ignore("unused_parameter")
func press_button(button : String):
	pass

func set_input_vector(vector : Vector2):
	if controlling:
		controlling.input_vector = vector
