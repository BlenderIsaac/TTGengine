extends Node
class_name Interface

var current_screen = null
var game_manager : GameManager

enum {
	MAIN_MENU
}

var basic_hud_offset := Vector2(134, 87)
var player_huds := {}
var player_colors = [
	Color.BLUE,
	Color.LAWN_GREEN,
	Color.RED,
	Color.YELLOW,
	Color.DEEP_PINK,
	Color.BLACK,
	Color.REBECCA_PURPLE,
	Color.WHITE,
]
var player_backs = [
	"Blue",
	"Green",
	"Red",
	"Yellow",
	"Pink",
	"Black",
	"Purple",
	"White",
	]

var screens := []

signal choose_level(load_command : LevelManager.LevelLoadCommand)
signal choose_mod(mod)

func _ready():
	create_screens()
	
	get_window().connect("size_changed", update_hud_positions)
	game_manager.connect("players_changed", update_players)
	game_manager.level_manager.connect("level_loading", reset_screen)
	
	name = "Interface"
	
	spawn_hud(0)
	spawn_hud(1)

func create_screens():
	## main menu
	var main_menu = create_screen(MainMenuScreen)
	main_menu.connect("choose_level", func(load_command): emit_signal("choose_level", load_command))
	main_menu.connect("choose_mod", func(mod): emit_signal("choose_mod", mod))

func create_screen(screen_class):
	var screen = screen_class.new()
	screen.hide()
	add_child(screen)
	screens.append(screen)
	
	return screen

func update_players(players):
	for player : Player in players:
		var in_huds = player.number in player_huds
		
		if !in_huds:
			add_hud_for(player)
		else:
			player_huds[player.number].set_player(player)

func add_hud_for(player):
	var hud = spawn_hud(player.number)
	hud.set_player(player)

func spawn_hud(number):
	var hud = ResourceManager.create_scene("Application/Interface/PlayerHUD", Vector2(), self)
	hud.number = number
	player_huds[number] = hud
	
	update_hud_position(hud)
	update_hud_visual(hud)
	return hud

func update_hud_visual(hud):
	var dir = ResourceManager.ResLoadDir.new()
	var back = get_player_icon_back(hud.number)
	var texture_details = ResourceManager.TextureLoadDetails.new(dir, "Textures/" + back + "Back.png")
	
	var color = Color.WHITE
	if hud.number > len(player_backs):
		color = get_player_color(hud.number)
	
	hud.get_node("Outline").texture = texture_details.gen()
	hud.get_node("Outline").modulate = color

func update_hud_positions():
	for hud in player_huds.values():
		update_hud_position(hud)

func update_hud_position(hud : PlayerHUD):
	var number = hud.number
	var window_size = get_window().size
	
	match number:
		0:
			hud.position = basic_hud_offset
			hud.horizontal = "LEFT"
			hud.vertical = "UP"
		1:
			hud.position = (basic_hud_offset * Vector2(-1, 1)) + Vector2(window_size.x, 0)
			hud.horizontal = "RIGHT"
			hud.vertical = "UP"
		2:
			hud.position = (basic_hud_offset * Vector2(1, -1)) + Vector2(0, window_size.y)
			hud.horizontal = "LEFT"
			hud.vertical = "DOWN"
		3:
			hud.position = (basic_hud_offset * Vector2(-1, -1)) + Vector2(window_size)
			hud.horizontal = "RIGHT"
			hud.vertical = "DOWN"
	
	hud.update_positions()

func get_player_color(number):
	if number > len(player_colors):
		var rando = [0, 1, randf_range(0, 1)]
		var color = Color()
		for channel in ["r", "g", "b"]:
			var value = rando.pick_random()
			rando.erase(value)
			
			color.set(channel, value)
		
		return color
	
	return player_colors[number]

func get_player_icon_back(number):
	if number > len(player_backs):
		return "White"
	
	return player_backs[number]

func load_screen(screen_idx):
	if current_screen:
		current_screen.hide()
	
	current_screen = screens[screen_idx]
	current_screen.show()

func reset_screen():
	current_screen.hide()
	current_screen = null

class PauseScreen extends InterfaceScreen:
	pass

class MainMenuScreen extends InterfaceScreen:
	
	signal choose_level(load_command)
	signal choose_mod(mod)
	
	var mod : String
	var level : String
	var section : String
	
	func _init():
		super([
					InterfaceImage.new("res://Textures/ahsokamenu2.png"),
					InterfaceLineEdit.new("Mod", set_mod, "Ahsoka Show"),
					InterfaceButton.new("Load Hub", button_load_hub),
					InterfaceLineEdit.new("Level", set_level, "EscapeOnArcana"),
					InterfaceLineEdit.new("Section", set_section, ""),
					InterfaceButton.new("Load Level", button_load_level),
				])
	
	func button_load_hub():
		var load_command = LevelManager.LevelLoadCommand.new()
		
		load_command.mod = mod
		load_command.level = "HUB"
		load_command.mode = Level.LevelMode.HUB
		
		emit_signal("choose_mod", mod)
		emit_signal("choose_level", load_command)
	
	func button_load_level():
		var load_command = LevelManager.LevelLoadCommand.new()
		
		load_command.mod = mod
		load_command.level = level
		load_command.section_override = section
		load_command.mode = Level.LevelMode.FREEPLAY
		
		emit_signal("choose_mod", mod)
		emit_signal("choose_level", load_command)
	
	func set_mod(new_mod):
		mod = new_mod
	
	func set_level(new_level):
		level = new_level
	
	func set_section(new_section):
		section = new_section

class InterfaceScreen extends CenterContainer:
	
	var items : Array = []
	var vbox_container : VBoxContainer
	
	func _init(_items):
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		theme = load("res://Interfaces/ButtonsTheme.tres")
		
		items = _items
		spawn()
	
	func spawn():
		
		vbox_container = VBoxContainer.new()
		#vbox_container.add_theme_constant_override("separation", -15)
		add_child(vbox_container)
		
		for item in items:
			vbox_container.add_child(item)

class InterfaceImage extends TextureRect:
	func _init(path):
		texture = load(path)

class InterfaceButton extends Button:
	func _init(_text, callable):
		generic_format()
		text = _text
		connect("pressed", callable)
	
	func generic_format():
		flat = true

class InterfaceLineEdit extends LineEdit:
	func _init(_text, callable, default):
		placeholder_text = _text
		connect("text_changed", callable)
		text = default
		emit_signal("text_changed", default)
