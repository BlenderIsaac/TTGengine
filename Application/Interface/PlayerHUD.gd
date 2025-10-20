extends Node2D
class_name PlayerHUD

#@export_tool_button("Update Positions") var call : Callable = Callable(self, "update_positions")
@export_enum("LEFT", "RIGHT") var horizontal : String = "LEFT"
@export_enum("UP", "DOWN") var vertical : String = "UP"

var money = 0:
	set(value):
		money = value
		$MoneyParent/Money.text = f.format_num(value)

var d_i_p_pos = Vector2(58, 30)
var coin_pos = Vector2(74, -13)
var money_text_pos = Vector2(25.02, -17.98)
var heart_pos = Vector2(75.6, 17.6)

var player : Player

var character : Character

var number : int

func _ready():
	update_visual_money()
	$DropInPrompt.visible = player == null
	modulate.a = 0.5 if player == null else 1.0

func set_player(new_player):
	if player:disconnect_from_player(player)
	player = new_player
	if player:connect_to_player(player)
	
	$DropInPrompt.visible = player == null
	modulate.a = 0.5 if player == null else 1.0

func connect_to_player(p : Player):
	p.connect("controlling_changed", set_character)
	p.connect("tree_exited", set_player.bind(null))
	p.connect("spawn_visual_stud", spawn_visual_stud)
	p.connect("force_update_money", update_visual_money)
	set_character(p.controlling)
	update_visual_money()

func disconnect_from_player(p : Player):
	p.disconnect("controlling_changed", set_character)
	p.disconnect("tree_exited", set_player.bind(null))
	p.disconnect("spawn_visual_stud", spawn_visual_stud)
	p.disconnect("force_update_money", update_visual_money)

func set_character(new_char : Character):
	if character:
		character.disconnect("health_changed", $HeartParent.set_hearts)
		
		character.disconnect("icon_changed", $Head.set_texture)
		$Head.texture = null
	
	character = new_char
	
	if new_char:
		new_char.connect("health_changed", $HeartParent.set_hearts)
		$HeartParent.set_hearts(new_char.hit_points)
		
		new_char.connect("icon_changed", $Head.set_texture)
		$Head.texture = new_char.icon

func get_camera_focal_length(camera):
	var rect = get_viewport().get_visible_rect()
	return rect.size.y / (2.0 * tan(deg_to_rad(camera.fov) * 0.5))

func spawn_visual_stud(pos, frame, type, value):
	# TODO: different cameras
	var camera : Camera3D = get_viewport().get_camera_3d()
	var pos2d = camera.unproject_position(pos)
	var size = get_camera_focal_length(camera) / camera.position.distance_to(pos)
	var sprite : AnimatedSprite2D = ResourceManager.create_scene("Application/Interface/stud_vis", pos2d, self)
	sprite.scale = Vector2(size, size) * 0.007
	sprite.play(type)
	sprite.frame = frame
	
	var move_tween = create_tween()
	move_tween.tween_property(sprite, "position", $MoneyParent/CoinHUD.global_position, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	move_tween.parallel().tween_property(sprite, "scale", $MoneyParent/CoinHUD.global_scale, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
	move_tween.tween_callback(add_visual_money.bind(value, type, frame))
	move_tween.tween_callback(sprite.queue_free)

func add_visual_money(amount, type, frame):
	money += amount
	$MoneyParent/Anim.stop()
	$MoneyParent/Anim.play("Juice")

func update_visual_money():
	if player:
		money = player.money
	else:
		money = 0

func update_positions():
	var x = 1 if horizontal == "LEFT" else -1
	var y = 1 if vertical == "UP" else -1
	
	$DropInPrompt.position = Vector2(d_i_p_pos.x * x, d_i_p_pos.y * y)
	$MoneyParent.position = Vector2(coin_pos.x * x, coin_pos.y * y)
	$MoneyParent/Money.position.x = money_text_pos.x * x
	$HeartParent.position = Vector2(heart_pos.x * x, heart_pos.y * y)
	
	$HeartParent.mltply = x
	$HeartParent.update_heart_visuals()
	
	match horizontal:
		"LEFT":
			
			$DropInPrompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			$MoneyParent/Money.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		"RIGHT":
			$DropInPrompt.position.x -= $DropInPrompt.size.x
			$MoneyParent/Money.position.x -= $MoneyParent/Money.size.x
			
			$DropInPrompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			$MoneyParent/Money.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	
	match vertical:
		"UP":
			pass
		"DOWN":
			$DropInPrompt.position.y -= $DropInPrompt.size.y
