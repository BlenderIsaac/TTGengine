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
	postfix_logic = f.infix2postfix(props.LINE)

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
