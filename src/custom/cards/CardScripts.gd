class_name CardScripts
extends Reference

func get_scripts(card_name) -> Dictionary:
	var scripts := {
		"Test Card 1": {
			"hand": [{
				'name': 'rotate_self',
				'args': ["self",90]}],
			"board": [{
				'name': 'move_self_to_container',
				'args': ["self",cfc.NMAP.deck]}]},
		"Test Card 2": {
			"board": [{
				'name': 'rotate_self',
				'args': ["self",270]}],
			"pile": [{
				'name': 'move_self_to_container',
				'args': ["self",cfc.NMAP.discard]}]},
	}
	return(scripts.get(card_name,{}))
