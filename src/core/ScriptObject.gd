# This is a parent class containing the methods for lookup of subjects
# and script properties.
#
# It is typically never instanced directly.
class_name ScriptObject
extends Reference

# Sent when the _init() method has completed
# warning-ignore:unused_signal
signal primed


# The object which owns this Task
var owner
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
var trigger_object: Node
# Stores the subjects discovered by the task previous to this one
var prev_subjects := []


# prepares the properties needed by the script to function.
func _init(_owner, script: Dictionary, _trigger_object = null) -> void:
	# We store the card which executes this task
	owner = _owner
	# We store all the task properties in our own dictionary
	script_definition = script
	trigger_object = _trigger_object
	parse_replacements()


# Returns the specified property of the string.
# Also sets appropriate defaults when then property has not beend defined.
# A default value can also be passed directly, which is useful when
# ScriptingEngine has been extended by custom tasks.
func get_property(property: String, default = null):
	if default == null:
		default = SP.get_default(property)
#	var found_value = lookup_script_property(script_definition.get(property,default))
	return(script_definition.get(property,default))
#
#
#func lookup_script_property(found_value):
#	if typeof(found_value) == TYPE_DICTIONARY and found_value.has("lookup_property"):
#		var lookup_property = found_value.get("lookup_property")
#		var value_key = found_value.get("value_key")
#		var default_value = found_value.get("default")
#		var owner_name = owner.name
#		if "canonical_name" in owner:
#			owner_name = owner.canonical_name
#		var value = cfc.card_definitions[owner.canonical_name]\
#				.get(lookup_property, {}).get(value_key, default_value)
#		if found_value.get("is_inverted"):
#			value *= 1
#		return(value)
#	return(found_value)


# Figures out what the subjects of this script is supposed to be.
#
# Returns a Card object if subjects is defined, else returns null.
func _find_subjects(stored_integer := 0) -> Array:
	var subjects_array := []
	# See SP.KEY_SUBJECT doc
	match get_property(SP.KEY_SUBJECT):
		# Ever task retrieves the subjects used in the previous task.
		# if the value "previous" is given to the "subjects" key,
		# it simple reuses the same ones.
		SP.KEY_SUBJECT_V_PREVIOUS:
			if get_property(SP.KEY_FILTER_EACH_REVIOUS_SUBJECT):
				# We still check all previous subjects to check that they match the filters
				# If not, we remove them from the subject list
				for c in prev_subjects:
					if SP.check_validity(c, script_definition, "subject"):
						subjects_array.append(c)
				if subjects_array.size() == 0:
					is_valid = false
			# With this approach, if any of the previous subjects doesn't
			# match the filter, the whole task is considered invalid.
			# But the subjects lists remains intact
			else:
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
			subjects_array = _boardseek_subjects(stored_integer)
		SP.KEY_SUBJECT_V_TUTOR:
			subjects_array = _tutor_subjects(stored_integer)
		SP.KEY_SUBJECT_V_INDEX:
			subjects_array = _index_seek_subjects(stored_integer)
		SP.KEY_SUBJECT_V_TRIGGER:
			# We check, just to make sure we didn't mess up
			if trigger_object:
				is_valid = SP.check_validity(trigger_object, script_definition, "subject")
				subjects_array.append(trigger_object)
			else:
				print_debug("WARNING: Subject: trigger requested, but no trigger card passed")
		SP.KEY_SUBJECT_V_SELF:
			is_valid = SP.check_validity(owner, script_definition, "subject")
			subjects_array.append(owner)
		_:
			subjects_array = cfc.ov_utils.get_subjects(
					get_property(SP.KEY_SUBJECT), stored_integer)
			for c in subjects_array:
				if not SP.check_validity(c, script_definition, "subject"):
					is_valid = false
	if get_property(SP.KEY_NEEDS_SELECTION):
		var selection_count = get_property(SP.KEY_SELECTION_COUNT)
		var selection_type = get_property(SP.KEY_SELECTION_TYPE)
		var selection_optional = get_property(SP.KEY_SELECTION_OPTIONAL)
		if get_property(SP.KEY_SELECTION_IGNORE_SELF):
			subjects_array.erase(owner)
		var select_return = cfc.ov_utils.select_card(
				subjects_array, selection_count, selection_type, selection_optional, cfc.NMAP.board)
		# In case the owner card is still focused (say because script was triggered
		# on double-click and card was not moved
		# Then we need to ensure it's unfocused
		# Otherwise its z-index will make it draw on top of the popup.
		if owner as Card:
			if owner.state in [Card.CardState.FOCUSED_IN_HAND]:
				# We also reorganize the whole hand to avoid it getting
				# stuck like this.
				for c in owner.get_parent().get_all_cards():
					c.interruptTweening()
					c.reorganize_self()
		if select_return is GDScriptFunctionState: # Still working.
			select_return = yield(select_return, "completed")
			# If the return is not an array, it means that the selection
			# was cancelled (either because there were not enough cards
			# or because the player pressed cancel
			# in which case we consider the task invalid
			if typeof(select_return) == TYPE_ARRAY:
				subjects_array = select_return
			else:
				is_valid = false
	subjects = subjects_array
	return(subjects_array)


