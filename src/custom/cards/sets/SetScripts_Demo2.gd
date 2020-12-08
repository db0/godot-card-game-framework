# See README.md
extends Reference

# This fuction returns all the scripts of the specified card name.
#
# if no scripts have been defined, an empty dictionary is returned instead.
func get_scripts(card_name: String) -> Dictionary:
	var scripts := {
		"Test Card 3": {
			"manual": {
				"board": [
					{
						"name": "flip_card",
						"subject": "target",
						"set_faceup": false,
					},
					{
						"name": "rotate_card",
						"subject": "previous",
						"degrees": 180,
					}
				],
				"hand": [
					{
						"name": "custom_script",
						"subject": "target",
					}
				]
			},
			"card_rotated": {
				"trigger": "another",
				"board": [
					{
						"name": "mod_tokens",
						"subject": "self",
						"modification": 1,
						"token_name":  "blood",
					},
				]
			},
		},
		"Multiple Choices Test Card": {
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
			},
#			"card_flipped": {
#				"trigger": "another",
#				"board": {
#					"Rotate This Card": [
#						{
#							"name": "rotate_card",
#							"subject": "self",
#							"degrees": 90,
#						}
#					],
#					"Flip This Card Face-down": [
#						{
#							"name": "flip_card",
#							"subject": "self",
#							"set_faceup": false,
#						}
#					]
#				},
#			},
		},
	}
	# We return only the scripts that match the card name and trigger
	return(scripts.get(card_name,{}))
