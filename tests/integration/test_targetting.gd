extends "res://tests/UTcommon.gd"

var cards := []

func before_all():
	cfc.fancy_movement = false

func after_all():
	cfc.fancy_movement = true

func before_each():
	setup_board()
	cards = draw_test_cards(5)
	yield(yield_for(1), YIELD)


func test_targetting():
	var card: Card
	card = cards[0]
	card.initiate_targeting()
	board._UT_interpolate_mouse_move(cards[4].global_position,card.global_position,3)
	yield(yield_for(0.6), YIELD)
	assert_lt(0,card.get_node("TargetLine").get_point_count( ),
			"test that TargetLine has length higher than 1 while active")
	assert_true(card.get_node("TargetLine/ArrowHead").visible,
			"test that arrowhead is visible on once active")
	assert_true(cards[4].get_node('Control/FocusHighlight').visible,
			"Test that a card hovering over another with attachment flag on, highlights it")
	assert_eq(cards[4].get_node('Control/FocusHighlight').modulate, cfc.TARGET_HOVER_COLOUR,
			"Test that a hovered target has the right colour highlight")
	card.complete_targeting()
	assert_eq(card.target_card,cards[4],
			"Test that card in hand can target card in hand")
	assert_eq(0,card.get_node("TargetLine").get_point_count( ),
			"test that TargetLine has no points once inactive")
	assert_false(card.get_node("TargetLine/ArrowHead").visible,
			"test that arrowhead is not visible on once inactive")
	assert_false(cards[4].get_node('Control/FocusHighlight').visible,
			"Test that a highlights disappears once targetting ends")

	yield(table_move(cards[3],Vector2(300,300)), 'completed')
	yield(table_move(cards[2],Vector2(350,400)), 'completed')
	card.initiate_targeting()
	board._UT_interpolate_mouse_move(cards[2].global_position,card.global_position,3)
	yield(yield_for(0.6), YIELD)
	assert_true(cards[2].get_node('Control/FocusHighlight').visible,
			"test that hovering over multiple cards selects the top one")
	assert_false(cards[3].get_node('Control/FocusHighlight').visible,
			"test that hovering over multiple cards does not highlight bottom ones")
	card.complete_targeting()
	assert_eq(card.target_card,cards[2],
			"Test that card in hand can target card on board")

	card = cards[2]
	card.initiate_targeting()
	board._UT_interpolate_mouse_move(cards[3].global_position,card.global_position,3)
	yield(yield_for(0.6), YIELD)
	card.complete_targeting()
	assert_eq(card.target_card,cards[3],
			"Test that card on board can target card on board")
	card.initiate_targeting()
	board._UT_interpolate_mouse_move(cards[2].global_position,card.global_position,3)
	yield(yield_for(0.6), YIELD)
	card.complete_targeting()
	assert_eq(card.target_card,cards[2],
			"Test that card can target itself")
	card.initiate_targeting()
	board._UT_interpolate_mouse_move(cards[1].global_position,card.global_position,3)
	yield(yield_for(0.6), YIELD)
	card.complete_targeting()
	assert_eq(card.target_card,cards[1],
			"Test that card on board can target card in hand")
