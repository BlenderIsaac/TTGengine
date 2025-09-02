class_name ImpactReciever

var host
var modifiers := []

func recieve_from(sender : ImpactSender):
	sender = sender.copy()
	
	for modifier in modifiers:
		modifier.adapt_sender(sender)
	
	host.take_damage(sender.damage)
	host.take_knockback(sender.get_knockback())
