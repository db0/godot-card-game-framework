extends "res://addons/gut/test.gd"

var board
var hand
var common = UTCommon.new()

func before_each():
	board = autoqfree(TestVars.new().boardScene.instance())
	get_tree().get_root().add_child(board)
	common.setup_board(board)
	hand = cfc_config.NMAP.hand

func test_single_card_draw():
	var card0: Card = hand.draw_card()
	assert_eq(len(hand.get_children()), 3, "Check correct amount of cards drawn")
	assert_true(card0.visible, "Check that cards drawn is visible")
	yield(yield_to(card0.get_node('Tween'), "tween_all_completed", 1), YIELD)
	yield(yield_to(card0.get_node('Tween'), "tween_all_completed", 1), YIELD)
	assert_almost_eq(415.0,card0.recalculatePosition().x,2.0, "Check that card position x is recalculated correctly")
	assert_almost_eq(120.0,card0.recalculatePosition().y,2.0, "Check that card position y is recalculated correctly")
	assert_almost_eq(hand.to_global(card0.recalculatePosition()),card0.rect_global_position,Vector2(2,2), "Check card placed in correct global position")
	assert_almost_eq(card0.recalculatePosition(),card0.rect_position,Vector2(2,2), "Check card placed in correct position")

func test_draw_multiple_cards_slow():
	var card0: Card = hand.draw_card()
	yield(yield_to(card0.get_node('Tween'), "tween_all_completed", 1), YIELD)
	yield(yield_to(card0.get_node('Tween'), "tween_all_completed", 1), YIELD)
	var card1: Card = hand.draw_card()
	yield(yield_to(card1.get_node('Tween'), "tween_all_completed", 1), YIELD)
	yield(yield_to(card1.get_node('Tween'), "tween_all_completed", 1), YIELD)
	assert_almost_eq(card0.recalculatePosition(),card0.rect_position,Vector2(2,2), "Check card at index 0 placed in correct position")
	assert_almost_eq(card1.recalculatePosition(),card1.rect_position,Vector2(2,2), "Check card at index 1 placed in correct position")
	var card2: Card = hand.draw_card()
	yield(yield_to(card2.get_node('Tween'), "tween_all_completed", 1), YIELD)
	yield(yield_to(card2.get_node('Tween'), "tween_all_completed", 1), YIELD)
	assert_almost_eq(250.0,card0.recalculatePosition().x,2.0, "Check that index 0 card position x is recalculated correctly")
	assert_almost_eq(120.0,card0.recalculatePosition().y,2.0, "Check that index 0 card position y is recalculated correctly")
	assert_almost_eq(415.0,card1.recalculatePosition().x,2.0, "Check that index 1 card position x is recalculated correctly")
	assert_almost_eq(120.0,card1.recalculatePosition().y,2.0, "Check that index 1 card position y is recalculated correctly")
	assert_almost_eq(580.0,card2.recalculatePosition().x,2.0, "Check that index 2 card position x is recalculated correctly")
	assert_almost_eq(120.0,card2.recalculatePosition().y,2.0, "Check that index 2 card position y is recalculated correctly")
	assert_almost_eq(card0.recalculatePosition(),card0.rect_position,Vector2(2,2), "Check card at index 0 placed in correct position")
	assert_almost_eq(card1.recalculatePosition(),card1.rect_position,Vector2(2,2), "Check card at index 1 placed in correct position")
	assert_almost_eq(card2.recalculatePosition(),card2.rect_position,Vector2(2,2), "Check card at index 2 placed in correct position")

func test_draw_multiple_cards_fast():
	var card0: Card = hand.draw_card()
	yield(yield_for(0.2), YIELD)
	var card1: Card = hand.draw_card()
	yield(yield_for(0.1), YIELD)
	var card2: Card = hand.draw_card()
	yield(yield_for(0.3), YIELD)
	var card3: Card = hand.draw_card()
	yield(yield_for(0.5), YIELD)
	var card4: Card = hand.draw_card()
	yield(yield_for(0.1), YIELD)
	var card5: Card = hand.draw_card()
	yield(yield_to(card5.get_node('Tween'), "tween_all_completed", 1), YIELD)
	yield(yield_to(card5.get_node('Tween'), "tween_all_completed", 1), YIELD)
	assert_almost_eq(card0.recalculatePosition(),card0.rect_position,Vector2(2,2), "Check card at index 0 placed in correct position")
	assert_almost_eq(card1.recalculatePosition(),card1.rect_position,Vector2(2,2), "Check card at index 1 placed in correct position")
	assert_almost_eq(card2.recalculatePosition(),card2.rect_position,Vector2(2,2), "Check card at index 2 placed in correct position")
	assert_almost_eq(card3.recalculatePosition(),card3.rect_position,Vector2(2,2), "Check card at index 3 placed in correct position")
	assert_almost_eq(card4.recalculatePosition(),card4.rect_position,Vector2(2,2), "Check card at index 4 placed in correct position")
	assert_almost_eq(card5.recalculatePosition(),card5.rect_position,Vector2(2,2), "Check card at index 5 placed in correct position")

func test_container_custom_card_functions():
	var card0: Card = hand.draw_card()
	var card1: Card = hand.draw_card()
	var card2: Card = hand.draw_card()
	var card3: Card = hand.draw_card()
	var card4: Card = hand.draw_card()
	var card5: Card = hand.draw_card()
	yield(yield_to(card5.get_node('Tween'), "tween_all_completed", 1), YIELD)
	assert_eq(len(hand.get_all_cards()), 6, "Check that get_all_cards() returns right amount of cards")
	assert_eq(hand.get_card_count(), 6, "Check that get_card_count() returns right amount of cards")
	assert_eq(hand.get_card(4), card4, "Check that get_card() returns the card at the correct index")
	assert_eq(hand.get_card_index(card4), 4, "Check that get_card_index() returns the correct index")
	
