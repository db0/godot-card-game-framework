# Mean to serve as the main play area for [Card] objects.
#
# It functions almost like a [CardContainer].
class_name Board
extends Control

# Simulated mouse position for Unit Testing
var _UT_mouse_position := Vector2(0,0)
# Simulated mouse position for Unit Testing
var _UT_current_mouse_position := Vector2(0,0)
# Simulated mouse position for Unit Testing
var _UT_target_mouse_position := Vector2(0,0)
# Simulated mouse movement speed for Unit Testing.
# The bigger the number, the faster the mouse moves
var _UT_mouse_speed := 3
# Set to true if there's an actual interpolation ongoing
var _UT_interpolation_requested := false
# Used for interpolating
var _t = 0
# Used for finding the counters node and modifying them
# This variable has to exist if the [mod_counters](ScriptingEngine#mod_counters)
# task is to be used.
var counters : Counters

var mouse_pointer: MousePointer
	

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("board")
	if not cfc.are_all_nodes_mapped:
		yield(cfc, "all_nodes_mapped")
	mouse_pointer = load(CFConst.PATH_MOUSE_POINTER).instance()
	add_child(mouse_pointer)
	for container in get_tree().get_nodes_in_group("piles"):
		container.re_place()
	for container in get_tree().get_nodes_in_group("hands"):
		container.re_place()


func _process(_delta: float) -> void:
	mouse_pointer.global_position = \
			mouse_pointer.determine_global_mouse_pos()

func _physics_process(delta) -> void:
	if _UT_interpolation_requested:
		if _t < 1:
			_t += delta * _UT_mouse_speed
			_UT_mouse_position = _UT_current_mouse_position.linear_interpolate(
					_UT_target_mouse_position, _t)
		else:
			_t = 0
			_UT_interpolation_requested = false


# This function is called by unit testing to simulate mouse movement on the board
func _UT_interpolate_mouse_move(newpos: Vector2,
		startpos := Vector2(-1,-1), mouseSpeed := 3) -> void:
#	print_debug(newpos, _UT_mouse_position)
	if startpos == Vector2(-1,-1):
		_UT_current_mouse_position = _UT_mouse_position
	else:
		_UT_current_mouse_position = startpos
	_UT_mouse_speed = mouseSpeed
	_UT_target_mouse_position = newpos
	_UT_interpolation_requested = true


# Returns an array with all children nodes which are of Card class
func get_all_cards() -> Array:
	var cardsArray := []
	for obj in get_children():
		if obj as Card: cardsArray.append(obj)
	return(cardsArray)

# Overridable function which returns all objects on the table which can
# be used as subjects by the scripting engine.
func get_all_scriptables() -> Array:
	return(get_all_cards())


# Returns an int with the amount of children nodes which are of Card class
func get_card_count() -> int:
	return(get_all_cards().size())


# Returns a card object of the card in the specified index among all cards.
func get_card(idx: int) -> Card:
	return(get_all_cards()[idx])


# Returns an int of the index of the card object requested
func get_card_index(card: Card) -> int:
	return(get_all_cards().find(card))


# Returns the BoardPlacementGrid object with the specified name
func get_grid(grid_name: String) -> BoardPlacementGrid:
	var found_grid: BoardPlacementGrid
	for grid in get_tree().get_nodes_in_group("placement_grid"):
		if grid.name_label.text == grid_name:
			found_grid = grid
	return(found_grid)

# warning-ignore:unused_argument
func get_final_placement_node(card: Card) -> Node:
	return(self)
