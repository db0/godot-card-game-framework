# This contains information about one specific task requested by the card
# automation
#
# It also contains methods to return properties of the task and to find
# the required objects in the game
class_name ScriptTask
extends Reference

# Sent when the _init() method has completed
signal completed_init


# The card which owns this Task
var owner: Card
# The card which triggered this Task.
#
# It is typically `"self"` during manual execution,
# but is `"another"` card during signal-based execution
var trigger: Card
# The subjects is typically a `Card` object
# in the future might be other things
var subjects := []
# The name of the method to call in the ScriptingEngine
# to implement this task
var task_name: String
# Storage for all details of the task definition
var properties : Dictionary
# Stores the details arg passed the signal to use for filtering
var signal_details : Dictionary
# Used by the ScriptingEngine to know if the task
# has finished processing targetting
var has_init_completed := false
# If true if this task is valid to run.
# A task is invalid to run if some filter does not match.
var is_valid := true
# If true if this task has been confirmed to run by the player
# Only relevant for optional tasks (see [SP].KEY_IS_OPTIONAL)
var is_accepted := true

# prepares the properties needed by the task to function.
func _init(card: Card,
		script: Dictionary,
		prev_subjects: Array,
		cost_dry_run: bool) -> void:
	# We store the card which executes this task
	owner = card
	# We store all the task properties in our own dictionary
	properties = script
	# The function name to be called gets its own var
	task_name = get("name")
	if ((not cost_dry_run and not get(SP.KEY_IS_COST))
			# This is the typical spot we're checking 
			# for non-cost optional confirmations.
			# The only time we're testing here during a cost-dry-run
			# is when its an "is_cost" task requiring targeting.
			# We want to avoid targeting and THEN ask for confirmation.
			# Non-targeting is_cost tasks are confirmed in the 
			# ScriptingEngine loop
			or (cost_dry_run
			and get(SP.KEY_IS_COST)
			and get(SP.KEY_SUBJECT) == "target")):
		# If this task has been specified as optional
		# We check if the player confirms it, before looking for targets
		# We check for optional confirmations only during
		# The normal run (i.e. not in a cost dry-run)
		var confirm_return = CFUtils.confirm(
				properties,
				owner.card_name,
				task_name)
		if confirm_return is GDScriptFunctionState: # Still working.
			is_accepted = yield(confirm_return, "completed")
	# If any confirmation is accepted, then we only draw a target
	# if either the card is a cost and we're doing a cost-dry run,
	# or the card is not a cost and we're in the normal run
	if is_accepted and (not cost_dry_run
			or (cost_dry_run and get(SP.KEY_IS_COST))):
	# We discover which other card this task will affect, if any
		var ret =_find_subjects(prev_subjects)
		if ret is GDScriptFunctionState: # Still working.
			ret = yield(ret, "completed")
	#print_debug(str(subjects), str(cost_dry_run))
	# We emit a signal when done so that our ScriptingEngine
	# knows we're ready to continue
	emit_signal("completed_init")
	has_init_completed = true


# Returns the specified property of the string.
# Also sets appropriate defaults when then property has not beend defined.
func get(property: String):
	return(properties.get(property,SP.get_default(property)))


# Figures out what the subjects of this script is supposed to be.
#
# Returns a Card object if subjects is defined, else returns null.
func _find_subjects(prev_subjects := []) -> Card:
	var subjects_array := []
	# See SP.KEY_SUBJECT doc
	match get(SP.KEY_SUBJECT):
		# Ever task retrieves the subjects used in the previous task.
		# if the value "previous" is given to the "subjects" key,
		# it simple reuses the same ones.
		SP.KEY_SUBJECT_V_PREVIOUS:
			subjects_array = prev_subjects
		SP.KEY_SUBJECT_V_TARGET:
			if owner.target_dry_run_card:
				is_valid = SP.check_properties(
						owner.target_dry_run_card,
						properties,
						"subject")
				subjects_array.append(owner.target_dry_run_card)
				owner.target_dry_run_card = null
			else:
				var c = _initiate_card_targeting()
				if c is GDScriptFunctionState: # Still working.
					c = yield(c, "completed")
				is_valid = SP.check_properties(c, properties, "subject")
				subjects_array.append(c)
		SP.KEY_SUBJECT_V_BOARDSEEK:
			for c in cfc.NMAP.board.get_all_cards():
				if SP.check_properties(c, properties, "seek"):
					subjects_array.append(c)
		SP.KEY_SUBJECT_V_TUTOR:
			# When we're tutoring for a subjects, we expect a
			# source CardContainer to have been provided.
			for c in get(SP.KEY_SRC_CONTAINER).get_all_cards():
				if SP.check_properties(c, properties, "tutor"):
					subjects_array.append(c)
					break
		SP.KEY_SUBJECT_V_INDEX:
			# When we're seeking for index, we expect a
			# source CardContainer to have been provided.
			var index: int = get(SP.KEY_SUBJECT_INDEX)
			var src_container: CardContainer = get(SP.KEY_SRC_CONTAINER)
			subjects_array.append(src_container.get_card(index))
		SP.KEY_SUBJECT_V_SELF:
			subjects_array.append(owner)
		_:
			subjects_array = []
	subjects = subjects_array
	return(subjects_array)


# Handles initiation of target seeking.
# and yields until it's found.
#
# Returns a Card object.
func _initiate_card_targeting() -> Card:
	# We wait a centisecond, to prevent the card's _input function from seeing
	# The double-click which started the script and immediately triggerring
	# the target completion
	yield(owner.get_tree().create_timer(0.1), "timeout")
	owner.initiate_targeting()
	# We wait until the targetting has been completed to continue
	yield(owner,"target_selected")
	var target = owner.target_card
	#owner.target_card = null
	return(target)
