# Card Gaming Framework Utilities
#
# This is a library of static functions.
class_name CardFrameworkUtils
extends Reference

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
static func randi_range(from: float, to: float) -> int:
	return cfc.game_rng.randi_range(from, to)

static func array_join(arr, separator = ""):
	var output = "";
	for s in arr:
		output += str(s) + separator
	output = output.left( output.length() - separator.length() )
	return output

static func list_files_in_directory(path: String, prepend_needed := "") -> Array:
	var files := []
	var dir := Directory.new()
	dir.open(path)
	dir.list_dir_begin()
	while true:
		var file := dir.get_next()
		if file == "":
			break
		elif file.begins_with(prepend_needed):
			files.append(file)
	dir.list_dir_end()
	return files


static func load_card_definitions() -> Dictionary:
	var set_definitions := list_files_in_directory(
				"res://src/custom/cards/sets/", "SetDefinition_")
	var combined_sets := {}
	for set_file in set_definitions:
		var set_dict = load("res://src/custom/cards/sets/" + set_file).CARDS
		for dict_entry in set_dict:
			combined_sets[dict_entry] = set_dict[dict_entry]
	return(combined_sets)


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
