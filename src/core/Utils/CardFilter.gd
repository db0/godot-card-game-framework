# Class to compare card properties against a specified filter
class_name CardFilter
extends Reference

# The property key for which to look in the provided card properties dict
var property: String
# The value against which to compare the value of the property
var filter
# The kind of comparison to perform
var comparison: String
# If true, will compare integers as strings.
var compare_int_as_str := false

func _init(
		property: String,
		value,
		comparison := 'eq',
		compare_int_as_str := false) -> void:
	self.property = property
	self.filter = value
	self.comparison = comparison
	self.compare_int_as_str = compare_int_as_str
	if compare_int_as_str and not comparison in ['eq', 'ne']:
		printerr("ERROR: Cannot compare int as strings using comparison: %s. Defaulting to 'eq' instead" % [comparison])
		comparison = 'eq'


# Takes the properties dictionary
func check_card(card_properties: Dictionary) -> bool:
	var card_matches := false
	var prop_value = card_properties.get(property)
	# If the property is an array, we assume the player is trying to
	# match an element in it
	if typeof(prop_value) == TYPE_ARRAY:
		if filter in prop_value and comparison == 'eq':
				card_matches = true
		elif not filter in prop_value and comparison == 'ne':
				card_matches = true
	elif typeof(prop_value) == typeof(filter)\
			and typeof(prop_value) == TYPE_INT\
			and not compare_int_as_str:
		if CFUtils.compare_numbers(
				prop_value,
				filter,
				comparison):
			card_matches = true
	elif property in CardConfig.PROPERTIES_NUMBERS and not compare_int_as_str:
		# We consider values of strings in numbers as 0, for comparisons
		var temp_prop_value = prop_value
		var temp_filter = filter
		if "VALUES_TREATED_AS_ZERO" in CardConfig and str(prop_value) in CardConfig.VALUES_TREATED_AS_ZERO:
			temp_prop_value = 0
		if str(filter) == 'X':
			temp_filter = 0
		if CFUtils.compare_numbers(
				temp_prop_value,
				temp_filter,
				comparison):
			card_matches = true
	elif CFUtils.compare_strings(
			str(prop_value),
			str(filter),
			comparison):
		card_matches = true
	return(card_matches)
