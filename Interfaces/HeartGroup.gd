extends Node2D


@export var offset_x = 30
@export var offset_y = 30
@export var initial_pos = Vector2(208, 102)

var heart_texture = "res://Textures/Heart.png"

@export var mltply = 1

var hearts_generated = 0

var t = 0.0

var per_row = -1

@export var max_hearts:int = 4:
	set(value):
		max_hearts = value
		
		while hearts_generated > max_hearts:
			get_node("Heart"+str(hearts_generated)).queue_free()
			hearts_generated -= 1
		
		while hearts_generated < max_hearts:
			create_heart()
		
		hearts = clamp(hearts, 0, max_hearts)
		
		update_heart_visuals()
@export var hearts:int = 4:
	set(value):
		hearts = clamp(value, 0, max_hearts)
		
		update_heart_visuals()

func _ready():
	max_hearts = max_hearts
	hearts = hearts

func _process(_delta):
	#if Input.is_action_just_pressed("Click"):
		#for child in get_children():
			#child.free()
		#
		#hearts_generated = 0
		#while hearts_generated < max_hearts:
			#create_heart()
	
	if hearts > 0:
		
		t += _delta*4.0
		
		var BOBHEART = get_node("Heart"+str(int(hearts)))
		
		var s = 1.0+(abs(sin(t))*0.1)
		
		BOBHEART.scale.x = s
		BOBHEART.scale.y = s


func update_heart_visuals():
	for heart in range(1, max_hearts+1):
		var HEART = get_node("Heart"+str(heart))
		HEART.scale = Vector2(1, 1)
		
		if heart > hearts:
			HEART.modulate = Color("ffffff50")
		else:
			HEART.modulate = Color("ffffffff")
		
		var heart_index = heart-1
		if per_row == -1 or heart_index < per_row:
			HEART.position = initial_pos
			HEART.position.x += offset_x*heart_index*mltply
		else:
			var column = fmod(heart_index, per_row)
			@warning_ignore("integer_division")
			var row = floor(int(heart_index)/int(per_row))
			
			HEART.position = initial_pos
			HEART.position.y += offset_y*row
			HEART.position.x += offset_x*column*mltply


func create_heart():
	var HEART = Sprite2D.new()
	HEART.texture = l.get_load(heart_texture)
	
	HEART.name = "Heart"+str(hearts_generated+1)
	add_child(HEART)
	
	hearts_generated += 1
