# See README.md
extends Reference

# This fuction returns all the scripts of the specified card name.
#
# if no scripts have been defined, an empty dictionary is returned instead.
func get_scripts(card_name: String) -> Dictionary:
	var scripts := {
		"Test Card 1": {
			"manual": {
				"board": [
					{
						"name": "rotate_card",
						"subject": "self",
						"degrees": 90,
					}
				],
				"hand": [
					{
						"name": "spawn_card",
						"card_name": "Spawn Card",
						"board_position": Vector2(500,200),
					}
				]
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
		"Shaking Card": {
			"manual": {
				"hand": [
					{
						"name": "mod_counter",
						"modification": 5,
						"counter_name":  "research"
					},
#					{
#						"name": "move_card_to_container",
#						"subject": "self",
#						"dest_container": cfc.NMAP.discard,
#					},
					{
						"name": "nested_script",
						"nested_tasks": [
							{
								"name": "move_card_to_container",
								"is_cost": true,
								"subject": "index",
								"subject_count": "all",
								"subject_index": "top",
								SP.KEY_NEEDS_SELECTION: true,
								SP.KEY_SELECTION_COUNT: 2,
								SP.KEY_SELECTION_TYPE: "equal",
								SP.KEY_SELECTION_OPTIONAL: true,
								SP.KEY_SELECTION_IGNORE_SELF: true,
								"src_container": cfc.NMAP.hand,
								"dest_container": cfc.NMAP.discard,
							},
							{
								"name": "mod_counter",
								"modification": 3,
								"counter_name":  "research"
							},
						]
					},
				],
			},
		},
	}
	# We return only the scripts that match the card name and trigger
	return(scripts.get(card_name,{}))
