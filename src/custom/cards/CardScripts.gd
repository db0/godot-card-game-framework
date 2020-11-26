class_name CardScripts
extends Reference

func get_scripts(card_name) -> Dictionary:
	var scripts := {
		"Test Card 1": {
			"hand": [
				{
					'name': 'rotate_self',
					'args': [90]
				}
			],
			"board": [
				{
					'name': 'move_self_to_container',
					'args': [cfc.NMAP.deck]
				}
			]
		},

		"Test Card 2": {
			"board": [
				{
					'name': 'move_target_to_container',
					'args': [cfc.NMAP.discard, false]
				},
				{
					'name': 'move_self_to_container',
					'args': [cfc.NMAP.discard]
				}
			],
			"pile": [
				{
					'name': 'move_self_to_container',
					'args': [cfc.NMAP.discard]
				}
			]
		},

		"Test Card 3": {
			"board": [
				{
					'name': 'flip_target',
					'args': [false,true]
				},
				{
					'name': 'rotate_target',
					'args': [180, true]
				}
			],
			"hand": [
				{
					'name': 'move_self_to_container',
					'args': [cfc.NMAP.discard]
				}
			]
		},
	}
	return(scripts.get(card_name,{}))
