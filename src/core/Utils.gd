
# Card Gaming Framework Utils func
# Add it to your autoloads with the name'cfu'
class_name CardFrameworkUtils
extends Node

var game_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var game_rng_seed: int = hash("godot") setget seed

func _ready() -> void:
	# Initialize random seed and random number generator
	self.seed(hash("godot"))

# Random array, Global shuffle is not used because we need to randomize through our own random seed
func shuffle_array(array:Array) -> void:
	var n = array.size()
	if n<2:
		return
	var j
	var tmp
	for i in range(n-1,1,-1):
		j = self.randi()%(i+1)
		tmp = array[j]
		array[j] = array[i]
		array[i] = tmp

# Mapping randi function
func randi():
	return game_rng.randi()

# Mapping randi_range function
func randi_range(from: float, to: float):
	return game_rng.randi_range(from, to)

# Set random seed
func seed(_seed: int):
	game_rng_seed = _seed
	game_rng.set_seed(game_rng_seed)
