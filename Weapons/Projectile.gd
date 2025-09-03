extends Area3D
class_name Projectile

var creator

var speed : float
var impact_sender : ImpactSender

var lifetime := 20.0
var death_tween : Tween

var die_on_hit := true

func _ready():
	set_collision_mask_value(2, true)
	connect("body_entered", body_enter)
	reset_lifetime()


func _process(delta):
	position += -transform.basis.z * speed * delta


func body_enter(body):
	if body == creator:
		return
	
	if "impact_reciever" in body:
		impact_sender.send_to(body.impact_reciever)
	
	despawn()

func reset_lifetime():
	if death_tween:
		death_tween.stop()
	
	death_tween = create_tween()
	death_tween.tween_interval(lifetime)
	death_tween.tween_callback(despawn)


func despawn():
	queue_free()


class LoadDetails:
	var model : ResourceManager.ModelLoadDetails
	var collision : ResourceManager.ColLoadDetails
	
	var speed : float
	var impact_sender : ImpactSender
	
	var lifetime : float
	
	func gen():
		var proj = Projectile.new()
		
		proj.speed = speed
		proj.impact_sender = impact_sender
		impact_sender.intermidiary = proj
		if lifetime:proj.lifetime = lifetime
		
		proj.add_child(collision.gen())
		proj.add_child(model.gen())
		
		return proj
