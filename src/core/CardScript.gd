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
# The card which triggered this CardScript.
#
# It is typically `"self"` during manual execution,
# but is `"another"` card during signal-based execution
var trigger: Card
# The subject is typically a `Card` object
# in the future might be other things
var subject: Card
# The name of the method to call in the ScriptingEngine
# to implement this task
var task_name: String
# Storage for all details of the task definition
var properties : Dictionary
var signal_details : Dictionary
# Used by the ScriptingEngine to know if the task
# has finished processing targetting
var has_init_completed := false
# If true if this task is valid to run.
# A task is invalid to run if some limitation does not match.
var is_valid := true

# prepares the properties needed by the task to function.
func _init(card: Card,
		trigger_card: Card,
		details: Dictionary,
		script: Dictionary) -> void:
	var subject_seek
	# We store the card which executes this task
	owner = card
	# We store the card which triggered this task (typically via signal)
	trigger = trigger_card
	# We store all the task properties in our own dictionary
	properties = script
	# The function name to be called gets its own var
	signal_details = details
	# The function name to be called gets its own var
	task_name = get("name")
	# We test if this task is valid
	_check_limitations()
	print(task_name,is_valid)
	# We only seek targets if the task is valid
	if is_valid:
		# We discover which other card this task will affect, if any
		subject_seek =_find_subject()
		if subject_seek is GDScriptFunctionState: # Still seeking...
			subject_seek = yield(subject_seek, "completed")
		subject = subject_seek
	# We emit a signal when done so that our ScriptingEngine
	# knows we're ready to continue
	emit_signal("completed_init")
	has_init_completed = true

# Returns the specified property of the string.
# Also sets appropriate defaults when then property has not beend defined.
func get(property: String):
	var default
	match property:
		# Used when targeting is required for this effect
		# If set to false, then it will reset the targetting, and any
		# future scripts which require targetting will have to acquire a new
		# target
		# if set to true (default), following scripts
		# requiring target, will use the previous one.
		"common_target_request":
			default = true
		# Used when a script is triggered by a signal
		# Limits the execution depending on the triggering card. Options are:
		# * "self": Triggering card has to be the owner of the script
		# * "another": Triggering card has to not be the owner of the script
		# * "any" (default): Will execute regardless of the triggering card.
		"trigger":
			default = "any"
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
func _find_subject() -> Card:
	var subject_seek
	# If set to true, only one target will be seeked using with the arrow
	# If one is selected, then no other will be sought,
	# until the next common_target_request == false
	var common_target_request : bool = get("common_target_request")
	# Subject can be "self" or "target"
	# If the subject is "target", we initiate targetting from the owner card
	# to ask the player to find a appropriate target
	if get("subject") == "target":
		subject_seek = _initiate_card_targeting(common_target_request)
		if subject_seek is GDScriptFunctionState: # Still working.
			subject_seek = yield(subject_seek, "completed")
	# If the subject is "self", we return the _card_owner
	# of this CardScript
	elif get("subject") == "self":
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


# Ensures that all limitations requested by the script are respected
#
# Will set is_valid to false if any limitation does not match reality
func _check_limitations():
	# Here we check that the trigger matches the _request_ for trigger
	# A trigger which requires "another" card, should not trigger
	# when itself causes the effect.
	# For example, a card which rotates itself whenever another card
	# is rotated, should not automatically rotate when itself rotates.
	if get("trigger") == "self" and trigger != owner:
		is_valid = false
	if get("trigger") == "another" and trigger == owner:
		is_valid = false
	# Used when triggering off of rotating cards
	if get("limit_to_degrees") \
			and get("limit_to_degrees") != signal_details.get("degrees"):
		is_valid = false
	# Used when triggering off of flipping cards
	if get("limit_to_faceup") \
			and get("limit_to_faceup") != signal_details.get("is_faceup"):
		is_valid = false
	# The two check below, are used when triggerring off of moving between containers
	# If a limit has been requested, then a source field should also exist
	if get("limit_to_source") \
			and get("limit_to_source") != signal_details.get("source"):
		is_valid = false
	if get("limit_to_destination") \
			and get("limit_to_destination") != signal_details.get("destination"):
		is_valid = false


