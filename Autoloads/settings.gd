extends Node

var mobile = true
var volume_level = -20

func _ready():
	if mobile == false:
		var settings_path = OS.get_executable_path().get_base_dir()+"/TCSR SETTINGS.txt"
		
		if !FileAccess.file_exists(settings_path):
			
			# Create the file
			var _new_file = FileAccess.open(settings_path, FileAccess.WRITE)
			_new_file.store_string(JSON.stringify({"mod_path" : OS.get_executable_path().get_base_dir()+"/mods"}))
		
		var file = FileAccess.open(settings_path, FileAccess.READ)
		
		var text = file.get_as_text()
		
		var json = JSON.parse_string(text)
		
		if json != null:
			
			for setting in json.keys():
				
				set(setting, json.get(setting))
	else:
		mod_path = "res://mods"


func get_logic_base_dir(origin_mod):
	var logics_base_path = mod_path+origin_mod+"/characters/logics/"
	if use_internal_logics == "true":
		logics_base_path = "res://Logic/"
	
	return logics_base_path


var player_keys = [
{ # Player 0 keys
	'Up' : 'W',
	'Down' : 'S',
	'Left' : 'A',
	'Right' : 'D',
	'Special': 'H',
	'Jump' : 'G',
	'Fight' : 'F',
	'Tag' : 'T',
	'ChangeLeft' : 'R',
	'ChangeRight' : 'Y',
	'Pause' : 'Q',
},
{ # Player 1 keys
	'Up' : 'Up',
	'Down' : 'Down',
	'Left' : 'Left',
	'Right' : 'Right',
	'Special': 'L',
	'Jump' : 'K',
	'Fight' : 'J',
	'Tag' : 'I',
	'ChangeLeft' : 'U',
	'ChangeRight' : 'O',
	'Pause' : 'P',
},
#{ # Player 2 keys
	#'Up' : 'Up',
	#'Down' : 'Down',
	#'Left' : 'Left',
	#'Right' : 'Right',
	#'Special': 'L',
	#'Jump' : 'K',
	#'Fight' : 'J',
	#'Tag' : 'I',
	#'ChangeLeft' : 'U',
	#'ChangeRight' : 'O',
	#'Pause' : 'P',
#},
#{ # Player 2 keys
	#'Up' : '1',
	#'Down' : '1',
	#'Left' : '1',
	#'Right' : '1',
	#'Special': '1',
	#'Jump' : '1',
	#'Fight' : '1',
	#'Tag' : '1',
	#'ChangeLeft' : '1',
	#'ChangeRight' : '1',
	#'Pause' : '1',
#}
]

var player_controller_buttons = [
{
	'Up' : JOY_BUTTON_DPAD_UP,
	'Down' : JOY_BUTTON_DPAD_DOWN,
	'Left' : JOY_BUTTON_DPAD_LEFT,
	'Right' : JOY_BUTTON_DPAD_RIGHT,
	'Special' : 1,
	'Jump' : 0,
	'Fight' : 2,
	'Tag' : 3,
	'ChangeLeft' : 9,
	'ChangeRight' : 10,
	'Pause' : JOY_BUTTON_START,
},
{
	'Up' : JOY_BUTTON_DPAD_UP,
	'Down' : JOY_BUTTON_DPAD_DOWN,
	'Left' : JOY_BUTTON_DPAD_LEFT,
	'Right' : JOY_BUTTON_DPAD_RIGHT,
	'Special' : 1,
	'Jump' : 0,
	'Fight' : 2,
	'Tag' : 3,
	'ChangeLeft' : 9,
	'ChangeRight' : 10,
	'Pause' : JOY_BUTTON_START,
},
{
	'Up' : JOY_BUTTON_DPAD_UP,
	'Down' : JOY_BUTTON_DPAD_DOWN,
	'Left' : JOY_BUTTON_DPAD_LEFT,
	'Right' : JOY_BUTTON_DPAD_RIGHT,
	'Special' : 1,
	'Jump' : 0,
	'Fight' : 2,
	'Tag' : 3,
	'ChangeLeft' : 9,
	'ChangeRight' : 10,
	'Pause' : JOY_BUTTON_START,
},
{
	'Up' : JOY_BUTTON_DPAD_UP,
	'Down' : JOY_BUTTON_DPAD_DOWN,
	'Left' : JOY_BUTTON_DPAD_LEFT,
	'Right' : JOY_BUTTON_DPAD_RIGHT,
	'Special' : 1,
	'Jump' : 0,
	'Fight' : 2,
	'Tag' : 3,
	'ChangeLeft' : 9,
	'ChangeRight' : 10,
	'Pause' : JOY_BUTTON_START,
},
]

var player_colours = {
	"0" : "209bff",
	"1" : "82f900",
	"2" : "FEFF37",
	"3" : "FF0000",
}

var spawn_troops = "true"
var use_internal_logics = "true"
var mod_path = ""
