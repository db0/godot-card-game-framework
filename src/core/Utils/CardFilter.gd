# Class to compare card properties against a specified filter
class_name CardFilter
extends Reference

# The property key for which to look in the provided card properties dict
var property: String
# The value against which to compare the value of the property
var filter
# The kind of comparison to perform
# Allowed values
# 'eq', 'ne'
# 'gt', 'ge', 'lt', 'le'
# Against numbers, will perform standard numerical comparison
# Against Arrays / Dictionaries, will perform standard numerical comparison against their size
var comparison: String
# If true, will compare integers as strings.
var compare_int_as_str := false
var custom_filter = null

func _init(
		_property: String,
		_value,
		_comparison := 'eq',
		_compare_int_as_str := false,
		_custom_filter = null) -> void:
	property = _property
	filter = _value
	comparison = _comparison
	compare_int_as_str = _compare_int_as_str
	custom_filter = _custom_filter
	if compare_int_as_str and not comparison in ['eq', 'ne']:
		printerr("ERROR:CardFilter: Cannot compare int as strings using comparison: %s. Defaulting to 'eq' instead" % [comparison])
		comparison = 'eq'
	if property in CardConfig.PROPERTIES_STRINGS and not comparison in ['eq', 'ne']:
		printerr("ERROR:CardFilter: Cannot use comparisons other than 'eq' and 'ne' on string property: %s. Defaulting to 'eq' instead" % [property])
		comparison = 'eq'
	if property in CardConfig.PROPERTIES_STRINGS and typeof(filter) != TYPE_STRING:
		printerr("WARN:CardFilter: Non-string filter '%s' requested for string property '%s'. This comparison would not be possible. '%s' will be converted to string for comparisons." % [filter, property, filter])
		filter = str(filter)
	if property in CardConfig.PROPERTIES_NUMBERS\
			and typeof(filter) == TYPE_STRING\
			and filter.is_valid_integer():
		printerr("WARN:CardFilter: String filter '%s' provided for number property '%s'. This comparison would not be possible. '%s' will be converted to int for comparisons." % [filter, property, filter])
		filter = int(filter)
		
# Takes the properties dictionary
# Returns true if the card matches this filter
# Else returns false
func check_card(card_properties: Dictionary) -> bool:
	var card_matches := false
	var prop_value = card_properties.get(property)
	if custom_filter:
		card_matches = custom_check(card_properties)
	elif typeof(filter) == TYPE_BOOL:
		# For now, we consider null value as false when comparison booleans
		# This allows the developer declare boolean properties only when they differ from the defalt.
		if typeof(prop_value) == TYPE_NIL:
			prop_value = false
		if typeof(prop_value) == TYPE_BOOL and prop_value == filter:
			card_matches = true
	# If the property is an array, we assume the player is trying to
	# match an element in it
	elif typeof(prop_value) == TYPE_ARRAY:
		if filter in prop_value and comparison == 'eq':
			card_matches = true
		elif not filter in prop_value and comparison == 'ne':
			card_matches = true
		elif not comparison in ['eq', 'ne'] and CFUtils.compare_numbers(
				prop_value.size(),
				int(filter),
				comparison):
			card_matches = true
	# A dictionary value is treated as an array, based on its keys
	elif typeof(prop_value) == TYPE_DICTIONARY:
		if prop_value.has(filter) and comparison == 'eq':
				card_matches = true
		elif not prop_value.has(filter) and comparison == 'ne':
				card_matches = true
		elif not comparison in ['eq', 'ne'] and CFUtils.compare_numbers(
				prop_value.size(),
				int(filter),
				comparison):
			card_matches = true
	elif typeof(prop_value) == typeof(filter)\
			and typeof(prop_value) == TYPE_INT\
			and not compare_int_as_str:
		if CFUtils.compare_numbers(
				prop_value,
				filter,
				comparison):
			card_matches = true
	elif typeof(prop_value) == typeof(filter)\
			and typeof(prop_value) == TYPE_STRING:
		if CFUtils.compare_strings(
				prop_value,
				filter,
				comparison):
			card_matches = true
	# We would only enter this, if the properties we compare are nominally strings
	# But one value is an int and the other is a string
	elif property in CardConfig.PROPERTIES_NUMBERS and not compare_int_as_str:
		var temp_prop_value = prop_value
		var temp_filter = filter
		if "VALUES_TREATED_AS_ZERO" in CardConfig:
			if typeof(temp_prop_value) == TYPE_STRING and temp_prop_value in CardConfig.VALUES_TREATED_AS_ZERO:
				temp_prop_value = 0
			if  typeof(temp_filter) == TYPE_STRING and temp_filter in CardConfig.VALUES_TREATED_AS_ZERO:
				temp_filter = 0
		# If temp values are still strings, then we check if they're valid integers to compare them
		if typeof(temp_prop_value) == TYPE_STRING and temp_prop_value.is_valid_integer():
			temp_prop_value = int(temp_prop_value)
		if typeof(temp_filter) == TYPE_STRING and temp_filter.is_valid_integer():
			temp_filter = int(temp_filter)
		if typeof(temp_prop_value) == TYPE_INT and  typeof(temp_filter) == TYPE_INT:
			if CFUtils.compare_numbers(
					temp_prop_value,
					temp_filter,
					comparison):
				card_matches = true
		# If one value is an int and the other is a string, and the developer has not configured
		# them accordingly in CardConfig.VALUES_TREATED_AS_ZERO, then we have to use a fallback
		# comparison as strings
		else:
			# for strings, we only allow 'eq' and 'ne' comparisons
			if comparison != 'ne':
				comparison = 'eq'
			if CFUtils.compare_strings(
					str(prop_value),
					str(filter),
					comparison):
				card_matches = true
	elif not typeof(prop_value) in [TYPE_ARRAY, TYPE_DICTIONARY] and CFUtils.compare_strings(
			str(prop_value),
			filter,
			comparison):
		card_matches = true
	return(card_matches)


# Extendable function to allow games to extend CardFilter with their own filters
# To enter this function, the custom_filter property has to be !null
# The value to put into it and how to use it is up each developer
# warning-ignore:unused_argument
func custom_check(card_properties: Dictionary) -> bool:
	return(false)
