# This class contains the definitions of all card scripts
# defined in your game.
#
# Everything is defined in the 'scripts' dictionary where the key is each
# card's name. This means that cards with the same name have the same scripts!
#
# Not only that, but the cards can handle different scripts, depending on
# where the are when the scripts are triggered (hand, board, pile etc)
#
# The format for each card is as follows
# * Key is card name in plaintext. At it would appear
#   in the card_name variable of each card
# * Inside is a dictionary based on card states, where each key is the area from
#   which the scripts will execute. So if the key is "board", then
#   the scripts defined in that dictionary, will be executed only while
#   the card in on the board (based on its state)
# * Inside the state dictionary, is a list which contains the individual
#   calls to the various scripts.
#   The scripts execute in the order they are defined in that list.
# * Each script in that list is a dictionary with two possible keys
#   * name is the name of the function which to call inside the ScriptingEngine
#   * args is an array, which contains all the arguments that function
#     requires to function. The array args have to be in the same order!
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
					'name': 'rotate_self',
					'args': [90],
				}
			],
			"hand": [
				{
					'name': 'flip_target',
					'args':  [false,false],
				}
			]
		},

		"Test Card 2": {
			"board": [
				{
					'name': 'move_target_to_container',
					'args': [cfc.NMAP.discard, false],
				},
				{
					'name': 'move_self_to_container',
					'args': [cfc.NMAP.discard],
				}
			],
			"pile": [
				{
					'name': 'move_self_to_container',
					'args': [cfc.NMAP.discard],
				}
			]
		},

		"Test Card 3": {
			"board": [
				{
					'name': 'flip_target',
					'args': [false,true],
				},
				{
					'name': 'rotate_target',
					'args': [180, true],
				}
			],
			"hand": [
				{
					'name': 'move_self_to_container',
					'args': [cfc.NMAP.discard],
				}
			]
		},
	}
	return(scripts.get(card_name,{}))
