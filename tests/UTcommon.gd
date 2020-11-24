class_name UTCommon
extends "res://addons/gut/test.gd"

var main
var board
var hand

func fake_click(pressed,position, flags=0) -> InputEvent:
	var ev := InputEventMouseButton.new()
	ev.button_index=BUTTON_LEFT
	ev.pressed = pressed
	ev.position = position
	ev.meta = flags
	board._UT_mouse_position = position
	return ev


func click_card(card: Card) -> void:
	var fc:= fake_click(true, card.global_position)
	card._on_Card_gui_input(fc)
	

func drop_card(card: Card, drop_location: Vector2) -> void:
	var fc:= fake_click(false, drop_location)
	card._on_Card_gui_input(fc)


func setup_main() -> void:
	main = autoqfree(TestVars.new().mainScene.instance())
	get_tree().get_root().add_child(main)
	cfc._ready()
	board = cfc.NMAP.board
	board.load_test_cards()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) # Always reveal the mouseon unclick
	

func setup_board() -> void:
	board = autoqfree(TestVars.new().boardScene.instance())
	get_tree().get_root().add_child(board)
	cfc._ready()
	board.load_test_cards()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) # Always reveal the mouseon unclick
	hand = cfc.NMAP.hand

func draw_test_cards(count: int) -> Array:
	var cards = []
	for _iter in range(count):
		cards.append(cfc.NMAP.hand.draw_card())
	return cards

# Takes care of simple drag&drop requests
func drag_drop(card: Card, target_position: Vector2, interpolation_speed := "fast") -> void:
	var mouse_yield_wait: float
	var mouse_speed: int
	if interpolation_speed == "fast":
		mouse_yield_wait = 0.3
		mouse_speed = 10
	else:
		mouse_yield_wait = 0.6
		mouse_speed = 3
	card._on_Card_mouse_entered()
	click_card(card)
	yield(yield_for(0.3), YIELD) # Wait to allow dragging to start
	board._UT_interpolate_mouse_move(target_position,card.position,mouse_speed)
	yield(yield_for(mouse_yield_wait), YIELD)
	drop_card(card,board._UT_mouse_position)
	card._on_Card_mouse_exited()
	yield(yield_to(card.get_node('Tween'), "tween_all_completed", 1), YIELD)
