extends Node
class_name Interface

var current_screen = null
var game_manager : GameManager

enum {
	MAIN_MENU
}

var screens = []

signal choose_level(load_command : LevelManager.LevelLoadCommand)
signal choose_mod(mod)

func _ready():
	create_screens()
	
	game_manager.level_manager.connect("level_loading", reset_screen)
	
	name = "Interface"

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
		load_command.mode = LevelManager.LevelLoadCommand.HUB
		
		emit_signal("choose_mod", mod)
		emit_signal("choose_level", load_command)
	
	func button_load_level():
		var load_command = LevelManager.LevelLoadCommand.new()
		
		load_command.mod = mod
		load_command.level = level
		load_command.section_override = section
		load_command.mode = LevelManager.LevelLoadCommand.STORY
		
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
