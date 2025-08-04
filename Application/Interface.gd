extends Node
class_name Interface

var current_screen = null
var game_manager = null

enum {
	MAIN_MENU
}

var screens = []


func _ready():
	create_screens()
	
	name = "Interface"

func create_screens():
	## main menu
	var main_menu = create_screen(MainMenuScreen)
	main_menu.connect("load_hub", on_load_hub)
	main_menu.connect("load_level", on_load_level)

func create_screen(screen_class):
	var screen = screen_class.new()
	screen.hide()
	add_child(screen)
	screens.append(screen)
	
	return screen

func load_screen(screen_idx):
	if current_screen:
		current_screen.hide()
	
	current_screen = screens[screen_idx]
	current_screen.show()



class PauseScreen extends InterfaceScreen:
	pass

class MainMenuScreen extends InterfaceScreen:
	
	signal load_hub(mod)
	signal load_level(mod, level, section)
	
	var mod : String
	var level : String
	var section : String
	
	func _init():
		super([
					InterfaceImage.new("res://Textures/ahsokamenu2.png"),
					InterfaceLineEdit.new("Mod", set_mod),
					InterfaceButton.new("Load Hub", button_load_hub),
					InterfaceLineEdit.new("Level", set_level),
					InterfaceLineEdit.new("Section", set_section),
					InterfaceButton.new("Load Level", button_load_level),
				])
	
	func button_load_hub():
		emit_signal("load_hub", mod)
	
	func button_load_level():
		emit_signal("load_level", mod, level, section)
	
	func set_mod(new_mod):
		mod = new_mod
	
	func set_level(new_level):
		level = new_level
	
	func set_section(new_section):
		section = new_section

func on_load_hub(mod):
	var load_command = LevelManager.LevelLoadCommand.new()
	
	load_command.mod = mod
	load_command.level = "HUB"
	load_command.mode = LevelManager.LevelLoadCommand.HUB
	
	game_manager.levelManager.load_level(load_command)

func on_load_level(mod, level, section):
	var load_command = LevelManager.LevelLoadCommand.new()
	
	load_command.mod = mod
	load_command.level = level
	load_command.section = section
	load_command.mode = LevelManager.LevelLoadCommand.STORY
	
	game_manager.levelManager.load_level(load_command)

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
	func _init(_text, callable):
		placeholder_text = _text
		connect("text_changed", callable)
