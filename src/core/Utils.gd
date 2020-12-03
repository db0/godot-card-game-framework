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


static func recalculate_position(card,index_diff=null)-> Vector2:
	if cfc.hand_use_oval_shape:
		return recalculate_position_use_oval(card,index_diff)
	return recalculate_position_use_rectangle(card,index_diff)


static func get_angle_by_index(card,index_diff = null):
	var index = card.get_my_card_index()
	var hand_size = card.get_parent().get_card_count()
	var half
	half = (hand_size-1)/2.0
	var max_hand_size = cfc.NMAP.hand.hand_size
	var card_angle_max:float = 15
	var card_angle_min:float = 5
	var card_angle = max(min(60/hand_size,card_angle_max),card_angle_min)
	if index_diff != null:
		return 90+(half-index)*card_angle - sign(index_diff)*(-index_diff*index_diff+5)
	else:
		return 90+(half-index)*card_angle

static func get_oval_angle_by_index(card,angle=null,index_diff = null,hor_rad=null,ver_rad=null):
	if not angle:
		angle = get_angle_by_index(card,index_diff)
	var parent_control
	if not hor_rad:
		parent_control = card.get_parent().get_node('Control')
		hor_rad = parent_control.rect_size.x * 0.5 * 1.5
	if not ver_rad:
		parent_control = card.get_parent().get_node('Control')
		ver_rad = parent_control.rect_size.y * 1.5
	var card_angle
	if angle == 90:
		card_angle = 90
	else:
		card_angle= rad2deg(atan(-ver_rad/hor_rad/tan(deg2rad(angle))))
		card_angle = card_angle + 90
	return card_angle

# Calculate the value after the rotation has been calculated
static func recalculate_position_use_oval(card,index_diff=null)-> Vector2:
	var card_position_x: float = 0.0
	var card_position_y: float = 0.0
	var parent_control = card.get_parent().get_node('Control')
	var control = card.get_node('Control')
	var hor_rad: float = parent_control.rect_size.x * 0.5 * 1.5
	var ver_rad: float = parent_control.rect_size.y * 1.5
	var angle = get_angle_by_index(card,index_diff)
	var rad_angle = deg2rad(angle)
	var oval_angle_vector = Vector2(hor_rad*cos(rad_angle),-ver_rad*sin(rad_angle))
	var left_top = Vector2(-control.rect_size.x/2,-control.rect_size.y/2)
	var center_top = Vector2(0,-control.rect_size.y/2)
	var card_angle = get_oval_angle_by_index(card,angle,null,hor_rad,ver_rad)
	var delta_vector = left_top - center_top.rotated(deg2rad(90-card_angle))
	var center_x = parent_control.rect_size.x/2+parent_control.rect_position.x
	var center_y = parent_control.rect_size.y*1.5 +parent_control.rect_position.y
	card_position_x = (oval_angle_vector.x+center_x)
	card_position_y = (oval_angle_vector.y+center_y)
	return Vector2(card_position_x,card_position_y)+delta_vector

static func recalculate_position_use_rectangle(card,index_diff=null)-> Vector2:
	var card_position_x: float = 0.0
	var card_position_y: float = 0.0
	# The number of cards currently in hand
	var hand_size: int = card.get_parent().get_card_count()
	# The maximum of horizontal pixels we want the cards to take
	# We simply use the size of the parent control container we've defined in
	# the node settings
	var parent_control = card.get_parent().get_node('Control')
	var control = card.get_node('Control')
	var max_hand_size_width: float = parent_control.rect_size.x
	# The maximum distance between cards
	# We base it on the card width to allow it to work with any card-size.
	var card_gap_max: float = control.rect_size.x * 1.1
	# The minimum distance between cards
	# (less than card width means they start overlapping)
	var card_gap_min: float = control.rect_size.x/2
	# The current distance between cards.
	# It is inversely proportional to the amount of cards in hand
	var cards_gap: float = max(min((max_hand_size_width
			- control.rect_size.x/2)
			/ hand_size, card_gap_max), card_gap_min)
	# The current width of all cards in hand together
	var hand_width: float = (cards_gap * (hand_size-1)) + control.rect_size.x
	# The following just create the vector position to place this specific card
	# in the playspace.
	card_position_x = (max_hand_size_width/2
			- hand_width/2
			+ cards_gap
			* card.get_my_card_index())
	# Since our control container has the same size as the cards,we start from 0
	# and just offset the card if we want it higher or lower.
	card_position_y = 0

	if index_diff!=null:
		return Vector2(card_position_x,card_position_y)+Vector2(control.rect_size.x/index_diff* cfc.NEIGHBOUR_PUSH,0)
	else:
		return Vector2(card_position_x,card_position_y)

static func recalculate_rotation(card,index_diff=null)-> float:
	if cfc.hand_use_oval_shape:
		return recalculate_rotation_use_oval(card,index_diff)
	return recalculate_rotation_use_rectangle(card)

static func recalculate_rotation_use_rectangle(card)-> float:
	return 0.0

static func recalculate_rotation_use_oval(card,index_diff=null)-> float:
	return 90.0-get_oval_angle_by_index(card,null,index_diff)
