# This contains information about one specific task requested by the card
# automation
#
# It also contains methods to return properties of the task and to find
# the required objects in the game
class_name CardScript
extends Reference

# Sent when the _init() method has completed
signal completed_init

# The card which owns this CardScript
var owner: Card
# The subject is typically a Card object
# in the future might be other things
var subject: Card
# The name of the function to call in the ScriptingEngine
var function_name: String
# Storage for all details of the script definition
var properties := {}
# Used by the ScriptingEngine to know if the script
# has finished processing targetting
var has_init_completed := false

# prepares the properties needed by the script to function.
func _init(card: Card, script: Dictionary) -> void:
	var subject_seek
	# We store the card which executes this script
	owner = card
	# We store all the script properties in our own dictionary
	properties = script
	# We discover which other this script will affect, if any
	subject_seek =_find_subject(script)
	if subject_seek is GDScriptFunctionState: # Still seeking...
		subject_seek = yield(subject_seek, "completed")
	subject = subject_seek
	# The function name to be called gets its own var
	function_name = properties.get("name",null)
	# We emit a signal when done so that our ScriptingEngine
	# knows we're ready to continue
	emit_signal("completed_init")
	has_init_completed = true

# Returns the specified property of the string.
# Also sets appropriate defaults when then property has not beend defined.
func get(property: String):
	var default
	match property:
		# Used when we're seeking a card inside a CardContainer
		# Default is to seek card at index 0
		"pile_index":
			default = 0
		# used when placing a card inside a CardContainer
		# When -1 is defined, it is placed on the last position
		"dest_index":
			default = -1
		# Used when placing a card on the board
		# If Vector2(-1,-1) is specified, it uses the mouse position
		# which obviously not good for scripts
		"board_position":
			default = Vector2(-1,-1)
		# Used when placing/modifying a token on a card
		# to specify if we're modifying the existing amount
		# or setting it to the exact one
		"set_to_mod":
			default = false
		# Used when placing/modifying a token on a card
		# to specify the amount we're setting/modifying by
		# or setting it to the exact one
		"modification":
			default = 1
		_:
			default = null
	return(properties.get(property,default))

# Figures out what the subject of this script is supposed to be.
#
# Returns a Card object if subject is defined, else returns null.
func _find_subject(script: Dictionary) -> Card:
	var subject_seek
	# If set to true, only one target will be seeked using with the arrow
	# If one is selected, then no other will be sought,
	# until the next common_target_request == false
	# If no common_target_request has been specified, we default to true
	var common_target_request : bool = script.get("common_target_request", true)
	# Subject can be "self" or "target"
	# If the subject is "target", we initiate targetting from the owner card
	# to ask the player to find a appropriate target
	if script.get("subject") == "target":
		subject_seek = _initiate_card_targeting(common_target_request)
		if subject_seek is GDScriptFunctionState: # Still working.
			subject_seek = yield(subject_seek, "completed")
	# If the subject is "self", we return the _card_owner
	# of this CardScript
	elif script.get("subject") == "self":
		subject_seek = owner
	# Otherwise we pass null, assuming there's no subject needed
	else:
		subject_seek = null
	return(subject_seek)


# Handles initiation of target seeking.
# and yields until it's found.
#
# Returns a Card object.
func _initiate_card_targeting(common_target_request: bool) -> Card:
	var target := owner.target_card
	# If we're using a common target for all the scripts
	# and a target has already been found once,
	# yhen we don't trigger new targetting arrow
	if not target or not common_target_request:
		# We wait a centisecond, to prevent the card's _input function from seeing
		# The double-click which started the script and immediately triggerring
		# the target completion
		yield(owner.get_tree().create_timer(0.1), "timeout")
		owner.initiate_targeting()
		# We wait until the targetting has been completed to continue
		yield(owner,"target_selected")
		target = owner.target_card
		if not common_target_request:
			owner.target_card = null
	else:
		# I don't understand it, but if I remove this timer
		# it breaks the yield from the caller
		# Replacing it with a pass or something simple doesn't work either
		yield(owner.get_tree().create_timer(0.1), "timeout")
	return(target)
