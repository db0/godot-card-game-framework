# See README.md
extends Reference

# This fuction returns all the scripts of the specified card name.
#
# if no scripts have been defined, an empty dictionary is returned instead.
func get_scripts(card_name: String) -> Dictionary:
	var scripts := {
		"Test Card 1": {
			"card_moved_to_board": {
				"board": [
					{
						"name": "mod_tokens",
						"modification": 1,
						"token_name": "bio",
						"subject": "self"
					},
				],
				"trigger": "self",
				SP.FILTER_SOURCE: cfc.NMAP.hand,
			},
		},
		"Test Card 2": {
			"manual": {
				"board": [
					{
						"name": "move_card_to_container",
						"subject": "target",
						"dest_container": cfc.NMAP.discard,
					},
					{
						"name": "move_card_to_container",
						"subject": "self",
						"dest_container": cfc.NMAP.discard,
					}
				],
				"hand": [
					{
						"name": "custom_script",
					}
				]
			},
		},
	}
	# We return only the scripts that match the card name and trigger
	return(scripts.get(card_name,{}))
