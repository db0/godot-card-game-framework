extends "res://addons/gut/test.gd"

var board
var hand
var cards := []
var tv = TestVars.new()


func fake_click(pressed,position, flags=0) -> InputEvent:
	var ev := InputEventMouseButton.new()
	ev.button_index=BUTTON_LEFT
	ev.pressed = pressed
	ev.position = position
	ev.meta = flags
	board.UT_mouse_position = position
	#if not pressed: get_tree().input_event(ev)
	return ev

func click_card(card: Card) -> void:
	var fc:= fake_click(true, card.rect_global_position)
	card._on_Card_gui_input(null,fc,null)

func drop_card(card: Card) -> void:
	var fc:= fake_click(false, card.rect_global_position)
	card._input(fc)

#func unclick(position) -> void:
#	var fc:= fake_click(false, position)

func before_each():
	board = autoqfree(tv.boardScene.instance())
	get_tree().get_root().add_child(board)
	cfc_config._ready() # This is needed every time because the objects change
	board.UT = true
	hand = board.get_node('Hand')
	cards = []
	for _iter in range(5):
		cards.append(hand.draw_card())

func test_card_table_drop_location():
	yield(yield_for(1), YIELD)
	cards[0]._on_Card_mouse_entered()
	#gut.p(cards[0].rect_global_position)
	click_card(cards[0])
	yield(yield_for(0.12), YIELD) # Wait to allow dragging to start
	board.UT_interpolate_mouse_move(Vector2(300,300),cards[0].rect_global_position)
	yield(yield_for(0.6), YIELD)
	board.UT_interpolate_mouse_move(Vector2(800,200))
	yield(yield_for(0.6), YIELD)
	drop_card(cards[0])
	watch_signals(cards[0])
	assert_signal_emitted(cards[0], "card_dropped") 
	yield(yield_to(cards[0].get_node('Tween'), "tween_all_completed", 1), YIELD)
	assert_almost_eq(Vector2(810, 210),cards[0].rect_global_position,Vector2(2,2), "Check card dragged in correct global position")

func test_card_hand_drop_recovery():
	yield(yield_for(1), YIELD)
	cards[0]._on_Card_mouse_entered()
	click_card(cards[0])
	yield(yield_for(0.12), YIELD) # Wait to allow dragging to start
	board.UT_interpolate_mouse_move(Vector2(100,100),cards[0].rect_global_position)
	yield(yield_for(0.4), YIELD)
	board.UT_interpolate_mouse_move(Vector2(200,620))
	yield(yield_for(0.4), YIELD)
	drop_card(cards[0])
	yield(yield_to(cards[0].get_node('Tween'), "tween_all_completed", 1), YIELD)
	assert_eq(hand.get_child_count(),6, "Check card dragged back in hand remains in hand")

func test_card_drag_block_by_board_borders():
	yield(yield_for(1), YIELD)
	cards[4]._on_Card_mouse_entered()
	click_card(cards[4])
	yield(yield_for(0.12), YIELD) # Wait to allow dragging to start
	board.UT_interpolate_mouse_move(Vector2(-100,100),cards[0].rect_global_position)
	yield(yield_for(0.4), YIELD)
	assert_almost_eq(Vector2(0, 110),cards[4].rect_global_position,Vector2(2,2), "Check dragged outside left viewport borders stays inside viewport")
	board.UT_interpolate_mouse_move(Vector2(1300,300))
	yield(yield_for(0.4), YIELD)
	assert_almost_eq(Vector2(1220, 310),cards[4].rect_global_position,Vector2(2,2), "Check dragged outside right viewport borders stays inside viewport")
	board.UT_interpolate_mouse_move(Vector2(800,-100))
	yield(yield_for(0.4), YIELD)
	assert_almost_eq(Vector2(810, 0),cards[4].rect_global_position,Vector2(2,2), "Check dragged outside top viewport borders stays inside viewport")
	board.UT_interpolate_mouse_move(Vector2(500,800))
	yield(yield_for(0.4), YIELD)
	assert_almost_eq(Vector2(510, 624),cards[4].rect_global_position,Vector2(2,2), "Check dragged outside bottom viewport borders stays inside viewport")


func test_fast_card_table_drop():
	# This catches a bug where the card keeps following the mouse after being dropped
	yield(yield_for(1), YIELD)
	cards[0]._on_Card_mouse_entered()
	click_card(cards[0])
	yield(yield_for(0.2), YIELD) # Wait to allow dragging to start
	board.UT_interpolate_mouse_move(Vector2(1000, 300),cards[0].rect_global_position,3)
	yield(yield_for(0.6), YIELD)
	drop_card(cards[0])
	yield(yield_to(cards[0].get_node('Tween'), "tween_all_completed", 1), YIELD)
	board.UT_interpolate_mouse_move(Vector2(400,200),cards[0].rect_global_position,3)
	yield(yield_for(0.6), YIELD)
	board.UT_interpolate_mouse_move(Vector2(1000,500),cards[0].rect_global_position,3)
	yield(yield_for(0.6), YIELD)
	assert_almost_eq(Vector2(1010, 310),cards[0].rect_global_position,Vector2(2,2), "Check card not dragged with mouse after dropping on table")
