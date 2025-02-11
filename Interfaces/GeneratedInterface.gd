extends Control


@export var buttons : Array[PackedStringArray]
@export var backing = true
@export var font_size = 52
@export var outline_size = 14

var center_box:CenterContainer
var v_box:VBoxContainer

var Buttons = []

# Called when the node enters the scene tree for the first time.
func _ready():
	spawn()


func spawn():
	center_box = CenterContainer.new()
	v_box = VBoxContainer.new()
	
	add_child(center_box)
	center_box.add_child(v_box)
	
	#center_box.layout_mode = 1
	center_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	center_box.size = Vector2(1152, 563)
	v_box.add_theme_constant_override("separation", -2)
	
	for button in buttons:
		var n = button[0]
		var t = button[1]
		
		var B:Button = Button.new()
		B.name = n
		B.text = t
		
		B.flat = true
		B.add_theme_font_size_override("font_size", font_size)
		B.add_theme_constant_override("outline_size", outline_size)
		B.connect("pressed", Callable.create(get_parent(), "Button_"+n))
		
		Buttons.append(B)
		
		v_box.add_child(B)
	
	var index = 0
	var list_size = Buttons.size()
	for button in Buttons:
		button.focus_neighbor_top = NodePath("../"+buttons[index-1][0])
		
		if index+1 >= list_size:
			button.focus_neighbor_bottom = NodePath("../"+buttons[0][0])
		else:
			button.focus_neighbor_bottom = NodePath("../"+buttons[index+1][0])
		
		index += 1
