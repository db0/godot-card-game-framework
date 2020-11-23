extends "res://addons/gut/test.gd"

var board
var hand
var cards := []
var common = UTCommon.new()

# Takes care of simple drag&drop requests
func drag_drop(card: Card, target_position: Vector2, interpolation_speed := "fast") -> void:
	var mouse_yield_wait: int
	var mouse_speed: int
	if interpolation_speed == "fast":
		mouse_yield_wait = 0.3
		mouse_speed = 10
	else:
		mouse_yield_wait = 0.6
		mouse_speed = 3
	card._on_Card_mouse_entered()
	common.click_card(card)
	yield(yield_for(0.5), YIELD) # Wait to allow dragging to start
	board._UT_interpolate_mouse_move(target_position,card.position,mouse_speed)
	yield(yield_for(mouse_yield_wait), YIELD)
	common.drop_card(card,board._UT_mouse_position)
	card._on_Card_mouse_exited()
	yield(yield_to(card.get_node('Tween'), "tween_all_completed", 1), YIELD)


func before_each():
	board = autoqfree(TestVars.new().boardScene.instance())
	get_tree().get_root().add_child(board)
	common.setup_board(board)
	cards = common.draw_test_cards(5)
	hand = cfc.NMAP.hand
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

	yield(drag_drop(cards[3],Vector2(300,300)), 'completed')
	yield(drag_drop(cards[2],Vector2(350,400)), 'completed')
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
