# SP stands for "ScriptProperties".
#
# This dummy class exists to allow games to extend 
# the core [ScriptProperties] class provided by CGF, with their own requirements.
# 
# This is particularly useful when needing to adjust filters for the game's needs.
class_name SP
extends ScriptProperties

# A demonstration filter setup. If you specify this value in your
# card script definition for a filter, then it will look for the same key
# in the trigger dictionary. If it does not, or the value does not match
# then it will consider this trigger invalid for execution.
const FILTER_DEMONSTRATION = "is_demonstration"

# This call has been setup to call the original, and allow futher extension
# simply create new filter
static func filter_trigger(
		card_scripts,
		trigger_card,
		owner_card,
		trigger_details) -> bool:
	var is_valid := .filter_trigger(card_scripts,
		trigger_card,
		owner_card,
		trigger_details)
	# This is a sample setup of how you would setup a new filter. 
	# See ScriptProperties for more advanced filters
	if is_valid and card_scripts.get("filter" + FILTER_DEMONSTRATION) \
			and card_scripts.get("filter" + FILTER_DEMONSTRATION) != \
			trigger_details.get(FILTER_DEMONSTRATION):
		is_valid = false
	return(is_valid)
