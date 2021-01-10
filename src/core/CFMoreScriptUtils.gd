# More Card Gaming Framework ScriptingEngine Utilities
#
# This is a library of static functions we had to separate to avoid
# further cyclic dependencies
#
# This script needs to have no references to [SP] or [Card]
class_name CFMoreScriptUtils
extends Reference

# Handles looking for intensifiers of a current effect via the board state
#
# Returns the amount of things the script is trying to count.
static func count_per(
			per_seek: String,
			script_owner, # Card type, but cannot type to avoid cycic cep
			per_definitions: Dictionary,
			_trigger_card = null) -> int:
	var found_things := 0
	var per_discovery = cfc.script_per.new(
			script_owner,
			per_definitions,
			per_seek,
			_trigger_card)
#	if not per_discovery.has_init_completed:
#		yield(per_discovery,"completed_init")
	found_things = per_discovery.return_per_count()
	return(found_things)
