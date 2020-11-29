# This class contains the definitions of all card scripts
# defined in your game.
#
# For reference. Each individual script to execute one single card manipulation
# is called a "task".
#
# Everything is defined in the `scripts` dictionary inside `get_scripts()`
# where the key is each card"s name.
# This means that cards with the same name have the same scripts!
#
# Not only that, but the cards can handle different scripts, depending on
# where the are when the scripts are triggered (hand, board, pile etc).
#
# The format for each card is as follows:
# * First key is the card name in plaintext. At it would appear
#	in the card_name variable of each card.
# * Inside that is a dictionary based on triggers. Each trigger specified
#   what causes the script to fire. The default one is "manual"
#   which triggers when the player double-clicks the card.
#   You can see the list of triggers in `cfc.SignalPropagator.known_card_signals`
# * Inside is a dictionary based on card states, where each key is the container
#	from which the scripts will execute. So if the key is "board", then
#	the scripts defined in that dictionary, will be executed only while
#	the card in on the board (based on its state).
# * Inside the state dictionary, is an array which contains one dictionary
#	per individual task. The tasks will execute in the order
#	they are defined in that list.
# * Each task dictionary has many possible keys depending on its type,
#	but also a few mandatory ones:
# * * *(Mandatory)* **String** `"name"`: The name of the function which
#	to call inside the ScriptingEngine.
# * * *(Mandatory)* `"subject"`: The thing that will be affected by this script.
# * * * `"self"`: The card which owns/runs this script.
# * * * `"target"`: The player will be asked to select a card with a taretting arrow.
# * * * `CardContainer`: Will be pre-specified in the task.
# * * *(Optional)* **bool** `"common_target_request"`: Used then subject
#		is `"target"` to tell the script whether to target each script
#		individually. Defaults to true.
# * * *(Mandatory)* Script arguments are put in the form of their individual names
#		and value types as per their definition
#		in the corresponding `ScriptingEngine.gd` task.
# * * *(Optional)* **String** `"trigger"`: Used with signal triggers to specify
#		further limitation to the trigger. You should generally always try
#		to specify the trigger, during anything other than manual execution
#		to keep things more understandable
# * * * `"any"` (Default): This effect will run regardless of who the trigger is
# * * * `"another"`: This effect will run only if the trigger card
#		is someone other than self
# * * * `"self"`: This effect will run only if the trigger card is self
# * * *(Optional)* limit_to_...: You can specify limits for this script that match
#		The triggering signal. The following have been defined
# * * * **int** `"limit_to_degrees"`: Use with card_rotated signal
# * * * **bool** `"limit_to_faceup"`: Use with card_flipped signal
# * * * **CardContainer** `"limit_to_source"`: Use with card_moved_to_... signals
# * * * **CardContainer** `"limit_to_destination"`: Use with card_moved_to_... signals
#
# And exception to the above is when the name is "custom_script".
# In that case you don't need any other keys. The complete definition should
# be in CustomScripts.gd
class_name CardScriptDefinitions
extends Reference

# This fuction returns all the scripts of the specified card name.
#
# if no scripts have been defined, an empty dictionary is returned instead.
func get_scripts(card_name: String, trigger: String) -> Dictionary:
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
						"subject": "target",
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
				"board": [
					{
						"name": "rotate_card",
						"subject": "self",
						"degrees": 270,
						"trigger": "another",
					},
				]
			},
		},
	}
	# We return only the scripts that match the card name and trigger
	return(scripts.get(card_name,{}).get(trigger,{}))
