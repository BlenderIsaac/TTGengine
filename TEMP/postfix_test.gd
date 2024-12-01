extends Control


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	if $Active.button_pressed:
		var postfix = f.infix2postfix($LineEdit.text)
		
		$Label.text = str(evaluate_postfix(postfix))
		$Label2.text = str(postfix)

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
	match operator.to_lower():
		"and":
			return bool1 and bool2
		"or":
			return bool1 or bool2


func is_obj_triggered(obj_str):
	var mesh_parent = get_node(obj_str)
	var trig_object
	
	if "button_pressed" in mesh_parent:
		trig_object = mesh_parent
	else:
		for child in mesh_parent.get_children():
			if "triggered" in child:
				trig_object = child
	
	return trig_object.button_pressed#.triggered
