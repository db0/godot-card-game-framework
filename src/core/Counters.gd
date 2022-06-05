# This class contains the methods needed to manipulate counters in a game
#
# It is meant to be extended and attached to a customized scene.
#
# In the extended script, the various values should be filled during
# the _ready() method
class_name Counters
extends Control

signal counter_modified(card,trigger,details)

# Hold the actual values of the various counters requested
var counters := {}
# Holds the label nodes which display the counter values to the user
var _labels := {}
# Each entry in this dictionary will specify one counter to be added
# The key will be the name of the node holding the counter
# The value is a dictionary where each key is a label node path relative
# to the counter_scene
# and each value, is the text value for the label
var needed_counters: Dictionary
# This hold modifiers to counters that will be only active temporarily.
#
# Typically only used during
# an [execute_scripts()](ScriptingEngine#execute_scripts] task.
#
# Each key is a ScriptingEngine reference, and each value is a dictionary
# With the following keys:
# * requesting_card: The card object which has requested this temp modifier
# * modifer: A dictionary with all the modifications requested by this card
#	Each key is a counter name, and value is the temp modifier requested
#	for this counter
#
# This allows multiple modifiers may be active at the same time, even from
# nested tasks on the same card during an execute_scripts task.
var temp_count_modifiers := {}

# Holds the counter scene which has been created by the developer
export(PackedScene) var counter_scene

# This variable should hold the path to the Control container
# Which will hold the counter objects.
#
# It should be set in the _ready() function of the script which extends this class
var counters_container : Container
# This variable should hold which needed_counters dictionary key is the path
# to the label which holds the values for the counter
#
# It should be set in the _ready() function of the script which extends this class
var value_node: String


func _ready() -> void:
	# For the counter signal, we "push" connect it instead from this node.
	# warning-ignore:return_value_discarded
	self.connect("counter_modified", cfc.signal_propagator, "_on_signal_received")


# This function should be called by the _ready() function of the script which
# extends thic class, after it has set all the necessary variables.
#
# It creates and initiates all the necessary counters required by this game.
func spawn_needed_counters() -> Array:
	var all_counters := []
	for counter_name in needed_counters:
		var counter = counter_scene.instance()
		counters_container.add_child(counter)
		all_counters.append(counter)
		counter.name = counter_name
		var counter_labels = needed_counters[counter_name]
		for label in counter_labels:
			if not counter.has_node(label):
				continue
			counter.get_node(label).text = str(counter_labels[label])
			# The value_node is also used determine the initial values
			# of the counters dictionary
			if label == value_node:
				counters[counter_name] = counter_labels[label]
				# _labels stores the label node which displays the value
				# of the counter
				_labels[counter_name] = counter.get_node(label)
	return(all_counters)


# Modifies the value of a counter. The counter has to have been specified
# in the `needed_counters`
#
# * Returns CFConst.ReturnCode.CHANGED if a modification happened
# * Returns CFConst.ReturnCode.OK if the modification requested is already the case
# * Returns CFConst.ReturnCode.FAILED if for any reason the modification cannot happen
#
# If check is true, no changes will be made, but will return
# the appropriate return code, according to what would have happened
#
# If set_to_mod is true, then the counter will be set to exactly the value
# requested. otherwise the value will be modified from the current value
func mod_counter(counter_name: String,
		value: int,
		set_to_mod := false,
		check := false,
		requesting_object = null,
		tags := ["Manual"]) -> int:
	var retcode = CFConst.ReturnCode.CHANGED
	if counters.get(counter_name, null) == null:
		retcode = CFConst.ReturnCode.FAILED
	else:
		if set_to_mod and counters[counter_name] == value:
			retcode = CFConst.ReturnCode.OK
		elif set_to_mod and counters[counter_name] < 0:
			retcode = CFConst.ReturnCode.FAILED
		else:
			if counters[counter_name] + value < 0:
				retcode = CFConst.ReturnCode.FAILED
				value = -counters[counter_name]
			if not check:
				cfc.flush_cache()
				var prev_value = counters[counter_name]
				if set_to_mod:
					_set_counter(counter_name,value)
				else:
					_set_counter(counter_name, counters[counter_name] + value)
				emit_signal(
						"counter_modified",
						requesting_object,
						"counter_modified",
						{
							SP.TRIGGER_COUNTER_NAME: counter_name,
							SP.TRIGGER_PREV_COUNT: prev_value,
							SP.TRIGGER_NEW_COUNT: counters[counter_name],
							"tags": tags,
						}
				)
	return(retcode)


# Returns the value of the specified counter.
# Takes into account temp_count_modifiers and alterants
func get_counter(counter_name: String, requesting_object = null) -> int:
	var count = get_counter_and_alterants(counter_name, requesting_object).count
	return(count)


# Discovers the modified value of the specified counter based
# on temp_count_modifiers and alterants.
#
# Returns a dictionary with the following keys:
# * count: The final value of this counter after all modifications
# * alteration: The full dictionary returned by
#	CFScriptUtils.get_altered_value() but including details about
# * temp_modifiers: A custom dictionary, following the format of the alteration
#	dictionary, but holding modifications done by temp_count_modifiers
#	temp_count_modifiers
func get_counter_and_alterants(
		counter_name: String,
		requesting_object = null) -> Dictionary:
	var count = counters[counter_name]
	# We iterate through the values, where each value is a dictionary
	# with key being the counter name, and value being the temp modifier
	var alteration = {
		"value_alteration": 0,
		"alterants_details": {}
	}
	if requesting_object:
		alteration = CFScriptUtils.get_altered_value(
			requesting_object,
			"get_counter",
			{SP.KEY_COUNTER_NAME: counter_name,},
			counters[counter_name])
		if alteration is GDScriptFunctionState:
			alteration = yield(alteration, "completed")
	# The first element is always the total modifier from all alterants
	count += alteration.value_alteration
	var temp_modifiers = {
		"value_modification": 0,
		"modifier_details": {}
	}
	for modifiers_dict in temp_count_modifiers.values():
		# The value_modification key hold the total modification done by
		# all temp modifiers.
		temp_modifiers.value_modification += modifiers_dict.modifier.get(counter_name,0)
		# Each value in the modifier_details dictionary is another dictionary
		# Where the key is the card object which has added this modifier
		# And the value is the modifier this specific card added to the total
		temp_modifiers.modifier_details[modifiers_dict.requesting_object] =\
				modifiers_dict.modifier.get(counter_name,0)
	count += temp_modifiers.value_modification
	if count < 0:
		count = 0
	var return_dict = {
		"count": count,
		"alteration": alteration,
		"temp_modifiers": temp_modifiers,
	}
	return(return_dict)


func set_temp_counter_modifiers(sceng, task, requesting_object, modifier) -> void:
	temp_count_modifiers[task] = {
			"requesting_object": requesting_object,
			"modifier": modifier,
		}
	if not sceng.is_connected("single_task_completed", self, "_on_single_task_completed"):
		sceng.connect("single_task_completed", self, "_on_single_task_completed")

func _on_single_task_completed(script_task) -> void:
	temp_count_modifiers.erase(script_task)

# Overridable function to update the various counters.
func _set_counter(counter_name: String, value) -> void:
	counters[counter_name] = value
	_labels[counter_name].text = str(counters[counter_name])
