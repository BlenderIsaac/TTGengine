extends WeaponEffect
class_name ColliderDamageEffect

var area : Area3D
var col : CollisionShape3D
var impact_sender : ImpactSender

var ray_count = 0
var rays_start : Vector3
var rays_end : Vector3

var is_damaging := false

func _ready():
	impact_sender.creator = weapon.C
	weapon.C.connect("anim_start", anim_started)
	col.set_disabled(true)

var anim_tween : Tween
func anim_started(_anim_name):
	if anim_tween:
		anim_tween.kill()
	
	col.set_disabled(true)
	
	if weapon.active:
		
		var key_frames = weapon.C.get_anim_key_frames()
		if "StartDamage" in key_frames or "EndDamage" in key_frames:
			var damage_start : float = key_frames.get("StartDamage", 0.0)
			var damage_end : float = key_frames.get("EndDamage", 1.0)
			
			anim_tween = create_tween()
			if damage_start > 0.0:
				anim_tween.tween_interval(damage_start)
			
			anim_tween.tween_callback(Callable(col, "set_disabled").bind(false))
			
			anim_tween.tween_interval(damage_end - damage_start)
			anim_tween.tween_callback(Callable(col, "set_disabled").bind(true))


func body_enter(body):
	if "impact_reciever" in body:
		impact_sender.send_to(body.impact_reciever)


class LoadDetails extends WeaponEffect.LoadDetails:
	var collision : ResourceManager.ColLoadDetails
	var impact_sender : ImpactSender
	
	func gen2():
		var effect = ColliderDamageEffect.new()
		
		var area = Area3D.new()
		effect.add_child(area)
		var col = collision.gen()
		area.add_child(col)
		effect.col = col
		effect.area = area
		area.set_collision_mask_value(2, true)
		area.connect("body_entered", effect.body_enter)
		
		effect.impact_sender = impact_sender
		
		return effect
