extends "res://Scripts/TriggerAnim.gd"

var logic_str = ""
var postfix_logic = []
var object_to_trigger

var play_anim = false

# we need to contstruct something that looks like
#[obj1, obj2, [obj3, [obj4, obj5], obj6]]
# that goes to
#[true, true, [true, [true, true], true]]


func extends_ready():
	play_anim = props.ANIM
	logic_str = props.LINE
	#print(props)
	postfix_logic = infix2postfix(props.LINE)


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

#func _process(delta):
	#triggered = are_we_triggered()
	#print(triggered)

func _process(_delta):
	
	
	
	if play_anim:
		
		if anim_time > 0:
			anim_time -= _delta
		else:
			playing = false
		
		var triggering = is_triggering()
		lbl.text = str(triggering)
		
		if triggering:
			delay = untrigger_wait
			if current_animation == "Default":
				anim_play("Trigger")
		else:
			if !playing:
				if current_animation == "Trigger":
					if delay <= 0:
						anim_play("UnTrigger")
					else:
						delay -= _delta
		
		triggered = !playing and (triggering or (!triggering and delay > 0))
		
		if current_animation == "UnTrigger" and not playing:
			anim_play("Default")
	else:
		triggered = are_we_triggered()


func is_triggering():
	return are_we_triggered()


func are_we_triggered():
	return evaluate_postfix(postfix_logic)


var operators = ["and", "or"]
func evaluate_postfix(postfix_array):
	var stack = []
	
	
	for item in postfix_array:
		if item in operators:
			var obj1 = stack.pop_back()
			var obj2 = stack.pop_back()
			
			stack.append(calculate(item, obj1, obj2))
		elif item == "not":
			var reversing = stack.pop_back()
			stack.append(!reversing)
		else:
			stack.append(is_obj_triggered(item))
	
	return stack.pop_back()



func calculate(operator, bool1, bool2):
	match operator:
		"and":
			return bool1 and bool2
		"or":
			return bool1 or bool2


func is_obj_triggered(obj_str):
	var mesh_parent = gltf.get_node(obj_str)
	var trig_object
	
	if "triggered" in mesh_parent:
		trig_object = mesh_parent
	else:
		for child in mesh_parent.get_children():
			if "triggered" in child:
				trig_object = child
	
	return trig_object.triggered
