extends Node
class_name CharacterController

var controlling : Character
#var team

@warning_ignore("unused_signal")
signal controlling_changed(new_controlling)

@warning_ignore("unused_parameter")
func trigger_action(logic):# : Logic):
	pass

func press_button(button : String):
	if controlling and not controlling.dead:
		for logic in controlling.logics.values():
			if logic.player_input(button):
				return

func set_input_vector(vector : Vector2):
	if controlling:
		if !controlling.dead:
			controlling.input_vector = vector
		else:
			controlling.input_vector = Vector2()
