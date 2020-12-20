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
var owner_card: Card
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
# This is passed from the [ScriptingEngine] and it stores a value retrieved
# using an ask_integer task. This might be used in this task
# when retrieving subjects if [SP].VALUE_RETRIEVE_INTEGER is used.
var stored_integer : int
# The amount of subjects card the script requested to modify
# We use this to compare against costs during dry_runs
var requested_subjects: int

# prepares the properties needed by the task to function.
func _init(card: Card,
		script: Dictionary,
		prev_subjects: Array,
		cost_dry_run: bool,
		sceng_stored_int) -> void:
	# We store the card which executes this task
	owner_card = card
	# We store all the task properties in our own dictionary
	properties = script
	stored_integer = sceng_stored_int
	# The function name to be called gets its own var
	task_name = get_property("name")
	if ((not cost_dry_run and not get_property(SP.KEY_IS_COST))
			# This is the typical spot we're checking
			# for non-cost optional confirmations.
			# The only time we're testing here during a cost-dry-run
			# is when its an "is_cost" task requiring targeting.
			# We want to avoid targeting and THEN ask for confirmation.
			# Non-targeting is_cost tasks are confirmed in the
			# ScriptingEngine loop
			or (cost_dry_run
			and get_property(SP.KEY_IS_COST)
			and get_property(SP.KEY_SUBJECT) == "target")):
		# If this task has been specified as optional
		# We check if the player confirms it, before looking for targets
		# We check for optional confirmations only during
		# The normal run (i.e. not in a cost dry-run)
		var confirm_return = CFUtils.confirm(
				properties,
				owner_card.card_name,
				task_name)
		if confirm_return is GDScriptFunctionState: # Still working.
			is_accepted = yield(confirm_return, "completed")
	# If any confirmation is accepted, then we only draw a target
	# if either the card is a cost and we're doing a cost-dry run,
	# or the card is not a cost and we're in the normal run
	if is_accepted and (not cost_dry_run
			or (cost_dry_run and get_property(SP.KEY_IS_COST))):
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
# A default value can also be passed directly, which is useful when
# ScriptingEngine has been extended by custom tasks.
func get_property(property: String, default = null):
	if default == null:
		default = SP.get_default(property)
	return(properties.get(property,default))


