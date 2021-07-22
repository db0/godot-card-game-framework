# A special LineEdit which compiles the text written
# into distinct [CVFilter] objects
#
# The filters use roughly the same syntax as
# [netrunnerdb](https://netrunnerdb.com/en/syntax)
# but have different criteria (see [criteria_map](#criteria_map))
class_name CVFilterLine
extends LineEdit

# Emited whenever the line text is changed. The deckbuilder grabs it and
# filters the cards based on the compiled filters sent with it
signal filters_changed(filters)

# Defines the available criteria for this game's filters.
#
# Developers can customize this dictionary based on each game's card properties
# Each character key defined here, corresponds to one property and when
# inserted as the criteria, will check the expression against that property
export var criteria_map = {
	'a': 'Abilities',
	't': 'Type',
	'g': 'Tags',
	'r': 'Requirements',
	'c': 'Cost',
	'p': 'Power',
}

# Used for checking if the filter is freeform, or regex
var _filter_parse = RegEx.new()


func _ready() -> void:
	# This variable holds a regex group to check for criteria, based on the
	# keys of criteria_map
	var criteria_regex_group := ''
	# This variable will hold the criteria legend
	var criteria_syntax_help := ''
	for criterion in criteria_map:
		criteria_regex_group += criterion
		criteria_syntax_help +=\
				criterion.lstrip('_').capitalize()\
				+ " - "\
				+ criteria_map[criterion].lstrip('_').capitalize()\
				+ '\n'
	var filter_parse_regex = "^([" + criteria_regex_group + "])?([:!><])(\\w+)"
	_filter_parse.compile(filter_parse_regex)
	$Syntax/Label.text =\
			"Syntax\n"\
			+ "-------\n"\
			+ "Criteria:\n"\
			+ criteria_syntax_help\
			+ "default - Name\n"\
			+ "-------\n"\
			+ "Operators:\n"\
			+ ": - equals\n"\
			+ "! - not equals\n"\
			+ "< - less than\n"\
			+ "> - greater than\n"
	# warning-ignore:return_value_discarded
	connect("text_changed", self, "on_text_changed")
	# warning-ignore:return_value_discarded
	connect("mouse_entered", self, "_on_FilterLine_mouse_entered")
	# warning-ignore:return_value_discarded
	connect("mouse_exited", self, "_on_FilterLine_mouse_exited")

func _process(_delta: float) -> void:
	if $Syntax.visible:
		$Syntax.rect_position \
				= get_global_mouse_position() + Vector2(10,0)


# Fired whenever the text of the LineEdit changes. It compiles the filters
# Then fires a signal which is caught by the deckbuilder.
func on_text_changed(new_text: String) -> void:
	var filters = compile_filters(new_text)
	emit_signal("filters_changed", filters)


# Function which takes as input a string, and then returns an array of
# DBFilters.
func compile_filters(line_text: String) -> Array:
	# Our filter string is always split on spaces
	# We don't support spaces in expressions yet.
	var filter_entries = line_text.to_lower().split(' ')
	var filters := []
	for filter in filter_entries:
		var filter_entry := CVFilter.new()
		var regex_result = _filter_parse.search(filter)
		# If the filter matches the conditiona-operator-expression format
		# we use the regex groups to populate the DBFilter object
		if regex_result:
			# if a specific conditional was not used, we default to the card name
			if not regex_result.get_string(1):
				filter_entry.property = "Name"
			else:
				filter_entry.property = criteria_map[regex_result.get_string(1)]
			filter_entry.operator = regex_result.get_string(2)
			filter_entry.expression = regex_result.get_string(3)
		# If the regex does not match, we treat the filter as a pure string
		else:
			filter_entry.property = "Name"
			filter_entry.operator = ':'
			filter_entry.expression  = filter
		filters.append(filter_entry)
	return(filters)


# Regenerates and returns the current filters based on the existing text
func get_active_filters() -> Array:
	return(compile_filters(text))


# Displays the syntax help
func _on_FilterLine_mouse_entered() -> void:
	$Syntax.visible = true


# Hides the syntax help
func _on_FilterLine_mouse_exited() -> void:
	$Syntax.visible = false
