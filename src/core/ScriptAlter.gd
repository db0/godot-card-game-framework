# This contains information about one specific alteration requested by the card
# automation
class_name ScriptAlter
extends ScriptObject

# Stores the details arg passed the signal to use for filtering
var trigger_details : Dictionary
# If true if this task has been confirmed to run by the player
# Only relevant for optional tasks (see [SP].KEY_IS_OPTIONAL)
var is_accepted := true


# Prepares the script_definition needed by the alteration to function and
# checks the ongoing task and its owner_card against defined filters.
func _init(
		alteration_script: Dictionary,
		trigger_card: Card,
		alterant_card: Card,
		task_details: Dictionary).(alterant_card, alteration_script, trigger_card) -> void:
	# The alteration name gets its own var
	script_name = get_property("filter_task")
	trigger_details = task_details
	if not SP.filter_trigger(
			alteration_script,
			trigger_card,
			owner_card,
			trigger_details):
		is_valid = false
	if is_valid:
		var confirm_return = CFUtils.confirm(
				script_definition,
				owner_card.card_name,
				script_name)
		if confirm_return is GDScriptFunctionState: # Still working.
			confirm_return = yield(confirm_return, "completed")
		is_valid = confirm_return
	if is_valid:
	# The script might require counting other cards.
		var ret =_find_subjects([], 0)
		if ret is GDScriptFunctionState: # Still working.
			ret = yield(ret, "completed")
	# We emit a signal when done so that our ScriptingEngine
	# knows we're ready to continue
	emit_signal("primed")
	is_primed = true
