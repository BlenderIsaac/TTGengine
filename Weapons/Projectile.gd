extends Area3D
class_name Projectile

var speed : float
var damage : f.Damage

func _process(delta):
	position += -transform.basis.z * speed * delta

class LoadDetails:
	var model : ResourceManager.ModelLoadDetails
	var collision : ResourceManager.ColLoadDetails
	
	var speed : float
	var damage : f.Damage
	
	func gen():
		var proj = Projectile.new()
		
		proj.speed = speed
		proj.damage = damage
		
		proj.add_child(collision.gen())
		proj.add_child(model.gen())
		
		return proj
