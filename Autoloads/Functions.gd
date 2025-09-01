extends Node

#var keys_pressed_last_frame = []
#var buttons_pressed_last_frame = []
#var keys_pressed_checking = []
#var buttons_pressed_checking = []


# https://www.reddit.com/r/godot/comments/40cm3w/looping_through_all_children_and_subchildren_of_a/
func get_all_children(node) -> Array:
	
	var nodes : Array = []
	
	for N in node.get_children():
		if N.get_child_count() > 0:
			nodes.append(N)
			nodes.append_array(get_all_children(N))
		else:
			nodes.append(N)
			
	return nodes


func to_vec2(vec3):
	return Vector2(vec3.x, vec3.z)

func vec3_0y(vec3):
	return Vector3(vec3.x, 0, vec3.z)

func LerpVector2(from, to, amount):
	var x = lerp(from.x, to.x, amount)
	var y = lerp(from.y, to.y, amount)
	return Vector2(x, y)

func LerpVector3(from, to, amount):
	var x = lerp(from.x, to.x, amount)
	var y = lerp(from.y, to.y, amount)
	var z = lerp(from.z, to.z, amount)
	return Vector3(x, y, z)

func LerpAngleVector3(from, to, amount):
	var x = lerp_angle(from.x, to.x, amount)
	var y = lerp_angle(from.y, to.y, amount)
	var z = lerp_angle(from.z, to.z, amount)
	return Vector3(x, y, z)

func RandomVector3(x, nx, y, ny, z, nz):
	return Vector3(randf_range(nx, x), randf_range(ny, y), randf_range(nz, z))


func deg2radvec3(vec3):
	return Vector3(deg_to_rad(vec3.x), deg_to_rad(vec3.y), deg_to_rad(vec3.z))

func angle_to_angle(from, to):
	#print("why are you using this? it doesn't work")
	return fposmod(to-from + PI, PI*2) - PI

func merge_arrays(array1, array2):
	var ret = array1.duplicate()
	for element in array2:
		ret.append(element)
	
	return ret


## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(_delta):
#	# make sure this is at the bottom of process.
#
#	for key_checked in keys_pressed_checking:
#
#		# KEYBOARD
#		var has_key = keys_pressed_last_frame.has(key_checked)
#
#		if key_press(key_checked, "keyboard"):
#			if not has_key:
#				keys_pressed_last_frame.append(key_checked)
#		else:
#			if has_key:
#				keys_pressed_last_frame.erase(key_checked)
#
#	for button_checked in buttons_pressed_checking:
#		# CONTROLLER
#		var has_button = buttons_pressed_last_frame.has(button_checked)
#
#		if key_press(button_checked, "controller"):
#			if not has_button:
#				buttons_pressed_last_frame.append(button_checked)
#		else:
#			if has_button:
#				buttons_pressed_last_frame.erase(button_checked)
#
#
#func add_key_to_check(key):
#	if not keys_pressed_checking.has(key):
#		keys_pressed_checking.append(key)
#
#func add_button_to_check(button):
#	if not keys_pressed_checking.has(button):
#		keys_pressed_checking.append(button)
#
#
## Basic function
#func key_just_pressed(key, control_type):
#	var key_currently_pressed = key_press(key, control_type)
#
#	if key_currently_pressed:
#		if keys_pressed_last_frame.has(key) and control_type == "keyboard":
#			return false
#		elif buttons_pressed_last_frame.has(key) and control_type == "controller":
#			return false
#		else:
#			return true
#
#	return false
#
## Basic function
#func key_just_unpressed(key, control_type):
#	var key_currently_pressed = key_press(key, control_type)
#
#	if not key_currently_pressed:
#		if keys_pressed_last_frame.has(key) and control_type == "keyboard":
#			return true
#		elif buttons_pressed_last_frame.has(key) and control_type == "controller":
#			return true
#
#	return false

#func _ready():
#	print(infix2postfix("button1 and button2 and not (button3 or button4)"))

var OP_PREC = {"(":1, "or":2, "and":3, "not":4}

# button1 and button2 and not (button3 or button4)
# ->
# button1 button2 and button3 button4 or not and
func infix2postfix(infixstr):
	var tokens = split_infix_str(infixstr)
	
	var stack = []
	var output = []
	
	for token in tokens:
		#print(stack)
		if token == "(":
			# left parenthesis
			stack.push_back(token)
		elif token == ")":
			# right parethesis
			while stack[-1] != "(":
				output.append(stack.pop_back())
			stack.pop_back()
		elif token in OP_PREC:
			# operator
			while not stack.is_empty() and OP_PREC[stack[-1]] >= OP_PREC[token]:
				output.append(stack.pop_back())
			
			stack.push_back(token)
		else:
			# operand
			output.append(token)
	
	while not stack.is_empty():
		output.append(stack.pop_back())
	
	return output