func _boardseek_subjects(stored_integer: int) -> Array:
	var subjects_array := []
	var subject_count = get_property(SP.KEY_SUBJECT_COUNT)
	if SP.VALUE_PER in str(subject_count):
		subject_count = count_per(
				get_property(SP.KEY_SUBJECT_COUNT),
				owner,
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
	var subject_list := sort_subjects(cfc.NMAP.board.get_all_scriptables())
	for c in subject_list:
		if SP.check_validity(c, script_definition, "seek"):
			subjects_array.append(c)
			subject_count -= 1
			if subject_count == 0:
				break
	if requested_subjects > 0\
			and subjects_array.size() < requested_subjects:
		is_valid = false
	return(subjects_array)

func _tutor_subjects(stored_integer: int) -> Array:
	var subjects_array := []
	# When we're tutoring for a subjects, we expect a
	# source CardContainer to have been provided.
	var subject_count = get_property(SP.KEY_SUBJECT_COUNT)
	if SP.VALUE_PER in str(subject_count):
		subject_count = count_per(
				get_property(SP.KEY_SUBJECT_COUNT),
				owner,
				get_property(get_property(SP.KEY_SUBJECT_COUNT)))
	elif str(subject_count) == SP.KEY_SUBJECT_COUNT_V_ALL:
		subject_count = -1
	elif str(subject_count) == SP.VALUE_RETRIEVE_INTEGER:
		subject_count = stored_integer
		if get_property(SP.KEY_IS_INVERTED):
			subject_count *= -1
	requested_subjects = subject_count
	var subject_list := sort_subjects(
			cfc.NMAP[get_property(SP.KEY_SRC_CONTAINER)].get_all_cards())
	for c in subject_list:
		if SP.check_validity(c, script_definition, "tutor"):
			subjects_array.append(c)
			subject_count -= 1
			if subject_count == 0:
				break
	if requested_subjects > 0:
		if get_property(SP.KEY_UP_TO):
			if subjects_array.size() < 1:
				is_valid = false
		else:
			if subjects_array.size() < requested_subjects:
				is_valid = false
	return(subjects_array)


func _index_seek_subjects(stored_integer: int) -> Array:
	var subjects_array := []
	# When we're seeking for index, we expect a
	# source CardContainer to have been provided.
	var src_container: CardContainer = cfc.NMAP[get_property(SP.KEY_SRC_CONTAINER)]
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
				owner,
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
	owner.targeting_arrow.initiate_targeting()
	# We wait until the targetting has been completed to continue
	yield(owner.targeting_arrow,"target_selected")
	var target = owner.targeting_arrow.target_object
	owner.targeting_arrow.target_object = null
	#owner_card.target_object = null
	return(target)


# Handles looking for intensifiers of a current effect via the board state
#
# Returns the amount of things the script is trying to count.
static func count_per(
			per_seek: String,
			script_owner: Card,
			per_definitions: Dictionary,
			_trigger_object = null) -> int:
	var per_msg := perMessage.new(
			per_seek,
			script_owner,
			per_definitions,
			_trigger_object)
	return(per_msg.found_things)


# Sorts the subjects list
# according to the directives in the following three keys
# * [KEY_SORT_BY](ScriptProperties#KEY_SORT_BY)
# * [KEY_SORT_NAME](ScriptProperties#KEY_SORT_NAME)
# * [KEY_SORT_DESCENDING](ScriptProperties#KEY_SORT_DESCENDING)
func sort_subjects(subject_list: Array) -> Array:
	var sorted_subjects := []
	var sort_by : String = get_property(SP.KEY_SORT_BY)
	if sort_by == "node_index":
		sorted_subjects = subject_list.duplicate()
	elif sort_by == "random":
		sorted_subjects = subject_list.duplicate()
		CFUtils.shuffle_array(sorted_subjects)
	# If the player forgot to fill in the SORT_NAME, we don't change the sort.
	# But we put out a warning instead
	elif not get_property(SP.KEY_SORT_NAME):
		print_debug("Warning: sort_by " + sort_by + ' requested '\
				+ 'but key ' + SP.KEY_SORT_NAME + ' is missing!')
	else:
		# I don't know if it's going to be a token name
		# or a property name, so I name the variable accordingly.
		var thing : String = get_property(SP.KEY_SORT_NAME)
		var sorting_list := []
		if sort_by == "property":
			for c in subject_list:
				# We create a list of dictionaries
				# because we cannot tell the sort_custom()
				# method what to search for
				sorting_list.append({
					"card": c,
					"value": c.get_property(thing)
				})
		if sort_by == "token":
			for c in subject_list:
				sorting_list.append({
					"card": c,
					"value": c.tokens.get_token_count(thing)
				})
		sorting_list.sort_custom(CFUtils,'sort_by_card_field')
		# Once we've sorted the items, we put just the card objects
		# in a new list, which we return to the player.
		for d in sorting_list:
			sorted_subjects.append(d.card)
	# If we want a descending list, we invert the subject list
	if get_property(SP.KEY_SORT_DESCENDING):
		sorted_subjects.invert()
	return(sorted_subjects)


# Goes through the provided scripts and replaces certain keyword values
# with variables retireved from specified location.
#
# This allows us for example to filter cards sought based on the properties
# of the card running the script.
func parse_replacements() -> void:
	# We need a deep copy because of all the nested dictionaries
	var wip_definitions := script_definition.duplicate(true)
	for key in wip_definitions:
		# We have to go through all the state filters
		# Because they have variable names
		if SP.FILTER_STATE in key:
			var state_filters_array : Array =  wip_definitions[key]
			for state_filters in state_filters_array:
				for filter in state_filters:
					# This branch checks for replacements for
					# filter_properties
					# We have to go to each dictionary for filter_properties
					# filters and check all values if they contain a
					# relevant keyword
					if SP.FILTER_PROPERTIES in filter:
						var property_filters = state_filters[filter]
						for property in property_filters:
							if str(property_filters[property]) in\
									[SP.VALUE_COMPARE_WITH_OWNER,
									SP.VALUE_COMPARE_WITH_TRIGGER]:
								var card: Card
								if str(property_filters[property]) ==\
										SP.VALUE_COMPARE_WITH_OWNER:
									card = owner
								else:
									card = trigger_object
								# Card name is always grabbed from
								# Card.canonical_name
								if property == "Name":
									property_filters[property] =\
											card.canonical_name
								else:
									property_filters[property] =\
											card.get_property(property)
					# This branch checks for replacements for
					# filter_tokens
					# We have to go to each dictionary for filter_tokens
					# filters and check all values if they contain a
					# relevant keyword
					if SP.FILTER_TOKENS in filter:
						var token_filters_array = state_filters[filter]
						for token_filters in token_filters_array:
							if str(token_filters.get(SP.FILTER_COUNT)) in\
									[SP.VALUE_COMPARE_WITH_OWNER,
									SP.VALUE_COMPARE_WITH_TRIGGER]:
								var card: Card
								if str(token_filters.get(SP.FILTER_COUNT)) ==\
										SP.VALUE_COMPARE_WITH_OWNER:
									card = owner
								else:
									card = trigger_object
								var owner_token_count :=\
										card.tokens.get_token_count(
										token_filters["filter_" + SP.KEY_TOKEN_NAME])
								token_filters[SP.FILTER_COUNT] =\
										owner_token_count
					if SP.FILTER_DEGREES in filter:
						if str(state_filters[filter]) == SP.VALUE_COMPARE_WITH_OWNER:
							var card: Card = owner
							state_filters[filter] = card.card_rotation
						if str(state_filters[filter]) == SP.VALUE_COMPARE_WITH_TRIGGER:
							var card: Card = trigger_object
							state_filters[filter] = card.card_rotation
					if SP.FILTER_FACEUP in filter:
						if str(state_filters[filter]) == SP.VALUE_COMPARE_WITH_OWNER:
							var card: Card = owner
							state_filters[filter] = card.is_faceup
						if str(state_filters[filter]) == SP.VALUE_COMPARE_WITH_TRIGGER:
							var card: Card = trigger_object
							state_filters[filter] = card.is_faceup
					if SP.FILTER_PARENT in filter:
						if str(state_filters[filter]) == SP.VALUE_COMPARE_WITH_OWNER:
							var card: Card = owner
							state_filters[filter] = card.get_parent()
						if str(state_filters[filter]) == SP.VALUE_COMPARE_WITH_TRIGGER:
							var card: Card = trigger_object
							state_filters[filter] = card.get_parent()
	script_definition = wip_definitions
