# Contains details about the way to seek through the game for the 
# Requested things to count. This is sent to ScriptPer to initiate it.
class_name perMessage
extends Reference

var per_seek: String
var script_owner # Card type, but cannot type to avoid cyclic dependency
var per_definitions: Dictionary
var trigger_card = null
var subjects := []
var found_things := 0 setget ,count_found_things

func _init(
		_per_seek: String,
		_script_owner,
		_per_definitions: Dictionary,
		_trigger_card = null,
		_subjects := []) -> void:
	per_seek = _per_seek
	script_owner = _script_owner
	per_definitions = _per_definitions
	trigger_card = _trigger_card
	subjects = _subjects

# Returns the amount of things the calling script is trying to count.
func count_found_things() -> int:
	var found_count := 0
	var per_discovery = cfc.script_per.new(self)
#	if not per_discovery.has_init_completed:
#		yield(per_discovery,"primed")
	found_count = per_discovery.return_per_count()
	return(found_count)

