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

# Contains a list of all the scripts still left to run for this card
var running_scripts: Array
# The card which owns this Scripting Engine.
var card_owner
# Set when a card script wants to use a common target for all effects
# To avoid multiple targetting arrows
var _common_target := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Sets the owner of this Scripting Engine
func _init(owner, target) -> void:
	card_owner = owner


# The main engine starts here. It populates an array with all the scripts
# to execute, then goes one by one and sends them to the appropriate
# functions
func run_next_script() -> void:
	if running_scripts.empty():
		#print('Scripting: All done!') # Debug
		_common_target = false
	else:
		var script = running_scripts.pop_front()
		#print("Scripting: " + str(script)) # Debug
		if script['name'] == 'custom':
			call('custom_script')
		elif script['name']:
			call(script['name'], script['args']) # Args should be an array of arguments to pass
			""" Available scripts:
				move_self_to_container([CardContainer])
				move_target_to_container([CardContainer, bool common_target])
				move_self_to_board([Card, Vector2])
				generate_card([str card_path, int amount])
				rotate_self([int degrees])
				rotate_self([int degrees, bool common_target])
				flip_self([])
				flip_target([bool common_target])
			"""
		else:
			print("[WARN] Found empty script. Ignoring...")
			 # If card has a script but it's null, it probably not coded yet. Just go on...
			run_next_script()


# Rotates the owner of this Scripting Engine the specified degrees
func rotate_self(args) -> void:
	var degrees: int = args[0]
	_rotate_card(card_owner, degrees)


# Targets a card to rotate the specified degrees
func rotate_target(args) -> void:
	var degrees: int = args[0]
	var common_target_request = args[1]
	# I don't understand why, but if I put this check inside
	# the _initiate_card_targeting() function, it breaks the second yield
	yield(_initiate_card_targeting(common_target_request), "completed")
	_rotate_card(card_owner.target_card, degrees)


# Flips face-up or -down the owner of this Scripting Engine
func flip_self(args) -> void:
	var is_faceup: bool = args[0]
	_flip_card(card_owner,  is_faceup)


# Targets a card to Flip face-up or -down
func flip_target(args) -> void:
	var is_faceup: bool = args[0]
	var common_target_request = args[1]
	yield(_initiate_card_targeting(common_target_request), "completed")
	_flip_card(card_owner.target_card, is_faceup)


# Moves the owner of this Scripting Engine to a different container
func move_self_to_container(args) -> void:
	var container = args[0]
	_move_card_to_container(card_owner,container)


# Targets a card to move to a different container
func move_target_to_container(args) -> void:
	var container = args[0]
	var common_target_request = args[1]
	yield(_initiate_card_targeting(common_target_request), "completed")
	_move_card_to_container(card_owner.target_card, container)


# Core script for moving to other containers
func _move_card_to_container(card, container) -> void:
	card.move_to(container)
#	yield(card.get_node("Tween"), "tween_all_completed")
#	if cfc.fancy_movement:
#		yield(card.get_node("Tween"), "tween_all_completed")
	run_next_script()


# Core script for rotating cards
func _rotate_card(card, degrees) -> void:
	card.card_rotation = degrees
	#yield(card.get_node("Tween"), "tween_all_completed")
	run_next_script()


# Core script for flipping cards
func _flip_card(card,is_faceup) -> void:
	card.is_faceup = is_faceup
	#yield(card.get_node("Tween"), "tween_all_completed")
	run_next_script()


# Handles initiation of target seeking.
func _initiate_card_targeting(common_target_req):
	# If we're using a common target for all the scripts
	# Then we don't trigger new arrows
	if not _common_target:
		# We wait a centisecond, to prevent the card's _input function from seeing
		# The double-click which started the script and immediately triggerring
		# the target completion
		yield(card_owner.get_tree().create_timer(0.1), "timeout")
		card_owner.initiate_targeting()
		# We wait until the targetting has been completed to continue
		yield(card_owner,"target_selected")
		_common_target = common_target_req
	else:
		# I don't understand it, but if I remove this timer
		# it breaks the yield from the caller
		# Replacing it with a pass or something simple doesn't work either
		yield(card_owner.get_tree().create_timer(0.1), "timeout")
