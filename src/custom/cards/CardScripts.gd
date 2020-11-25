class_name CardScripts
extends Reference

func get_scripts(card_name) -> Dictionary:
	var scripts := {
		"Test1" : {
			"board" : [
				{'name':'rotate_self',
					'args':["self",90]},
				{'name':'move_self_to_container',
					'args':["self",cfc.NMAP.deck]}]
		}
	}
	return(scripts.get(card_name,[]))
