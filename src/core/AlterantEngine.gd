# This class contains all the functionality required to modify a
# running task during runtime
#
# The automation is based on [ScriptAlter] definitions. 
#
# This class is on request when one of a number of specific tasks
# which allow it, are going through all the cards, looking for valid Alterants
# definitions. 
class_name AlterantEngine
extends Reference

const _ASK_INTEGER_SCENE_FILE = CFConst.PATH_CORE + "AskInteger.tscn"
const _ASK_INTEGER_SCENE = preload(_ASK_INTEGER_SCENE_FILE)

# Emitted when all alterations have been run succesfully
signal alterations_completed

# This is checked by the yield in [get_altered_value](CFScriptUtils#get_altered_value)
# to know execution has completed.
var all_alterations_completed := false
# The total amount of alterations that this card's script will perform.
var alteration := 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Sets the owner of this Scripting Engine
func _init(
		trigger_card: Card,
		alterant_card: Card,
		scripts_queue: Array,
		task_details: Dictionary) -> void:
	calculate_next_alteration(
			trigger_card,
			alterant_card,
			scripts_queue.duplicate(),
			task_details)

# The main engine starts here.
# It receives array with all the possible alterations to execute,
# then turns each array element into a [ScriptAlter] object which check
# against the relevant filters and per_ requests.
func calculate_next_alteration(
		trigger_card: Card,
		alterant_card: Card,
		scripts_queue: Array,
		task_details: Dictionary) -> void:
	if scripts_queue.empty():
		all_alterations_completed = true
		emit_signal("alterations_completed")
	else:
		var script := ScriptAlter.new(
				scripts_queue.pop_front(),
				trigger_card,
				alterant_card,
				task_details)
		if not script.is_primed:
			yield(script,"primed")
		if script.is_valid:
			calculate_alteration(script)
		# At the end of the run, we loop back to the start, but of course
		# with one less item in our scripts_queue.
		calculate_next_alteration(
				trigger_card,
				alterant_card,
				scripts_queue,
				task_details)


# This is called if the alterants passes all validity checks
# it calculates how much to alter, based on the script definition.
func calculate_alteration(script: ScriptAlter) -> void:
	var alteration_requested = script.get_property(SP.KEY_ALTERATION)
	if str(alteration_requested) == "custom_script":
		var custom := CustomScripts.new(false)
		alteration += custom.custom_alterants(script)
	elif SP.VALUE_PER in str(alteration_requested):
		var per_msg = perMessage.new(
				script.get_property(SP.KEY_ALTERATION),
				script.owner_card,
				script.get_property(script.get_property(SP.KEY_ALTERATION)),
				script.trigger_card)
		alteration = per_msg.found_things
	else:
		alteration += script.get_property(SP.KEY_ALTERATION)
