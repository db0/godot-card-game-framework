# This is a parent class containing the methods for lookup of subjects
# and script properties.
#
# It is typically never instanced directly.
class_name ScriptObject
extends Reference

# Sent when the _init() method has completed
# warning-ignore:unused_signal
signal primed


# The card which owns this Task
var owner_card: Card
# The subjects is typically a `Card` object
# in the future might be other things
var subjects := []
# The name of the method to call in the ScriptingEngine
# to implement this task
var script_name: String
# Storage for all details of the task definition
var script_definition : Dictionary
# Used by the ScriptingEngine to know if the task
# has finished processing targetting and optional confirmations
var is_primed := false
# If true if this task is valid to run.
# A task is invalid to run if some filter does not match.
var is_valid := true
# The amount of subjects card the script requested to modify
# We use this to compare against costs during dry_runs
#
# This is typically set during the _find_subjects() call
var requested_subjects: int
# The card which triggered this script.
var trigger_card: Card


# prepares the properties needed by the script to function.
func _init(card: Card, script: Dictionary, _trigger_card = null) -> void:
	# We store the card which executes this task
	owner_card = card
	# We store all the task properties in our own dictionary
	script_definition = script
	trigger_card = _trigger_card


# Returns the specified property of the string.
# Also sets appropriate defaults when then property has not beend defined.
# A default value can also be passed directly, which is useful when
# ScriptingEngine has been extended by custom tasks.
func get_property(property: String, default = null):
	if default == null:
		default = SP.get_default(property)
	return(script_definition.get(property,default))


# Figures out what the subjects of this script is supposed to be.
#
# Returns a Card object if subjects is defined, else returns null.
func _find_subjects(prev_subjects := [], stored_integer := 0) -> Array:
	var subjects_array := []
	# See SP.KEY_SUBJECT doc
	match get_property(SP.KEY_SUBJECT):
		# Ever task retrieves the subjects used in the previous task.
		# if the value "previous" is given to the "subjects" key,
		# it simple reuses the same ones.
		SP.KEY_SUBJECT_V_PREVIOUS:
			subjects_array = prev_subjects
			for c in subjects_array:
				if not SP.check_validity(c, script_definition, "subject"):
					is_valid = false
		SP.KEY_SUBJECT_V_TARGET:
			var c = _initiate_card_targeting()
			if c is GDScriptFunctionState: # Still working.
				c = yield(c, "completed")
			# If the target is null, it means the player pointed at nothing
			if c:
				is_valid = SP.check_validity(c, script_definition, "subject")
				subjects_array.append(c)
			else:
				# If the script required a target and it didn't find any
				# we consider it invalid
				is_valid = false
		SP.KEY_SUBJECT_V_BOARDSEEK:
			var subject_count = get_property(SP.KEY_SUBJECT_COUNT)
			if SP.VALUE_PER in str(subject_count):
				subject_count = count_per(
						get_property(SP.KEY_SUBJECT_COUNT),
						owner_card,
						get_property(get_property(SP.KEY_SUBJECT_COUNT)))
			elif str(subject_count) == SP.KEY_SUBJECT_COUNT_V_ALL:
				# When the value is set to -1, the seek will retrieve as many
				# cards as it can find, since the subject_count will
				# never be 0
				subject_count = -1
			# If the script requests a number of subjects equal to a
			# player-inputed number, we retrieve the integer
			# stored from the previous ask_integer task.
			elif str(subject_count) == SP.VALUE_RETRIEVE_INTEGER:
				subject_count = stored_integer
				if get_property(SP.KEY_IS_INVERTED):
					subject_count *= -1
			requested_subjects = subject_count
			for c in cfc.NMAP.board.get_all_cards():
				if SP.check_validity(c, script_definition, "seek"):
					subjects_array.append(c)
				subject_count -= 1
				if subject_count == 0:
					break
			if requested_subjects > 0\
					and subjects_array.size() < requested_subjects:
				is_valid = false
		SP.KEY_SUBJECT_V_TUTOR:
			# When we're tutoring for a subjects, we expect a
			# source CardContainer to have been provided.
			var subject_count = get_property(SP.KEY_SUBJECT_COUNT)
			if SP.VALUE_PER in str(subject_count):
				subject_count = count_per(
						get_property(SP.KEY_SUBJECT_COUNT),
						owner_card,
						get_property(get_property(SP.KEY_SUBJECT_COUNT)))
			elif str(subject_count) == SP.KEY_SUBJECT_COUNT_V_ALL:
				subject_count = -1
			elif str(subject_count) == SP.VALUE_RETRIEVE_INTEGER:
				subject_count = stored_integer
				if get_property(SP.KEY_IS_INVERTED):
					subject_count *= -1
			requested_subjects = subject_count
			for c in get_property(SP.KEY_SRC_CONTAINER).get_all_cards():
				if SP.check_validity(c, script_definition, "tutor"):
					subjects_array.append(c)
					subject_count -= 1
					if subject_count == 0:
						break
			if requested_subjects > 0\
					and subjects_array.size() < requested_subjects:
				is_valid = false
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
			elif str(index) == SP.KEY_SUBJECT_INDEX_V_RANDOM:
				index = src_container.get_card_index(src_container.get_random_card())
			elif str(index) == SP.VALUE_RETRIEVE_INTEGER:
				index = stored_integer
				if get_property(SP.KEY_IS_INVERTED):
					index *= -1
			# Just to prevent typos since we don't enforce integers on index
			elif not str(index).is_valid_integer():
				index = 0
			var subject_count = get_property(SP.KEY_SUBJECT_COUNT)
			# If the subject count is ALL, we retrieve as many cards as
			# possible after the specified index
			if SP.VALUE_PER in str(subject_count):
				subject_count = count_per(
						get_property(SP.KEY_SUBJECT_COUNT),
						owner_card,
						get_property(get_property(SP.KEY_SUBJECT_COUNT)))
			elif str(subject_count) == SP.KEY_SUBJECT_COUNT_V_ALL:
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
				if get_property(SP.KEY_IS_INVERTED):
					subject_count *= -1
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
			if requested_subjects > 0\
					and subjects_array.size() < requested_subjects:
				if get_property(SP.KEY_IS_COST):
					is_valid = false
				else:
					requested_subjects = subjects_array.size()
		SP.KEY_SUBJECT_V_TRIGGER:
			# We check, just to make sure we didn't mess up
			if trigger_card:
				is_valid = SP.check_validity(trigger_card, script_definition, "subject")
				subjects_array.append(trigger_card)
			else:
				print_debug("WARNING: Subject: trigger requested, but no trigger card passed")
		SP.KEY_SUBJECT_V_SELF:
			is_valid = SP.check_validity(owner_card, script_definition, "subject")
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
	owner_card.targeting_arrow.target_card = null
	#owner_card.target_card = null
	return(target)


# Handles looking for intensifiers of a current effect via the board state
#
# Returns the amount of things the script is trying to count.
static func count_per(
			per_seek: String,
			script_owner: Card,
			per_definitions: Dictionary,
			_trigger_card = null) -> int:
	var per_msg := perMessage.new(
			per_seek,
			script_owner,
			per_definitions,
			_trigger_card)
	return(per_msg.found_things)
