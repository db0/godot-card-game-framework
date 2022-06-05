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
# If avoid_cfc_rng, it will randomize using godot's internal randomizer
# use this for randomizations you do not care to repeat
static func shuffle_array(array: Array, avoid_cfc_rng:= false) -> void:
	var n = array.size()
	if n<2:
		return
	var j
	var tmp
	for i in range(n-1,0,-1):
		# Because there is a problem with the calling sequence of static classes,
		# if you call randi directly, you will not call CFUtils.randi
		# but call math.randi, so we call cfc.game_rng.randi() directly
		if avoid_cfc_rng:
			j = randi()%(i+1)
		else:
			j = cfc.game_rng.randi()%(i+1)
		tmp = array[j]
		array[j] = array[i]
		array[i] = tmp

# Mapping randi function
static func randi() -> int:
	return(cfc.game_rng.randi())

# Mapping randf function
static func randf() -> float:
	return(cfc.game_rng.randf())

# Mapping randi_range function
static func randi_range(from: int, to: int) -> int:
	return(cfc.game_rng.randi_range(from, to))

# Mapping randf_range function
static func randf_range(from: float, to: float) -> float:
	return(cfc.game_rng.randf_range(from, to))

# Returns a random boolean
static func rand_bool() -> bool:
	var rnd_bool = {0:true, 1: false}
	return(rnd_bool[randi_range(0,1)])

# Compares two floats within a threshold value
static func compare_floats(a, b, epsilon = 0.001):
	return abs(a - b) <= epsilon

# Returns a string of all elements in the array, separared by the
# provided separator
static func array_join(arr: Array, separator = "") -> String:
	var output : String = ""
	for s in arr:
		output += str(s) + separator
	# Remove the leftover separator
	output = output.rstrip(separator)
	return(output)


# Returns a an array of all files in a specific directory.
# If a prepend_needed String is passed, only returns files
# which start with that string.
#
# **NOTE:** This will not work for images when exported.
# use list_imported_in_directory() instead
static func list_files_in_directory(path: String, prepend_needed := "", full_path := false) -> Array:
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
			if full_path:
				files.append(path + file)
			else:
				files.append(file)
	dir.list_dir_end()
	return(files)


# Returns a an array of all images in a specific directory.
#
# Due to the way Godot exports work, we cannot look for image
# Files. Instead we have to explicitly look for their .import
# filenames, and grab the filename from there.
static func list_imported_in_directory(path: String) -> Array:
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
		elif file.ends_with(".import"):
			files.append(file.rstrip(".import"))
	dir.list_dir_end()
	return(files)


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
	if not c1.has_method("get_my_card_index") or not c2.has_method("get_my_card_index"):
		return(false)
	if c1.get_my_card_index() < c2.get_my_card_index():
		return true
	return(false)


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

# Used with sort_custom sort cards according to properties or tokens
# Expects a list of dictionaries.
# Each dictionary has two keys
# * card: The card object
# * value: The value being compared.
static func sort_by_card_field(c1, c2) -> bool:
	if c1.value < c2.value:
		return true
	return(false)


# Returns an array of CardContainers sorted reverse order of whichever
# has to be shifted first to resolve duplicate anchor placement
static func sort_by_shift_priority(c1, c2) -> bool:
	var ret: bool
	# The first two checks ensure that CardContainers
	# set to overlap_shift == None will never be pushed.
	if c1.overlap_shift_direction == CFInt.OverlapShiftDirection.NONE:
		ret = true
	elif c2.overlap_shift_direction == CFInt.OverlapShiftDirection.NONE:
		ret = false
	elif c1.index_shift_priority == CFInt.IndexShiftPriority.LOWER:
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


# Sorts scriptable objects by their canonical names
# all noes in the list need to have a "canonical_name" property
static func sort_scriptables_by_name(c1, c2) -> bool:
	if "canonical_name" in c1 and  "canonical_name" in c2:
		if c1.canonical_name < c2.canonical_name:
			return true
	elif "card_name" in c1 and  "card_name" in c2:
		if c1.card_name < c2.card_name:
			return true
	return(false)

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


# Calculates all unique values of one card property,
# among all card definitions
#
# Returns an array with all the unique values
static func get_unique_values(property: String) -> Array:
	var unique_property_values := []
	# For now we support only string properties or meta-properties
	if property in CardConfig.PROPERTIES_STRINGS\
			or property.begins_with('_'):
		for card_def in cfc.card_definitions:
			if not cfc.card_definitions[card_def][property]\
					in unique_property_values:
				unique_property_values.append(
						cfc.card_definitions[card_def][property])
	return(unique_property_values)

# Converts a resource path to a texture, or a StreamTexture object
# (which you get with `preload()`)
# into an ImageTexture you can assign to a node's texture property.
static func convert_texture_to_image(texture, is_lossless = false) -> ImageTexture:
	var tex: StreamTexture
	if typeof(texture) == TYPE_STRING:
		tex = load(texture)
	else:
#		print_debug(texture)
		tex = texture
	var new_texture = ImageTexture.new();
	if is_lossless:
		new_texture.storage = ImageTexture.STORAGE_COMPRESS_LOSSLESS
	var image = tex.get_data()
	new_texture.create_from_image(image)
	return(new_texture)
