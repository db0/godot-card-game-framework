# This contains information about one specific task requested by the card
# automation
#
# It also contains methods to return properties of the task and to find
# the required objects in the game
class_name ScriptTask
extends ScriptObject

# Stores the details arg passed the signal to use for filtering
var signal_details : Dictionary
# If true if this task has been confirmed to run by the player
# Only relevant for optional tasks (see [SP].KEY_IS_OPTIONAL)
var is_accepted := true
var is_skipped := false


# prepares the script_definition needed by the task to function.
func _init(owner_card: Card,
		script: Dictionary,
		prev_subjects: Array,
		cost_dry_run: bool,
		sceng_stored_int,
		_trigger_card,
		trigger_details).(owner_card, script, _trigger_card) -> void:
	# The function name to be called gets its own var
	script_name = get_property("name")
	if not SP.filter_trigger(
			script,
			trigger_card,
			owner_card,
			trigger_details):
		is_skipped = true
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
				script_definition,
				owner_card.card_name,
				script_name)
		if confirm_return is GDScriptFunctionState: # Still working.
			is_accepted = yield(confirm_return, "completed")
	# If any confirmation is accepted, then we only draw a target
	# if either the card is a cost and we're doing a cost-dry run,
	# or the card is not a cost and we're in the normal run
	if not is_skipped and is_accepted and (not cost_dry_run
			or (cost_dry_run and get_property(SP.KEY_IS_COST))):
	# We discover which other card this task will affect, if any
		var ret =_find_subjects(prev_subjects, sceng_stored_int)
		if ret is GDScriptFunctionState: # Still working.
			ret = yield(ret, "completed")
	#print_debug(str(subjects), str(cost_dry_run))
	# We emit a signal when done so that our ScriptingEngine
	# knows we're ready to continue
	emit_signal("completed_init")
	has_init_completed = true
#	print_debug("skipped: " + str(is_skipped) +  " valid: " + str(is_valid))

