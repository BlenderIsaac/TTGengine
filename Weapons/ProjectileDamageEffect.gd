extends WeaponEffect
class_name ProjectileDamageEffect

var projectile : Projectile.LoadDetails
var fire_position : Vector3

func trigger(_target):
	await get_tree().process_frame
	var proj = projectile.gen()
	
	proj.impact_sender.creator = weapon.C
	proj.transform = global_transform
	proj.translate_object_local(fire_position)
	
	if _target:
		proj.look_at_from_position(proj.position, _target.position + _target.aim_pos)
	
	weapon.C.section.add_child(proj)

class LoadDetails extends WeaponEffect.LoadDetails:
	var projectile : Projectile.LoadDetails
	var fire_position : Vector3
	
	func gen2():
		var effect = ProjectileDamageEffect.new()
		
		effect.fire_position = fire_position
		effect.projectile = projectile
		
		return effect