# Figures out what the subjects of this script is supposed to be.
#
# Returns a Card object if subjects is defined, else returns null.
func _find_subjects(prev_subjects := []) -> Card:
	var subjects_array := []
	# See SP.KEY_SUBJECT doc
	match get_property(SP.KEY_SUBJECT):
		# Ever task retrieves the subjects used in the previous task.
		# if the value "previous" is given to the "subjects" key,
		# it simple reuses the same ones.
		SP.KEY_SUBJECT_V_PREVIOUS:
			subjects_array = prev_subjects
		SP.KEY_SUBJECT_V_TARGET:
			if owner_card.targeting_arrow.target_dry_run_card:
				is_valid = SP.check_properties(
						owner_card.targeting_arrow.target_dry_run_card,
						properties,
						"subject")
				subjects_array.append(owner_card.targeting_arrow.target_dry_run_card)
				owner_card.targeting_arrow.target_dry_run_card = null
			else:
				var c = _initiate_card_targeting()
				if c is GDScriptFunctionState: # Still working.
					c = yield(c, "completed")
				is_valid = SP.check_properties(c, properties, "subject")
				subjects_array.append(c)
		SP.KEY_SUBJECT_V_BOARDSEEK:
			var subject_count = get_property(SP.KEY_SUBJECT_COUNT)
			if str(subject_count) == SP.KEY_SUBJECT_COUNT_V_ALL:
				# When the value is set to -1, the seek will retrieve as many
				# cards as it can find, since the subject_count will
				# never be 0
				subject_count = -1
			# If the script requests a number of subjects equal to a
			# player-inputed number, we retrieve the integer
			# stored from the previous ask_integer task.
			elif str(subject_count) == SP.VALUE_RETRIEVE_INTEGER:
				subject_count = stored_integer
			requested_subjects = subject_count
			for c in cfc.NMAP.board.get_all_cards():
				if SP.check_properties(c, properties, "seek"):
					subjects_array.append(c)
				subject_count -= 1
				if subject_count == 0:
					break
		SP.KEY_SUBJECT_V_TUTOR:
			# When we're tutoring for a subjects, we expect a
			# source CardContainer to have been provided.
			var subject_count = get_property(SP.KEY_SUBJECT_COUNT)
			if str(subject_count) == SP.KEY_SUBJECT_COUNT_V_ALL:
				subject_count = -1
			elif str(subject_count) == SP.VALUE_RETRIEVE_INTEGER:
				subject_count = stored_integer
			requested_subjects = subject_count
			for c in get_property(SP.KEY_SRC_CONTAINER).get_all_cards():
				if SP.check_properties(c, properties, "tutor"):
					subjects_array.append(c)
					subject_count -= 1
					if subject_count == 0:
						break
		SP.KEY_SUBJECT_V_INDEX:
			# When we're seeking for index, we expect a
			# source CardContainer to have been provided.
			var src_container: CardContainer = get_property(SP.KEY_SRC_CONTAINER)
			var index = get_property(SP.KEY_SUBJECT_INDEX)
			if str(index) == SP.KEY_SUBJECT_INDEX_V_TOP:
				# We use the CardContainer functions, inctead of the Piles ones
				# to allow this value to be used on Hand classes as well
				index = src_container.get_card_index(src_container.get_last_card())
			elif str(index) == SP.KEY_SUBJECT_INDEX_V_BOTTOM:
				index = src_container.get_card_index(src_container.get_first_card())
			elif str(index) == SP.VALUE_RETRIEVE_INTEGER:
				index = stored_integer
			# Just to prevent typos since we don't enforce integers on index
			elif not str(index).is_valid_integer():
				index = 0
			var subject_count = get_property(SP.KEY_SUBJECT_COUNT)
			# If the subject count is ALL, we retrieve as many cards as
			# possible after the specified index
			if str(subject_count) == SP.KEY_SUBJECT_COUNT_V_ALL:
				# This variable is used to only retrieve as many cards
				# Up to the maximum that exist below the specified index
				var adjust_count = index
				# If we're searching from the "top", then the card will
				# have the last index. In that case the maximum would be
				# the whole deck
				# we have to ensure the value is a string, as KEY_SUBJECT_INDEX
				# can contain either integers of strings
				if str(get_property(SP.KEY_SUBJECT_INDEX)) == SP.KEY_SUBJECT_INDEX_V_TOP:
					adjust_count = 0
				subject_count = src_container.get_card_count() - adjust_count
			elif str(subject_count) == SP.VALUE_RETRIEVE_INTEGER:
				subject_count = stored_integer
			requested_subjects = subject_count
			# If KEY_SUBJECT_COUNT is more than 1, we seek a number
			# of cards from this index equal to the amount
			for iter in range(subject_count):
				# Specifically when retrieving cards from the bottom
				# we move up the pile, instead of down.
				# This is useful for effects which mention something like:
				# "...the last X cards from the deck"
				if str(get_property(SP.KEY_SUBJECT_INDEX)) == SP.KEY_SUBJECT_INDEX_V_BOTTOM:
					if index + iter > src_container.get_card_count():
						break
					subjects_array.append(src_container.get_card(index + iter))
				# When retrieving cards from any other index,
				# we always move down the pile from the starting index point.
				else:
					if index - iter < 0:
						break
					subjects_array.append(src_container.get_card(index - iter))
		SP.KEY_SUBJECT_V_SELF:
			subjects_array.append(owner_card)
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
	yield(owner_card.get_tree().create_timer(0.1), "timeout")
	owner_card.targeting_arrow.initiate_targeting()
	# We wait until the targetting has been completed to continue
	yield(owner_card.targeting_arrow,"target_selected")
	var target = owner_card.targeting_arrow.target_card
	#owner_card.target_card = null
	return(target)
