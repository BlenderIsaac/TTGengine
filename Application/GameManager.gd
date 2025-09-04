extends Node
class_name GameManager

var current_mod : String
var current_party : Array
var level_manager : LevelManager
var interface : Interface
var players : Array = []
var keybinds : Array = [KeyboardKeybind.new(), ControllerKeybind.new(), WASDKeyboardKeybind.new()]
var player_ids = []
var devices_taken = []

signal players_changed(new_players)

func _ready():
	print("Starting Game Manager")
	name = "Game Manager"
	
	spawn_level_manager()
	spawn_interface()
	
	interface.load_screen(Interface.MAIN_MENU)

func add_player(keybind : Keybind, device = 0):
	var player = Player.new()
	player.game_manager = self
	
	if keybind.control_type == 0:keybind.taken_by = player
	player.keybind = keybind
	player.number = get_next_player_id()
	player.player_color = interface.get_player_color(player.number)
	player.controller_device = device
	add_child(player)
	players.append(player)
	
	if level_manager.current_level:
		assign_party(level_manager.current_level.party)
	else:
		emit_signal("players_changed", players)

func get_next_player_id():
	
	for i in len(player_ids):
		if player_ids[i] == false:
			player_ids[i] = true
			return i
	
	player_ids.append(true)
	return len(player_ids) - 1

func assign_party(new_party):
	var unclaimed = new_party.duplicate()
	
	for player in players:
		if player.controlling:
			unclaimed.erase(player.controlling)
	
	for player in players:
		if !player.controlling:
			if !unclaimed.is_empty():
				player.set_control_to(unclaimed.pop_front())
	
	emit_signal("players_changed", players)

func delete_player(player):
	if player.controlling:
		player.reset_control_of(player.controlling)
	
	match player.keybind.control_type:
		0:
			player.keybind.taken_by = null
		1:
			devices_taken.erase(player.controller_device)
	
	player_ids[player.number] = false
	
	players.erase(player)
	player.queue_free()
	emit_signal("players_changed", players)

func spawn_level_manager():
	level_manager = LevelManager.new()
	level_manager.game_manager = self
	add_child(level_manager)

func spawn_interface():
	interface = Interface.new()
	interface.connect("choose_level", level_manager.load_level)
	interface.connect("choose_mod", set_mod)
	interface.game_manager = self
	add_child(interface)

func set_mod(new_mod):
	current_mod = new_mod
	ResourceManager.current_mod = current_mod

func _input(event):
	
	if event is InputEventKey and event.pressed and not event.echo:
		for keybind : Keybind in keybinds:
			
			if keybind.control_type == 0 and keybind.pause_key == event.physical_keycode:
				
				if keybind.taken_by:
					delete_player(keybind.taken_by)
					continue
				
				if keybind.pause_key == event.physical_keycode:
					add_player(keybind)
					return
	elif event is InputEventJoypadButton and event.pressed:
		if event.device in devices_taken:
			for player in players:
				if player.keybind.control_type == 1:
					if player.controller_device == event.device:
						if player.keybind.pause_key == event.button_index:
							delete_player(player)
							return
			return
		
		for keybind : Keybind in keybinds:
			if keybind.control_type == 1:
				if keybind.pause_key == event.button_index:
					add_player(keybind, event.device)
					devices_taken.append(event.device)
					return

class Keybind:
	var control_type = -1
	var pause_key
	
	var action_key
	var jump_key
	var special_key
	
	var tag_key
	
	var switch_left_key
	var switch_right_key

class KeyboardKeybind extends Keybind:
	var up_key = KEY_UP
	var down_key = KEY_DOWN
	var left_key = KEY_LEFT
	var right_key = KEY_RIGHT
	
	var taken_by = null
	
	func _init():
		control_type = 0
		pause_key = KEY_P
		
		action_key = KEY_J
		jump_key = KEY_K
		special_key = KEY_L
		
		tag_key = KEY_I
		
		switch_left_key = KEY_U
		switch_right_key = KEY_O

class WASDKeyboardKeybind extends KeyboardKeybind:
	
	func _init():
		control_type = 0
		pause_key = KEY_Q
		
		up_key = KEY_W
		down_key = KEY_S
		left_key = KEY_A
		right_key = KEY_D
		
		action_key = KEY_F
		jump_key = KEY_G
		special_key = KEY_H
		
		tag_key = KEY_T
		
		switch_left_key = KEY_R
		switch_right_key = KEY_Y

class ControllerKeybind extends Keybind:
	func _init():
		control_type = 1
		pause_key = JOY_BUTTON_START
		
		action_key = JOY_BUTTON_X
		jump_key = JOY_BUTTON_A
		special_key = JOY_BUTTON_B
		
		tag_key = JOY_BUTTON_Y
		
		switch_left_key = JOY_BUTTON_LEFT_SHOULDER
		switch_right_key = JOY_BUTTON_RIGHT_SHOULDER
