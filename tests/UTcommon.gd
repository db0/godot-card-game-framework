class_name UTCommon
extends Reference

var main
var board

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


func setup_main(m: Node) -> Node:
	main = m
	cfc._ready()
	board = cfc.NMAP.board
	board.load_test_cards()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) # Always reveal the mouseon unclick
	return board
	

func setup_board(b: Node) -> Node:
	board = b
	cfc._ready()
	board.load_test_cards()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) # Always reveal the mouseon unclick
	return board


func draw_test_cards(count: int) -> Array:
	var cards = []
	for _iter in range(count):
		cards.append(cfc.NMAP.hand.draw_card())
	return cards
