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

func test_fancy_reshuffle_all():
	cfc_config.fancy_movement = true
	yield(yield_for(1), YIELD)
	cards[0]._on_Card_mouse_entered()
	common.click_card(cards[0])
	yield(yield_for(0.3), YIELD) # Wait to allow dragging to start
	board.UT_interpolate_mouse_move(Vector2(300,300),cards[0].global_position)
	yield(yield_for(0.6), YIELD)
	common.drop_card(cards[0],board.UT_mouse_position)
	yield(yield_to(cards[0].get_node('Tween'), "tween_all_completed", 1), YIELD)
	cards[4]._on_Card_mouse_entered()
	common.click_card(cards[4])
	yield(yield_for(0.3), YIELD) # Wait to allow dragging to start
	board.UT_interpolate_mouse_move(Vector2(1000,10),cards[0].global_position)
	yield(yield_for(0.6), YIELD)
	common.drop_card(cards[4],board.UT_mouse_position)
	yield(yield_to(cards[4].get_node('Tween'), "tween_all_completed", 1), YIELD)
	board._on_ReshuffleAll_pressed()
	yield(yield_for(0.02), YIELD)
	assert_almost_eq(Vector2(310, 310),cards[0].global_position,Vector2(10,10), "Check that card is not being teleported from where is expect by Tween")
	assert_almost_eq(Vector2(1010, 20),cards[4].global_position,Vector2(10,10), "Check that card is not being teleported from where is expect by Tween")
	yield(yield_to(cards[4].get_node('Tween'), "tween_all_completed", 1), YIELD)

func test_basic_reshuffle_all():
	cfc_config.fancy_movement = false
	yield(yield_for(1), YIELD)
	cards[0]._on_Card_mouse_entered()
	common.click_card(cards[0])
	yield(yield_for(0.3), YIELD) # Wait to allow dragging to start
	board.UT_interpolate_mouse_move(Vector2(300,300),cards[0].global_position)
	yield(yield_for(0.6), YIELD)
	common.drop_card(cards[0],board.UT_mouse_position)
	yield(yield_to(cards[0].get_node('Tween'), "tween_all_completed", 1), YIELD)
	cards[4]._on_Card_mouse_entered()
	common.click_card(cards[4])
	yield(yield_for(0.3), YIELD) # Wait to allow dragging to start
	board.UT_interpolate_mouse_move(Vector2(1000,10),cards[0].global_position)
	yield(yield_for(0.6), YIELD)
	common.drop_card(cards[4],board.UT_mouse_position)
	yield(yield_to(cards[4].get_node('Tween'), "tween_all_completed", 1), YIELD)
	board._on_ReshuffleAll_pressed()
	yield(yield_for(0.018), YIELD)
	assert_almost_eq(Vector2(310, 310),cards[0].global_position,Vector2(10,10), "Check that card is not being teleported from where is expect by Tween")
	assert_almost_eq(Vector2(1010, 20),cards[4].global_position,Vector2(10,10), "Check that card is not being teleported from where is expect by Tween")
	yield(yield_to(cards[4].get_node('Tween'), "tween_all_completed", 1), YIELD)
	
