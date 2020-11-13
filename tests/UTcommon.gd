extends Reference
class_name UTCommon

var main
var board

func fake_click(pressed,position, flags=0) -> InputEvent:
	var ev := InputEventMouseButton.new()
	ev.button_index=BUTTON_LEFT
	ev.pressed = pressed
	ev.position = position
	ev.meta = flags
	board.UT_mouse_position = position
	#get_tree().input_event(ev)
	return ev

func click_card(card: Card) -> void:
	var fc:= fake_click(true, card.global_position)
	card._on_Card_gui_input(fc)
	
func drop_card(card: Card, drop_location: Vector2) -> void:
	var fc:= fake_click(false, drop_location)
	card._on_Card_gui_input(fc)

func setup_main(m: Node) -> Node:
	main = m
	cfc_config._ready()
	board = cfc_config.NMAP.board
	#cfc_config.UT = true
	board.load_test_cards()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) # Always reveal the mouseon unclick
	return board
	
func setup_board(b: Node) -> Node:
	board = b
	cfc_config._ready()
	#.UT = true
	board.load_test_cards()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) # Always reveal the mouseon unclick
	return board

func draw_test_cards(count: int) -> Array:
	var cards = []
	for _iter in range(count):
		cards.append(cfc_config.NMAP.hand.draw_card())
	return cards
