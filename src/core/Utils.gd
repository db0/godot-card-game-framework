# Card Gaming Framework Utilities
#
# This is a library of static functions.
class_name CardFrameworkUtils
extends Reference

const _CARD_OPTIONAL_CONFIRM = \
		preload("res://src/core/OptionalConfirmation.tscn")

# Randomize array through our own seed
static func shuffle_array(array: Array) -> void:
	var n = array.size()
	if n<2:
		return
	var j
	var tmp
	for i in range(n-1,1,-1):
		# Because there is a problem with the calling sequence of static classes,
		# if you call randi directly, you will not call CardFrameworkUtils.randi
		# but call math.randi, so we call cfc.game_rng.randi() directly
		j = cfc.game_rng.randi()%(i+1)
		tmp = array[j]
		array[j] = array[i]
		array[i] = tmp

# Mapping randi function
static func randi() -> int:
	return cfc.game_rng.randi()

# Mapping randi_range function
static func randi_range(from: int, to: int) -> int:
	return cfc.game_rng.randi_range(from, to)


# Returns a string of all elements in the array, separared by the
# provided separator
static func array_join(arr: Array, separator = "") -> String:
	var output = "";
	for s in arr:
		output += str(s) + separator
	output = output.left( output.length() - separator.length() )
	return output


# Returns a an array of all files in a specific directory.
# If a prepend_needed String is passed, only returns files
# which start with that string.
static func list_files_in_directory(path: String, prepend_needed := "") -> Array:
	var files := []
	var dir := Directory.new()
	# warning-ignore:return_value_discarded
	dir.open(path)
	# warning-ignore:return_value_discarded
	dir.list_dir_begin()
	while true:
		var file := dir.get_next()
		if file == "":
			break
		elif not file.begins_with('.') and file.begins_with(prepend_needed):
			files.append(file)
	dir.list_dir_end()
	return files


# Returns the combined Card definitions of all set files
static func load_card_definitions() -> Dictionary:
	var set_definitions := list_files_in_directory(
				"res://src/custom/cards/sets/", "SetDefinition_")
	var combined_sets := {}
	for set_file in set_definitions:
		var set_dict = load("res://src/custom/cards/sets/" + set_file).CARDS
		for dict_entry in set_dict:
			combined_sets[dict_entry] = set_dict[dict_entry]
	return(combined_sets)


# Seeks in the script definitions of all sets, and returns the script for
# the requested card
static func find_card_script(card_name, trigger) -> Dictionary:
	var set_definitions := list_files_in_directory(
				"res://src/custom/cards/sets/", "SetScripts_")
	var card_script := {}
	for set_file in set_definitions:
		var set_scripts = load("res://src/custom/cards/sets/" + set_file).new()
		card_script = set_scripts.get_scripts(card_name, trigger)
		if not card_script.empty():
			break
	return(card_script)


# Creates a ConfirmationDialog for the player to approve the 
# Use of an optional script or task.
static func confirm(
		script: Dictionary, 
		card_name: String,
		task_name: String,
		type := "task") -> bool:
	var is_accepted := true
	if script.get(SP.KEY_IS_OPTIONAL + type):
		var confirm = _CARD_OPTIONAL_CONFIRM.instance()
		confirm.prep(card_name,task_name)
		# We have to wait until the player has finished selecting an option
		yield(confirm,"selected")
		# If the player selected "No", we don't execute anything
		if not confirm.is_accepted:
			is_accepted = false
		# Garbage cleanup
		confirm.queue_free()
	return(is_accepted)


# Used with sort_custom to find the highest child index among multiple cards
static func sort_index_ascending(c1, c2):
	if c1.get_my_card_index() < c2.get_my_card_index():
		return true
	return false
