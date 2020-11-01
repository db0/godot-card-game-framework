extends "res://addons/gut/test.gd"

var Board

func before_each():
	Board = autoqfree(load("res://Board.tscn").instance())
	self.add_child(Board)

func test_single_card_draw():
	var card0: Card = $Board/Hand.draw_card()
	assert_eq(len($Board/Hand.get_children()), 1, "Check correct amount of cards drawn")
	assert_true(card0.visible, "Check that cards drawn is visible")
	yield(yield_to(card0.get_node('Tween'), "tween_all_completed", 1), YIELD)
	yield(yield_to(card0.get_node('Tween'), "tween_all_completed", 1), YIELD)
	assert_almost_eq(Vector2(565,600),card0.rect_global_position,Vector2(2,2), "Check card placed in correct global position")

func test_draw_multiple_cards_slow():
	var card0: Card = $Board/Hand.draw_card()
	yield(yield_to(card0.get_node('Tween'), "tween_all_completed", 1), YIELD)
	yield(yield_to(card0.get_node('Tween'), "tween_all_completed", 1), YIELD)
	var card1: Card = $Board/Hand.draw_card()
	yield(yield_to(card1.get_node('Tween'), "tween_all_completed", 1), YIELD)
	yield(yield_to(card1.get_node('Tween'), "tween_all_completed", 1), YIELD)
	assert_almost_eq(Vector2(482.5, 600),card0.rect_global_position,Vector2(2,2), "Check card at index 0 placed in correct global position")
	assert_almost_eq(Vector2(647.5, 600),card1.rect_global_position,Vector2(2,2), "Check card at index 1 placed in correct global position")
	var card2: Card = $Board/Hand.draw_card()
	yield(yield_to(card2.get_node('Tween'), "tween_all_completed", 1), YIELD)
	yield(yield_to(card2.get_node('Tween'), "tween_all_completed", 1), YIELD)
	assert_almost_eq(Vector2(400, 600),card0.rect_global_position,Vector2(2,2), "Check card at index 0 placed in correct global position")
	assert_almost_eq(Vector2(565, 600),card1.rect_global_position,Vector2(2,2), "Check card at index 1 placed in correct global position")
	assert_almost_eq(Vector2(730, 600),card2.rect_global_position,Vector2(2,2), "Check card at index 2 placed in correct global position")

func test_draw_multiple_cards_fast():
	var card0: Card = $Board/Hand.draw_card()
	yield(yield_for(0.2), YIELD)
	var card1: Card = $Board/Hand.draw_card()
	yield(yield_for(0.1), YIELD)
	var card2: Card = $Board/Hand.draw_card()
	yield(yield_for(0.3), YIELD)
	var card3: Card = $Board/Hand.draw_card()
	yield(yield_for(0.5), YIELD)
	var card4: Card = $Board/Hand.draw_card()
	yield(yield_for(0.1), YIELD)
	var card5: Card = $Board/Hand.draw_card()
	yield(yield_to(card5.get_node('Tween'), "tween_all_completed", 1), YIELD)
	yield(yield_to(card5.get_node('Tween'), "tween_all_completed", 1), YIELD)
	assert_almost_eq(Vector2(188, 600),card0.rect_global_position,Vector2(2,2), "Check card at index 0 placed in correct global position")
	assert_almost_eq(Vector2(338.75, 600),card1.rect_global_position,Vector2(2,2), "Check card at index 1 placed in correct global position")
	assert_almost_eq(Vector2(490, 600),card2.rect_global_position,Vector2(2,2), "Check card at index 2 placed in correct global position")
	assert_almost_eq(Vector2(640, 600),card3.rect_global_position,Vector2(2,2), "Check card at index 3 placed in correct global position")
	assert_almost_eq(Vector2(790, 600),card4.rect_global_position,Vector2(2,2), "Check card at index 4 placed in correct global position")
	assert_almost_eq(Vector2(942, 600),card5.rect_global_position,Vector2(2,2), "Check card at index 5 placed in correct global position")

