# Card Gaming Framework Utilities
#
# This is a library of static functions.
class_name CFUtils
extends Reference

# The path to the optional confirm scene. This has to be defined explicitly
# here, in order to use it in its preload, otherwise the parser gives an error
const _OPTIONAL_CONFIRM_SCENE_FILE = CFConst.PATH_CORE + "OptionalConfirmation.tscn"
const _OPTIONAL_CONFIRM_SCENE = preload(_OPTIONAL_CONFIRM_SCENE_FILE)


# Randomize array through our own seed
static func shuffle_array(array: Array) -> void:
	var n = array.size()
	if n<2:
		return
	var j
	var tmp
	for i in range(n-1,1,-1):
		# Because there is a problem with the calling sequence of static classes,
		# if you call randi directly, you will not call CFUtils.randi
		# but call math.randi, so we call cfc.game_rng.randi() directly
		j = cfc.game_rng.randi()%(i+1)
		tmp = array[j]
		array[j] = array[i]
		array[i] = tmp

# Mapping randi function
static func randi() -> int:
	return cfc.game_rng.randi()

# Mapping randf function
static func randf() -> float:
	return cfc.game_rng.randf()

# Mapping randi_range function
static func randi_range(from: int, to: int) -> int:
	return cfc.game_rng.randi_range(from, to)

# Mapping randf_range function
static func randf_range(from: float, to: float) -> float:
	return cfc.game_rng.randf_range(from, to)


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
		elif not file.begins_with('.')\
				and file.begins_with(prepend_needed)\
				and not file.ends_with(".remap")\
				and not file.ends_with(".import")\
				and not file.ends_with(".md"):
			files.append(file)
	dir.list_dir_end()
	return files


# Creates a ConfirmationDialog for the player to approve the
# Use of an optional script or task.
static func confirm(
		script: Dictionary,
		card_name: String,
		task_name: String,
		type := "task") -> bool:
	var is_accepted := true
	# We do not use SP.KEY_IS_OPTIONAL here to avoid causing cyclical
	# references when calling CFUtils from SP
	if script.get("is_optional_" + type):
		var confirm = _OPTIONAL_CONFIRM_SCENE.instance()
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
static func sort_index_ascending(c1, c2) -> bool:
	# Cards with higher index get moved to the back of the Array
	# When this comparison is true, c2 is moved
	# further back in the array
	if c1.get_my_card_index() < c2.get_my_card_index():
		return true
	return false


# Used with sort_custom to find the highest child index among multiple cards
static func sort_card_containers(c1, c2) -> bool:
	var ret: bool
	if (c1.is_in_group("hands") and c2.is_in_group("hands")) \
			or (c1.is_in_group("piles") and c2.is_in_group("piles")):
		if c1.get_index() < c2.get_index():
			ret = true
		else:
			ret = false
	else:
		# We want the hand to have a lower priority than piles
		# because it has a larger drop area
		if c2.is_in_group("hands"):
			ret = false
		else:
			ret = true
	return(ret)


# Returns an array of CardContainers sorted reverse order of whichever
# has to be shifted first to resolve duplicate anchor placement
static func sort_by_shift_priority(c1, c2) -> bool:
	var ret: bool
	# The first two checks ensure that CardContainers
	# set to overlap_shift == None will never be pushed.
	if c1.overlap_shift_direction == CFConst.OverlapShiftDirection.NONE:
		ret = true
	elif c2.overlap_shift_direction == CFConst.OverlapShiftDirection.NONE:
		ret = false
	elif c1.index_shift_priority == CFConst.IndexShiftPriority.LOWER:
		if c1.get_index() < c2.get_index():
			ret = false
		else:
			ret = true
	else:
		if c1.get_index() < c2.get_index():
			ret = true
		else:
			ret = false
	return(ret)


# Generates a random 10-char string to serve as a seed for a game.
# This allows the seed to be viewed and shared for the same game to be replayed.
static func generate_random_seed() -> String:
	randomize()
	var rnd_seed : String = ""
	for _iter in range(10):
		rnd_seed +=  char(int(rand_range(40,127)))
	return(rnd_seed)


# Compares two numbers based on a comparison type
# The comparison type is one of the following
# * "eq": Equal
# * "ne": Not Equal
# * "gt": Greater than
# * "lt": Less than
# * "le": Less than or Equal
# * "ge": Geater than or equal
#
# The perspective is always from the perspetive of n1
# I.e. n1 = 1, n2 = 2 and comparison_type = "gt" is equal to: 1 > 2
static func compare_numbers(n1: int, n2: int, comparison_type: String) -> bool:
	var comp_result = false
	match comparison_type:
		"eq":
			if n1 == n2:
				comp_result = true
		"ne":
			if n1 != n2:
				comp_result = true
		"lt":
			if n1 < n2:
				comp_result = true
		"le":
			if n1 <= n2:
				comp_result = true
		"gt":
			if n1 > n2:
				comp_result = true
		"ge":
			if n1 >= n2:
				comp_result = true
	return(comp_result)

# Compares two strings based on a comparison type
# The comparison type is one of the following
# * "eq": Equal
# * "ne": Not Equal
static func compare_strings(s1: String, s2: String, comparison_type: String) -> bool:
	var comp_result = false
	match comparison_type:
		"eq":
			if s1 == s2:
				comp_result = true
		"ne":
			if s1 != s2:
				comp_result = true
	return(comp_result)

static func get_unique_values(property) -> Array:
	var unique_property_values := []
	if property in CardConfig.PROPERTIES_STRINGS:
		for card_def in cfc.card_definitions:

			if not cfc.card_definitions[card_def][property]\
					in unique_property_values:
				unique_property_values.append(
						cfc.card_definitions[card_def][property])
	return(unique_property_values)
