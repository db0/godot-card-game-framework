# This class contains all the functions required to perform
# full rules enforcement on any card
#
# Each function is effectively an API to call the various card functions
# through a text-based definition
#
# This class is loaded by each card invidually, and contains a link
# back to the card object itself
class_name ScriptingEngine
extends Reference

# Emitted when all scripts have finished running
signal scripts_completed

# Contains a list of all the scripts still left to run for this card
var _running_scripts: Array
# The card which owns this Scripting Engine.
var _card_owner
# Set when a card script wants to use a common target for all effects
# To avoid multiple targetting arrows
var _common_target := false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Sets the owner of this Scripting Engine
func _init(owner) -> void:
	_card_owner = owner


# The main engine starts here. It populates an array with all the scripts
# to execute, then goes one by one and sends them to the appropriate
# functions
func run_next_script() -> void:
	if _running_scripts.empty():
		#print('Scripting: All done!') # Debug
		_common_target = false
		# Once the target card has been used, we clear it to avoid
		# any bugs
		_card_owner.target_card = null
		emit_signal("scripts_completed")
	else:
		var script = _running_scripts.pop_front()
		#print("Scripting: " + str(script)) # Debug
		if script['name'] == 'custom':
			call('custom_script')
		elif script['name']:
			_find_subject(script)
		else:
			print("[WARN] Found empty script. Ignoring...")
			 # If card has a script but it's null, it probably not coded yet. Just go on...
			run_next_script()


# Core script for rotating cards
#
# Requires the following keys:
# * "degrees": int
func rotate_card(card, script: Dictionary) -> void:
	card.card_rotation = script["degrees"]
	run_next_script()


# Core script for flipping cards
#
# Requires the following keys:
# * "set_faceup": bool
func flip_card(card, script: Dictionary) -> void:
	card.is_faceup = script["set_faceup"]
	run_next_script()


# Core script for moving to other containers
#
# Requires the following keys:
# * "container": CardContainer
func move_card_to_container(card, script: Dictionary) -> void:
	card.move_to(script["container"])
	run_next_script()


# TODO
# func generate_card(card, script: Dictionary) -> void:
# func move_card_to_board(card, script: Dictionary) -> void:
# func move_card_from_container_to_container(container, script: Dictionary) -> void:
# func move_card_from_container_to_board(script: Dictionary) -> void:
# func shuffle_container(container, script: Dictionary) -> void:
# func mod_card_tokens(card, script: Dictionary) -> void:



# Scripts pass through this function to find their expected subject card.
# The "subject" key in the dictionary specifies what card we're looking for.
func _find_subject(script: Dictionary) -> void:
	var subject
	# If set to true, only one target will be looked for with the arrow
	# If one is selected, then no other will be sought, until the next
	# until the next common_target_request == false
	# If common_target_request == false, then we look for a new target
	# If no common_target_request has been specified, we default to true
	var common_target_request : bool = script.get("common_target_request", true)
	# Subject can be "self", "target" or a node
	# If the subject is "target", we start the targetting
	# to make the player to find one
	if script["subject"] == "target":
		yield(_initiate_card_targeting(common_target_request), "completed")
		subject = _card_owner.target_card
	# If the subject is "self", we return the _card_owner
	# of this ScriptingEngine
	elif script["subject"] == "self":
		subject = _card_owner
	# Otherwise we pass null, assuming there's no subject needed
	else:
		subject = null
	# Args should be an array of arguments to pass
	call(script['name'], subject, script)


# Handles initiation of target seeking.
func _initiate_card_targeting(common_target_req):
	# If we're using a common target for all the scripts
	# Then we don't trigger new arrows
	if not _common_target:
		# We wait a centisecond, to prevent the card's _input function from seeing
		# The double-click which started the script and immediately triggerring
		# the target completion
		yield(_card_owner.get_tree().create_timer(0.1), "timeout")
		_card_owner.initiate_targeting()
		# We wait until the targetting has been completed to continue
		yield(_card_owner,"target_selected")
		_common_target = common_target_req
	else:
		# I don't understand it, but if I remove this timer
		# it breaks the yield from the caller
		# Replacing it with a pass or something simple doesn't work either
		yield(_card_owner.get_tree().create_timer(0.1), "timeout")
