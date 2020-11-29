class_name UTCommon
extends "res://addons/gut/test.gd"

const MAIN_SCENE = preload("res://src/core/Main.tscn")
const BOARD_SCENE = preload("res://src/custom/Board.tscn")
const MOUSE_SPEED := {
	"fast": [10,0.3],
	"slow": [3,0.6],
}


var main
var board
var hand
var deck
var discard

func fake_click(pressed,position, flags=0) -> InputEvent:
	var ev := InputEventMouseButton.new()
	ev.button_index=BUTTON_LEFT
	ev.pressed = pressed
	ev.position = position
	ev.meta = flags
	board._UT_mouse_position = position
	return ev


func setup_main() -> void:
	main = autoqfree(MAIN_SCENE.instance())
	get_tree().get_root().add_child(main)
	cfc._ready()
	board = cfc.NMAP.board
	board.load_test_cards()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) # Always reveal the mouseon unclick


func setup_board() -> void:
	board = autoqfree(BOARD_SCENE.instance())
	get_tree().get_root().add_child(board)
	cfc._ready()
	board.load_test_cards()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) # Always reveal the mouseon unclick
	hand = cfc.NMAP.hand
	deck = cfc.NMAP.deck
	discard = cfc.NMAP.discard

func draw_test_cards(count: int) -> Array:
	var cards = []
	for _iter in range(count):
		cards.append(hand.draw_card())
	return cards

func click_card(card: Card) -> void:
	var fc:= fake_click(true, card.global_position)
	card._on_Card_gui_input(fc)

func unclick_card(card: Card) -> void:
	var fc:= fake_click(false, card.global_position)
	card._on_Card_gui_input(fc)

# We need this for targetting arrows which don't release back on the card gui
func unclick_card_anywhere(card: Card) -> void:
	var fc:= fake_click(false, card.global_position)
	card._input(fc)


func drag_card(card: Card, target_position: Vector2, interpolation_speed := "fast") -> void:
	var mouse_speed = MOUSE_SPEED[interpolation_speed][0]
	var mouse_yield_wait = MOUSE_SPEED[interpolation_speed][1]
	card._on_Card_mouse_entered()
	click_card(card)
	yield(yield_for(0.3), YIELD) # Wait to allow dragging to start
	board._UT_interpolate_mouse_move(target_position,card.global_position,mouse_speed)
	yield(yield_for(mouse_yield_wait), YIELD)


func drop_card(card: Card, drop_location: Vector2) -> void:
	var fc:= fake_click(false, drop_location)
	card._on_Card_gui_input(fc)
	yield(yield_to(card.get_node('Tween'), "tween_all_completed", 1), YIELD)


# Takes care of simple drag&drop requests
func drag_drop(card: Card, target_position: Vector2, interpolation_speed := "fast") -> void:
	yield(drag_card(card,target_position,interpolation_speed), 'completed')
	yield(drop_card(card,board._UT_mouse_position), 'completed')
	yield(yield_for(0.1), YIELD) # Wait to allow dragging to start
	card._on_Card_mouse_exited()

# Interpolates the virtual mouse so that it correctly targets a card
func target_card(source, target, interpolation_speed := "fast") -> void:
	var mouse_speed = MOUSE_SPEED[interpolation_speed][0]
	var mouse_yield_wait = MOUSE_SPEED[interpolation_speed][1]
	# We need to offset a bit towards the card rect, to ensure the arrow
	# Area2D collides
	board._UT_interpolate_mouse_move(target.global_position + Vector2(10,10),
			source.global_position,mouse_speed)
	yield(yield_for(mouse_yield_wait), YIELD)
	unclick_card_anywhere(source)

func table_move(card: Card, pos: Vector2) -> void:
	card.move_to(board, -1, pos)
	yield(yield_to(card._tween, "tween_all_completed", 0.5), YIELD)
	if cfc.fancy_movement:
		yield(yield_to(card._tween, "tween_all_completed", 0.5), YIELD)
	
	
