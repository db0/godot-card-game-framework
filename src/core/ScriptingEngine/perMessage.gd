# Contains details about the way to seek through the game for the 
# Requested things to count. This is sent to ScriptPer to initiate it.
class_name perMessage
extends Reference

var per_seek: String
var script_owner # Card type, but cannot type to avoid cyclic dependency
var per_definitions: Dictionary
var trigger_object = null
# This is the subject selected by the task from which this per message
# originates
var subjects := []
# These are the prev_subject which were sent to the task 
# from which this per message originates
var prev_subjects := []
var found_things := 0 setget ,count_found_things

# Why do we send each element isolated, instead of just sending the ScriptTask object
# from which we extract them directly, I hear you ask?  Because this class
# can also be generated as part of a ScriptObject's subject methods, which does not utilize
# a ScriptTask object
func _init(
		_per_seek: String,
		_script_owner,
		_per_definitions: Dictionary,
		_trigger_object = null,
		_subjects := [],
		_prev_subjects := []) -> void:
	per_seek = _per_seek
	script_owner = _script_owner
	per_definitions = _per_definitions
	trigger_object = _trigger_object
	subjects = _subjects
	prev_subjects = _prev_subjects

# Returns the amount of things the calling script is trying to count.
func count_found_things() -> int:
	var found_count := 0
	var multiplier = per_definitions.get(
			"multiplier", 1)
	var divider = per_definitions.get(
			"divider", 1)
	# This key is added/removed from the total count
	var modifier = per_definitions.get(
			"modifier", 0)
	var per_discovery = cfc.script_per.new(self)
#	if not per_discovery.has_init_completed:
#		yield(per_discovery,"primed")
	found_count = per_discovery.return_per_count() + modifier
	# We have to divide before we multiply because we fall back into an ingeger
	# This allows us to code things like "for every 4 cards in the deck, do 2 damage"
	# and return 4 damage on 11 cards, instead of 5.
	# If the game wants to handle something like "do 2 damage per decksize/3", then
	# the script can float in the multiplier directly (e.g. put 2.0/3.0 as "multiplier")
	found_count = int(float(found_count) / float(divider))
	# The mutliplier might be a float
	return(int(found_count * multiplier))
