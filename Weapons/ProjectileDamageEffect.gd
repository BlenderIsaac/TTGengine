extends WeaponDamageEffect
class_name ProjectileDamageEffect

var projectile_details : Projectile.LoadDetails
var trigger_command_name : String

func trigger():
	projectile_details.gen()

class LoadDetails:
	var projectile : Projectile.LoadDetails
	var trigger_command_name := "FirePosition"
	var fire_position : Vector3
	
	func gen():
		var effect = ProjectileDamageEffect.new()
		
		effect.fire_position = fire_position
		effect.projectile_details = projectile
		effect.trigger_command_name = trigger_command_name
		
		return effect
