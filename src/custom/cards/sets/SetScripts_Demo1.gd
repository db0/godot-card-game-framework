# See README.md
extends Reference

# This fuction returns all the scripts of the specified card name.
#
# if no scripts have been defined, an empty dictionary is returned instead.
func get_scripts(card_name: String, trigger: String) -> Dictionary:
	var scripts := {
		"Test Card 1": {
			"manual": {
				"board": {
					"Rotate This Card": [
						{
							"name": "rotate_card",
							"subject": "self",
							"degrees": 90,
						}
					],
					"Flip This Card Face-down": [
						{
							"name": "flip_card",
							"subject": "self",
							"set_faceup": false,
						}
					]
				},
				"hand": [
					{
						"name": "spawn_card",
						"card_scene": "res://src/core/CardTemplate.tscn",
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
						"container": cfc.NMAP.discard,
					},
					{
						"name": "move_card_to_container",
						"subject": "self",
						"container": cfc.NMAP.discard,
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
	return(scripts.get(card_name,{}).get(trigger,{}))
