extends "res://Scripts/TriggerAnim.gd"

var logic
var object_to_trigger

var play_anim = false

# we need to contstruct something that looks like
#[obj1, obj2, [obj3, [obj4, obj5], obj6]]
# that goes to
#[true, true, [true, [true, true], true]]


func extends_ready():
	play_anim = props.ANIM
	logic = props.LINE.split("|")

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
	var is_command = false
	
	var currently_true = true
	
	for piece in logic:
		if is_command:
			pass
		else:
			
			var mesh_parent = gltf.get_node(piece)
			var trig_object
			
			if "triggered" in mesh_parent:
				trig_object = mesh_parent
			else:
				for child in mesh_parent.get_children():
					if "triggered" in child:
						trig_object = child
			
			if trig_object:
				
				if !trig_object.triggered:
					currently_true = false
					break
		
		is_command = !is_command
	
	return currently_true
