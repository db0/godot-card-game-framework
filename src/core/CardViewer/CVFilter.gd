# This class stores a filter for the Card Viewer 
# and is responsible for doing comparisons of expressions
class_name CVFilter
extends Reference

# The property of a card this filter is checking against
var property: String setget set_property
# an operator is either:
# * : – equals
# * ! – different from
# * < – less than
# * > – more than
var operator: String setget set_operator
# The expression can either be a integer, or a regex
var expression setget set_expression
# The type of filter this is. It will only be an int, if the 
# property being compared is a number
var type := "regex"


# Setter for property var
func set_property(value) -> void:
	property = value
	if property in CardConfig.PROPERTIES_NUMBERS:
		type = "int"


# Setter for operator var
func set_operator(value) -> void:
	if value == ':':
		operator = 'eq'
	if value == '!':
		operator = 'ne'
	if value == '>':
		operator = 'gt'
	if value == '<':
		operator = 'lt'


# Setter for expression var
func set_expression(value: String) -> void:
	if type == "int" and value.is_valid_integer():
		expression = int(value)
	else:
		var string_regex := RegEx.new()
# warning-ignore:return_value_discarded
		string_regex.compile(value)
		expression  = string_regex


# Compares the provided DBListCardObject against this filter
#
# Returns true if this filter matches the card_properties, else returns false
func assess_card_object(card_object: CVListCardObject) -> bool:
	var card_match = true
	var prop_value
	# The card's name is not in the card properties, but in a special var
	if property == "Name":
		prop_value = card_object.card_name
	else:
		prop_value = card_object.card_properties.get(property)
	# we allow number properties to get string values to give flexibility to the 
	# designer, but we need to check for it to make proper comparisons
	if property in CardConfig.PROPERTIES_NUMBERS\
			and (typeof(prop_value) == TYPE_INT or typeof(prop_value) == TYPE_REAL):
		if not CFUtils.compare_numbers(prop_value,expression,operator):
			card_match = false
	# For arrays, we want to return false, if none of the tags match the filter
	# If a single tag matches, we're good.
	elif property in CardConfig.PROPERTIES_ARRAYS:
		card_match = false
		for pvalue in prop_value:
			if compare_regex(pvalue.to_lower()):
				card_match = true
				break
	else:
		if not compare_regex(prop_value.to_lower()):
			card_match = false
	return(card_match)


# Compares regex based on the operator provided to this filter
func compare_regex(value) -> bool:
	var regex_match = true
	if not expression.search(value) and operator == 'eq':
		regex_match = false
	if expression.search(value) and operator == 'ne':
		regex_match = false
	return(regex_match)
