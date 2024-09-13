extends "res://tests/UTcommon.gd"

var cards := []

func before_all():
	cfc.game_settings.fancy_movement = false

func after_all():
	cfc.game_settings.fancy_movement = true

func before_each():
	await setup_board()
	cards = draw_test_cards(5)
	await yield_for(0.1)


func test_targetting():
	var card: Card
	card = cards[0]
	card.targeting_arrow.initiate_targeting()
	await move_mouse(cards[4].global_position)
	assert_lt(0,card.targeting_arrow.get_point_count(),
			"test that TargetLine has length higher than 1 while active")
	assert_true(card.targeting_arrow.get_node("ArrowHead").visible,
			"test that arrowhead is visible on once active")
	assert_true(cards[4].highlight.visible,
			"Test that a target arrow hovering over another card, highlights it")
	assert_eq(cards[4].highlight.modulate, CFConst.TARGET_HOVER_COLOUR,
			"Test that a hovered target has the right colour highlight")
	card.targeting_arrow.complete_targeting()
	assert_eq(card.targeting_arrow.target_object,cards[4],
			"Test that card in hand can target card in hand")
	assert_eq(0,card.targeting_arrow.get_point_count(),
			"test that TargetLine has no points once inactive")
	assert_false(card.targeting_arrow.get_node("ArrowHead").visible,
			"test that arrowhead is not visible on once inactive")
	assert_false(cards[4].highlight.visible,
			"Test that a highlights disappears once targetting ends")

	await table_move(cards[3],Vector2(300,300))
	await table_move(cards[2],Vector2(350,400))
	card.targeting_arrow.initiate_targeting()
	board._UT_interpolate_mouse_move(cards[2].global_position,card.global_position,3)
	await yield_for(0.6)
	assert_true(cards[2].highlight.visible,
			"test that hovering over multiple cards selects the top one")
	assert_false(cards[3].highlight.visible,
			"test that hovering over multiple cards does not highlight bottom ones")
	card.targeting_arrow.complete_targeting()
	assert_eq(card.targeting_arrow.target_object,cards[2],
			"Test that card in hand can target card on board")

	card = cards[2]
	card.targeting_arrow.initiate_targeting()
	board._UT_interpolate_mouse_move(cards[3].global_position,card.global_position,3)
	await yield_for(0.6)
	card.targeting_arrow.complete_targeting()
	assert_eq(card.targeting_arrow.target_object,cards[3],
			"Test that card on board can target card on board")
	card.targeting_arrow.initiate_targeting()
	board._UT_interpolate_mouse_move(cards[2].global_position,card.global_position,3)
	await yield_for(0.6)
	card.targeting_arrow.complete_targeting()
	assert_eq(card.targeting_arrow.target_object,cards[2],
			"Test that card can target itself")
	card.targeting_arrow.initiate_targeting()
	board._UT_interpolate_mouse_move(cards[1].global_position,card.global_position,3)
	await yield_for(0.6)
	card.targeting_arrow.complete_targeting()
	assert_eq(card.targeting_arrow.target_object,cards[1],
			"Test that card on board can target card in hand")

func test_signals():
	var card: Card
	card = cards[0]
	watch_signals(card.targeting_arrow)
	card.targeting_arrow.initiate_targeting()
	assert_signal_emitted(card.targeting_arrow,"initiated_targeting",
			"initiated_targeting emited")
	await move_mouse(Vector2(1000,100))
	card.targeting_arrow.complete_targeting()
	assert_signal_emitted(card.targeting_arrow,"target_selected",
			"Targetting empty space, still emits target_selected")
