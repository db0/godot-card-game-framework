extends "res://addons/gut/test.gd"

var board
var hand
var cards := []
var common = UTCommon.new()

func before_each():
	board = autoqfree(TestVars.new().boardScene.instance())
	get_tree().get_root().add_child(board)
	common.setup_board(board)
	cards = common.draw_test_cards(5)
	hand = cfc_config.NMAP.hand
	yield(yield_for(1), YIELD)


func test_card_table_drop_location():
	cards[0]._on_Card_mouse_entered()
	common.click_card(cards[0])
	yield(yield_for(0.3), YIELD) # Wait to allow dragging to start
	board.UT_interpolate_mouse_move(Vector2(300,300),cards[0].position)
	yield(yield_for(0.6), YIELD)
	board.UT_interpolate_mouse_move(Vector2(800,200))
	yield(yield_for(0.6), YIELD)
	common.drop_card(cards[0],board.UT_mouse_position)
	yield(yield_to(cards[0].get_node('Tween'), "tween_all_completed", 1), YIELD)
	assert_almost_eq(Vector2(800, 200),cards[0].position,Vector2(2,2), "Check card dragged in correct global position")

func test_card_hand_drop_recovery():
	cards[0]._on_Card_mouse_entered()
	common.click_card(cards[0])
	yield(yield_for(0.3), YIELD) # Wait to allow dragging to start
	board.UT_interpolate_mouse_move(Vector2(100,100),cards[0].position)
	yield(yield_for(0.4), YIELD)
	board.UT_interpolate_mouse_move(Vector2(200,620))
	yield(yield_for(0.4), YIELD)
	common.drop_card(cards[0],board.UT_mouse_position)
	yield(yield_to(cards[0].get_node('Tween'), "tween_all_completed", 1), YIELD)
	assert_eq(hand.get_card_count(),5, "Check card dragged back in hand remains in hand")

func test_card_drag_block_by_board_borders():
	cards[4]._on_Card_mouse_entered()
	common.click_card(cards[4])
	yield(yield_for(0.3), YIELD) # Wait to allow dragging to start
	board.UT_interpolate_mouse_move(Vector2(-100,100),cards[0].global_position)
	yield(yield_for(0.4), YIELD)
	assert_almost_eq(Vector2(0, 100),cards[4].global_position,Vector2(2,2), "Check dragged outside left viewport borders stays inside viewport")
	board.UT_interpolate_mouse_move(Vector2(1300,300))
	yield(yield_for(0.4), YIELD)
	assert_almost_eq(Vector2(1220, 300),cards[4].global_position,Vector2(2,2), "Check dragged outside right viewport borders stays inside viewport")
	board.UT_interpolate_mouse_move(Vector2(800,-100))
	yield(yield_for(0.4), YIELD)
	assert_almost_eq(Vector2(800, 0),cards[4].global_position,Vector2(2,2), "Check dragged outside top viewport borders stays inside viewport")
	board.UT_interpolate_mouse_move(Vector2(500,800))
	yield(yield_for(0.4), YIELD)
	assert_almost_eq(Vector2(500, 624),cards[4].global_position,Vector2(2,2), "Check dragged outside bottom viewport borders stays inside viewport")


func test_fast_card_table_drop():
	# This catches a bug where the card keeps following the mouse after being dropped
	cards[0]._on_Card_mouse_entered()
	common.click_card(cards[0])
	yield(yield_for(0.3), YIELD) # Wait to allow dragging to start
	board.UT_interpolate_mouse_move(Vector2(1000, 300),cards[0].position,3)
	yield(yield_for(0.6), YIELD)
	common.drop_card(cards[0],board.UT_mouse_position)
	yield(yield_to(cards[0].get_node('Tween'), "tween_all_completed", 1), YIELD)
	board.UT_interpolate_mouse_move(Vector2(400,200),cards[0].position,3)
	yield(yield_for(0.6), YIELD)
	board.UT_interpolate_mouse_move(Vector2(1000,500),cards[0].position,3)
	yield(yield_for(0.6), YIELD)
	assert_almost_eq(Vector2(1000, 300),cards[0].position,Vector2(2,2), "Check card not dragged with mouse after dropping on table")
