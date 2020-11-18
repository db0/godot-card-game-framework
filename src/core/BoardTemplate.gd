# Holds Card objects for the player to manipulate
class_name Board
extends Node2D

# Simulated mouse position for Unit Testing
var UT_mouse_position := Vector2(0,0)
# Simulated mouse position for Unit Testing
var UT_current_mouse_position := Vector2(0,0)
# Simulated mouse position for Unit Testing
var UT_target_mouse_position := Vector2(0,0)
# Simulated mouse movement speed for Unit Testing.
# The bigger the number, the faster the mouse moves
var UT_mouse_speed := 3
# Set to true if there's an actual interpolation ongoing
var UT_interpolation_requested := false
# Used for interpolating
var t = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


func _physics_process(delta) -> void:
	if UT_interpolation_requested:
		if UT_mouse_position != UT_target_mouse_position:
			t += delta * UT_mouse_speed
			UT_mouse_position = UT_current_mouse_position.linear_interpolate(
					UT_target_mouse_position, t)
		else:
			t = 0
			UT_interpolation_requested = false


# This function is called by unit testing to simulate mouse movement on the board
func UT_interpolate_mouse_move(newpos: Vector2,
		startpos := Vector2(-1,-1), mouseSpeed := 3) -> void:
	if startpos == Vector2(-1,-1):
		UT_current_mouse_position = UT_mouse_position
	else:
		UT_current_mouse_position = startpos
	UT_mouse_speed = mouseSpeed
	UT_target_mouse_position = newpos
	UT_interpolation_requested = true


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
