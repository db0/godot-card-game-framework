extends Node2D
class_name Board
# Code for a sample playspace, you're expected to provide your own ;)

var UT_mouse_position := Vector2(0,0) # Simulated mouse position for Unit Testing
var UT_current_mouse_position := Vector2(0,0) # Simulated mouse position for Unit Testing
var UT_target_mouse_position := Vector2(0,0) # Simulated mouse position for Unit Testing
var UT_mouse_speed := 3 # Simulated mouse movement speed for Unit Testing. The bigger the number, the faster the mouse moves
var UT_interpolation_requested := false
var t = 0 # Used for interpolating

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func UT_interpolate_mouse_move(newpos: Vector2, startpos := Vector2(-1,-1), mouseSpeed := 3) -> void:
	# This function is called by our unit testing to simulate mouse movement on the board
	if startpos == Vector2(-1,-1):
		UT_current_mouse_position = UT_mouse_position
	else:
		UT_current_mouse_position = startpos
	UT_mouse_speed = mouseSpeed
	UT_target_mouse_position = newpos
	UT_interpolation_requested = true

func _physics_process(delta):
	if UT_interpolation_requested:
		if UT_mouse_position != UT_target_mouse_position:
			t += delta * UT_mouse_speed
			UT_mouse_position = UT_current_mouse_position.linear_interpolate(UT_target_mouse_position, t)
		else:
			t = 0
			UT_interpolation_requested = false

func get_all_cards() -> Array:
	var cardsArray := []
	for obj in get_children():
		if obj as Card: cardsArray.append(obj)
	return cardsArray

func get_card_count() -> int:
	return len(get_all_cards())

func get_card(idx: int) -> Card:
	return get_all_cards()[idx]

func get_card_index(card: Card) -> int:
	return get_all_cards().find(card)
