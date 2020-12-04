extends "res://tests/UTcommon.gd"

var cards := []

func before_each():
	setup_board()
	cards = draw_test_cards(5)
	yield(yield_for(1), YIELD)


func test_card_table_drop_location_and_rotation():
	# Reminder that card should not have trigger script definitions, to avoid
	# messing with the tests
	var card = cards[1]
	card._on_Card_mouse_entered()
	click_card(card)
	yield(yield_for(0.5), YIELD) # Wait to allow dragging to start
	board._UT_interpolate_mouse_move(Vector2(300,300),card.global_position)
	yield(yield_for(0.6), YIELD)
	board._UT_interpolate_mouse_move(Vector2(800,200))
	yield(yield_for(0.6), YIELD)
	drop_card(card,board._UT_mouse_position)
	yield(yield_to(card._tween, "tween_all_completed", 1), YIELD)
	assert_almost_eq(Vector2(800, 200),card.global_position,Vector2(2,2),
			"Card dragged in correct global position")
	card.card_rotation = 90
	yield(yield_to(card._tween, "tween_all_completed", 1), YIELD)
	assert_almost_eq(90.0,card.get_node("Control").rect_rotation,2.0,
			"Card rotates 90")
	card.card_rotation = 180
	yield(yield_to(card._tween, "tween_all_completed", 1), YIELD)
	assert_almost_eq(180.0,card.get_node("Control").rect_rotation,2.0,
			"Card rotates 180")
	card.set_card_rotation(180,true)
	yield(yield_to(card._tween, "tween_all_completed", 1), YIELD)
	assert_almost_eq(180.0,card.get_node("Control").rect_rotation,2.0,
			"Card rotation doesn't revert without toggle")
	card.set_card_rotation(180,true)
	yield(yield_to(card._tween, "tween_all_completed", 1), YIELD)
	assert_almost_eq(0.0,card.get_node("Control").rect_rotation,2.0,
			"Card rotation toggle works to reset to 0")
	assert_eq(2,card.set_card_rotation(111),
			"Setting rotation to an invalid value fails")
	assert_eq(2,cards[0].set_card_rotation(180),
			"Changing rotation to a card outside table fails")
	card._on_Card_mouse_entered()
	assert_eq(1,card.set_card_rotation(270),
			"Rotation changed when card is focused")
	click_card(card)
	yield(yield_for(0.5), YIELD) # Wait to allow dragging to start
	board._UT_interpolate_mouse_move(Vector2(1000,100),card.global_position)
	yield(yield_for(0.3), YIELD)
	assert_eq(270,card.card_rotation,
			"Rotation remains while card is being dragged")
	yield(yield_for(0.3), YIELD)
	board._UT_interpolate_mouse_move(cfc.NMAP.discard.position)
	yield(yield_for(0.6), YIELD)
	drop_card(card,board._UT_mouse_position)
	yield(yield_to(card._tween, "tween_all_completed", 0.5), YIELD)
	yield(yield_to(card._tween, "tween_all_completed", 0.5), YIELD)
	if cfc.hand_use_oval_shape:
		pass
	else:
		assert_eq(0.0,card.get_node("Control").rect_rotation,
				"Rotation reset to 0 when card moved off board")

func test_card_hand_drop_recovery():
	var card = cards[1]
	card._on_Card_mouse_entered()
	click_card(card)
	yield(yield_for(0.5), YIELD) # Wait to allow dragging to start
	board._UT_interpolate_mouse_move(Vector2(100,100),card.global_position)
	yield(yield_for(0.4), YIELD)
	board._UT_interpolate_mouse_move(Vector2(200,620))
	yield(yield_for(0.4), YIELD)
	drop_card(card,board._UT_mouse_position)
	yield(yield_to(card._tween, "tween_all_completed", 1), YIELD)
	assert_eq(hand.get_card_count(),5,
			"Card dragged back in hand remains in hand")

func test_card_drag_block_by_board_borders():
	cards[4]._on_Card_mouse_entered()
	click_card(cards[4])
	yield(yield_for(0.5), YIELD) # Wait to allow dragging to start
	board._UT_interpolate_mouse_move(Vector2(-100,100),cards[0].global_position)
	yield(yield_for(0.4), YIELD)
	assert_almost_eq(Vector2(0, 100),cards[4].global_position,Vector2(2,2),
			"Dragged outside left viewport borders stays inside viewport")
	board._UT_interpolate_mouse_move(Vector2(1300,300))
	yield(yield_for(0.4), YIELD)
	assert_almost_eq(Vector2(1220, 300),cards[4].global_position,Vector2(2,2),
			"Dragged outside right viewport borders stays inside viewport")
	board._UT_interpolate_mouse_move(Vector2(800,-100))
	yield(yield_for(0.4), YIELD)
	assert_almost_eq(Vector2(800, 0),cards[4].global_position,Vector2(2,2),
			"Dragged outside top viewport borders stays inside viewport")
	board._UT_interpolate_mouse_move(Vector2(500,800))
	yield(yield_for(0.4), YIELD)
	assert_almost_eq(Vector2(500, 624),cards[4].global_position,Vector2(2,2),
			"Dragged outside bottom viewport borders stays inside viewport")


func test_fast_card_table_drop():
	# This catches a bug where the card keeps following the mouse after being dropped
	cards[0]._on_Card_mouse_entered()
	click_card(cards[0])
	yield(yield_for(0.5), YIELD) # Wait to allow dragging to start
	board._UT_interpolate_mouse_move(Vector2(1000, 300),cards[0].global_position)
	yield(yield_for(0.6), YIELD)
	drop_card(cards[0],board._UT_mouse_position)
	yield(yield_to(cards[0]._tween, "tween_all_completed", 1), YIELD)
	board._UT_interpolate_mouse_move(Vector2(400,200),cards[0].global_position)
	yield(yield_for(0.6), YIELD)
	board._UT_interpolate_mouse_move(Vector2(1000,500),cards[0].global_position)
	yield(yield_for(0.6), YIELD)
	assert_almost_eq(Vector2(1000, 300),cards[0].global_position,Vector2(2,2),
			"Card not dragged with mouse after dropping on table")

func test_board_to_board_move():
	var card: Card
	card = cards[0]
	yield(table_move(card, Vector2(100,200)), "completed")
	card.card_rotation = 90
	yield(drag_drop(card, Vector2(800,200)), 'completed')
	assert_eq(90.0,card.get_node("Control").rect_rotation,
			"Card should stay in the same rotation when moved around the board")
