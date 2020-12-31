# This class contains all the functionality required to perform
# full rules enforcement on any card.
#
# The automation is based on [ScriptTask]s. Each such "task" performs a very specific
# manipulation of the board state, based on using existing functions
# in the object manipulated.
# Therefore each task function provides effectively a text-based API
#
# This class is loaded by each card invidually, and contains a link
# back to the card object itself
class_name AlterantEngine
extends Reference

const _ASK_INTEGER_SCENE_FILE = CFConst.PATH_CORE + "AskInteger.tscn"
const _ASK_INTEGER_SCENE = preload(_ASK_INTEGER_SCENE_FILE)

# Emitted when all tasks have been run succesfully
signal alterationss_completed

# This is checked by the yield in [Card] execute_scripts()
# to know when the cost dry-run has completed, so that it can
# check the state of `can_all_costs_be_paid`.
var all_alterations_completed := false
# These task will require input from the player, so the subsequent task execution
# needs to wait for their completion
#
# This variable can be extended when this class is extended with new tasks
var wait_for_tasks = ["ask_integer"]
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
# It receives array with all the scripts to execute,
# then turns each array element into a ScriptTask object and
# send it to the appropriate tasks.
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
		# In case the task involves targetting, we need to wait on further
		# execution until targetting has completed
		if not script.has_init_completed:
			yield(script,"completed_init")
		if script.is_valid:
			calculate_alteration(script)
		# At the end of the task run, we loop back to the start, but of course
		# with one less item in our scripts_queue.
		calculate_next_alteration(
				trigger_card,
				alterant_card,
				scripts_queue,
				task_details)

func calculate_alteration(script: ScriptAlter) -> void:
	var alteration_requested = script.get_property(SP.KEY_ALTERATION)
	if str(alteration_requested) == "custom_script":
		var custom := CustomScripts.new(false)
		alteration += custom.custom_alterants(script)
	elif SP.VALUE_PER in str(alteration_requested):
		alteration = ScriptObject.count_per(
				script.get_property(SP.KEY_ALTERATION),
				script.owner_card,
				script.get_property(script.get_property(SP.KEY_ALTERATION)),
				script.trigger_card)
	else:
		alteration += script.get_property(SP.KEY_ALTERATION)
