# This class is responsible for looking up the amount of per count
# that has been requested in a [ScripTask](#ScriptTask)
class_name ScriptPer
extends ScriptObject


# prepares the properties needed by the task to function.
func _init(per_msg: perMessage).(
		per_msg.script_owner, 
		per_msg.per_definitions, 
		per_msg.trigger_object) -> void:
	# The name of the type of per we're seeking gets its own var
	script_name = per_msg.per_seek
	if get_property(SP.KEY_ORIGINAL_PREVIOUS):
		prev_subjects = per_msg.prev_subjects
	else:
		prev_subjects = per_msg.subjects
	var ret = _find_subjects()
	if ret is GDScriptFunctionState: # Still working.
		ret = yield(ret, "completed")
	# We emit a signal when done so that our ScriptingEngine
	# knows we're ready to continue
	emit_signal("primed")
	is_primed = true


# Goes through the subjects specied for this per calculation
# and counts the number of "things" requested
func return_per_count() -> int:
	var ret: int
	match script_name:
		SP.KEY_PER_TOKEN:
			ret = _count_tokens()
		SP.KEY_PER_PROPERTY:
			ret = _count_property()
		# These two keys simply count the number
		# of subjects found
		SP.KEY_PER_TUTOR,SP.KEY_PER_BOARDSEEK:
			if get_property(SP.KEY_COUNT_UNIQUE):
				ret = _count_unique()
			else:
				ret = subjects.size()
		SP.KEY_PER_COUNTER:
			ret = _count_counter()
		_:
			ret = _count_custom()
	if get_property(SP.KEY_IS_INVERTED):
		ret *= -1
	return(ret)


# Do something per token count
func _count_tokens() -> int:
	var ret := 0
	for card in subjects:
		ret = card.tokens.get_token_count(get_property(SP.KEY_TOKEN_NAME))
	return(ret)


# Do something per property amount
func _count_property() -> int:
	var ret := 0
	# Only number properties can be used for per
	if get_property(SP.KEY_PROPERTY_NAME) in CardConfig.PROPERTIES_NUMBERS:
		for card in subjects:
			# We allow properties which are specified as numbers
			# To have string values. But we cannot accumulate them, so we ignore
			# those values
			var value = card.get_property(get_property(SP.KEY_PROPERTY_NAME))
			if typeof(value) == TYPE_INT:
				ret += value
	return(ret)


# Do something per counter amount
func _count_counter() -> int:
	var ret: int
	var counter_name = get_property(SP.KEY_COUNTER_NAME)
	ret = cfc.NMAP.board.counters.get_counter(counter_name, owner)
	return(ret)


# Do something per unique card in the gathered subjects
func _count_unique() -> int:
	var unique_subjects := []
	for c in subjects:
		if not c.canonical_name in unique_subjects:
			unique_subjects.append(c.canonical_name)
	return unique_subjects.size()

# Overridable function for scripts extending this class
# to add their own methods
func _count_custom() -> int:
	return(1)
