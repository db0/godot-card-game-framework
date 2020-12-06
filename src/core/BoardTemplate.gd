# Mean to serve as the main play area for [Card] objects.
#
# It functions almost like a [CardContainer].
class_name Board
extends Node2D


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

onready var mouse_pointer := preload("res://src/core/MousePointer.tscn").instance()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_child(mouse_pointer)



func _process(_delta: float) -> void:
	mouse_pointer.global_position = \
			mouse_pointer.determine_global_mouse_pos()
	
func _physics_process(delta) -> void:
	if _UT_interpolation_requested:
		if _UT_mouse_position != _UT_target_mouse_position:
			_t += delta * _UT_mouse_speed
			_UT_mouse_position = _UT_current_mouse_position.linear_interpolate(
					_UT_target_mouse_position, _t)
		else:
			_t = 0
			_UT_interpolation_requested = false


# This function is called by unit testing to simulate mouse movement on the board
func _UT_interpolate_mouse_move(newpos: Vector2,
		startpos := Vector2(-1,-1), mouseSpeed := 3) -> void:
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
	return cardsArray


# Returns an int with the amount of children nodes which are of Card class
func get_card_count() -> int:
	return len(get_all_cards())


# Returns a card object of the card in the specified index among all cards.
func get_card(idx: int) -> Card:
	return get_all_cards()[idx]


# Returns an int of the index of the card object requested
func get_card_index(card: Card) -> int:
	return get_all_cards().find(card)