func split_infix_str(infixstr):
	var infix_array = []
	
	var built = ""
	for c in infixstr:
		if c == " ":
			if built != "":infix_array.append(built)
			built = ""
		elif c == "(" or c == ")":
			if built != "":
				infix_array.append(built)
			
			infix_array.append(c)
			built = ""
		else:
			built += c
	
	
	if built != "":infix_array.append(built)
	
	return infix_array


# Basic function
func key_press(key, control_type, controller_number=0):
	
	if control_type == "keyboard":
		if Input.is_key_pressed(OS.find_keycode_from_string(key)):
			return true
	elif control_type == "controller":
		if Input.is_joy_button_pressed(controller_number, key):
			return true
	
	return false

func gen_array(list):
	var new_list = []
	for element in list:
		new_list.append(element.gen())
	return new_list

func gen_dict(dict):
	var new_dict = {}
	for element in dict.keys():
		new_dict[element] = dict[element].gen()
	return new_dict

class Damage:
	var amount = 1
	var from = null
	var iframes = 0.2
	var knockback = Vector3(0, 0, 0)
	
	func _init(Amount=1, From=null, IFrames=0.2):
		amount = Amount
		from = From
		iframes = IFrames


func is_object_valid(obj):
	if obj == null:
		return false
	
	if !is_instance_valid(obj):
		return false
	
	return true

func does_character_exist(character):
	
	if !is_object_valid(character):
		return false
	
	return true


func is_character_valid(character):
	
	if !is_object_valid(character):
		return false
	
	if character.dead:
		return false
	
	return true


func is_valid_character(body):
	if !is_object_valid(body):
		return false
	
	if body.is_in_group("Character"):
		if body.dead:
			return false
	else:
		return false
	
	return true


var stud_value = {
	"Silver" : 10,
	"Gold" : 100,
	"Blue" : 1000,
	"Purple" : 10000,
	"Pink" : 100000,
}

func _process(_delta):
	if Input.is_action_just_pressed("fullscreen"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		
	#if Input.is_action_just_pressed("Click"):
		#var h = [890]
		#
		#for s in h:
			#
			#var sv = get_stud_values_for_count(s)
			#var fv = 0
			#
			#for v in sv:
				#fv += stud_value[v]

# This was ripped from online
# from https://ask.godotengine.org/18559/how-to-add-commas-to-an-integer-or-float-in-gdscript
func format_num(num):
	var i : int = num.length() - 3
	while i > 0:
		num = num.insert(i, ",")
		i = i - 3
	return num


var exceptions = ["vec3", "array"]
func get_var_from_str(value):
	
	if typeof(value[1]) == typeof(""):
		match value[0]:
			"int":
				return value[1].to_int()
			"str":
				return value[1]
			"dict":
				return value[1]
			"float":
				return float(value[1])
			"bool":
				return get_bool_from_string(value[1])
			"color_hex":
				return Color(value[1])
			_:
				if !exceptions.has(value[0]):
					print(value[0] + " doesn't exist")
				return str_to_var(value[1])
	
	return value[1]


func get_bool_from_string(b):
	if ["true", "t", "yes"].has(b.to_lower()):
		return true
	return false


func transform_based_on_parent(parent, object):
	var total_transform = object.transform
	
	var last_object = object.get_parent()
	
	while last_object != parent:
		#Transform3D().origin
		total_transform.origin += last_object.transform.origin
		total_transform.basis = Basis.from_euler(last_object.transform.basis.get_euler() + total_transform.basis.get_euler())
		
		#total_transform += last_object.transform.scale
		
		last_object = last_object.get_parent()
	
	return total_transform

func get_stud_values_for_count(value):
	# loop until we have dropped enough money
	var has_dropped = 0
	var stud_values = []
	
	while has_dropped < value:
		
		# Variables for the type of stud we are dropping and the value of that stud
		var type_drop = null
		
		# Match the amount of money we have to the types of studs
		if value > 100000:
			type_drop = "Pink"
		elif value > 10000:
			type_drop = "Purple"
		elif value > 1000:
			type_drop = "Blue"
		elif value > 100:
			type_drop = "Gold"
		elif value >= 10:
			type_drop = "Silver"
		
		# If we have found a stud to drop
		if not type_drop == null:
			
			value -= stud_value[type_drop]
			# drop the stud, based on what type the stud is
			stud_values.append(type_drop)
	
	return stud_values
