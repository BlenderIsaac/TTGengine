extends Node
class_name CharacterController

var game_manager : GameManager

var controlling : Character

var freeplay_char_idx = -1

var audio : AudioPlayer

func _ready():
	audio = AudioPlayer.new()
	audio.universal = true
	add_child(audio)
	
	var dir = ResourceManager.ResLoadDir.new()
	
	var switch_sound = ResourceManager.SoundLoadDetails.new(dir, "Sounds/TOGGLECHAR.WAV")
	audio.set_sound("Switch", [switch_sound])


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

func can_switch():
	if !game_manager.level_manager.current_level:
		return false
	
	if !game_manager.level_manager.current_level.mode in [Level.LevelMode.FREEPLAY, Level.LevelMode.SUPERFREEPLAY]:
		return false
	
	return true

func switch(offset):
	if controlling:
		var team_size = len(game_manager.level_manager.current_level.freeplay_characters_details)
		var next_i = (controlling.freeplay_char_idx + offset) % team_size
		controlling.freeplay_char_idx = next_i
		
		var next_details : ResourceManager.CharacterLoadDetails = game_manager.level_manager.current_level.freeplay_characters_details[next_i]
		
		next_details.gen_to(controlling)
		
		controlling.get_node("SwitchParticles").restart()
		#controlling.get_node("SwitchParticles").emitting = true
		
		audio.play("Switch")
