extends Area3D
class_name Projectile

var speed : float
var damage : f.Damage
var impact_sender

var lifetime := 20.0
var death_tween : Tween

func _ready():
	set_collision_mask_value(2, true)
	connect("body_entered", body_enter)
	reset_lifetime()


func _process(delta):
	position += -transform.basis.z * speed * delta

func _physics_process(delta):
	print(get_overlapping_bodies())

func body_enter(_body):
	if "impact_reciever" in _body:
		pass
	
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
	var damage : f.Damage
	
	var lifetime : float
	
	func gen():
		var proj = Projectile.new()
		
		proj.speed = speed
		proj.damage = damage
		if lifetime:proj.lifetime = lifetime
		
		proj.add_child(collision.gen())
		proj.add_child(model.gen())
		
		return proj
