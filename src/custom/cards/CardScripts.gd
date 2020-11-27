# This class contains the definitions of all card scripts
# defined in your game.
#
# Everything is defined in the "scripts" dictionary where the key is each
# card"s name. This means that cards with the same name have the same scripts!
#
# Not only that, but the cards can handle different scripts, depending on
# where the are when the scripts are triggered (hand, board, pile etc)
#
# The format for each card is as follows
# * Key is card name in plaintext. At it would appear
#	in the card_name variable of each card
# * Inside is a dictionary based on card states, where each key is the area from
#	which the scripts will execute. So if the key is "board", then
#	the scripts defined in that dictionary, will be executed only while
#	the card in on the board (based on its state)
# * Inside the state dictionary, is a list which contains one dictionary 
#	per script. The scripts will execute in the order they are defined in that list.
# * Each script in that list is a dictionary with many possible keys, but a few
#	mandatory ones.
# * * (Mandatory) "name" (String value) is the name of the function which 
#	to call inside the ScriptingEngine
# * * (Mandatory) "subject" is the thing that will be affected by this script.
# * * * "self"
# * * * "target"
# * * * a CardContainer node
# * * (Optional) "common_target_request" (bool value) is used then subject 
#		is "target" to tell the script whether to target each script 
#		individually. Defaults to true
# * * (Mandatory) Script arguments are put in the form of their individual names
#		as per their definition in the ScriptingEngine.gd
class_name CardScripts
extends Reference

# This fuction returns all the scripts of the specified card name.
#
# if no scripts have been defined, an empty dictionary is returned instead.
func get_scripts(card_name) -> Dictionary:
	var scripts := {
		"Test Card 1": {
			"board": [
				{
					"name": "rotate_card",
					"subject": "self",
					"degrees": 90,
				}
			],
			"hand": [
				{
					"name": "flip_card",
					"subject": "target",
					"set_faceup": false,
				}
			]
		},

		"Test Card 2": {
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
			"pile": [
				{
					"name": "move_card_to_container",
					"subject": "self",
					"container": cfc.NMAP.discard,
				}
			]
		},

		"Test Card 3": {
			"board": [
				{
					"name": "flip_card",
					"subject": "target",
					"set_faceup": false,
				},
				{
					"name": "rotate_card",
					"subject": "target",
					"degrees": 180,
				}
			],
			"hand": [
				{
					"name": "move_card_to_container",
					"subject": "self",
					"container": cfc.NMAP.discard,
				}
			]
		},
	}
	return(scripts.get(card_name,{}))
