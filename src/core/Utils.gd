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
