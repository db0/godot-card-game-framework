extends "res://addons/gut/test.gd"

var board
var hand
var cards := []
var common = UTCommon.new()

func before_each():
	board = autoqfree(TestVars.new().boardScene.instance())
	get_tree().get_root().add_child(board)
	common.setup_board(board)
	hand = cfc_config.NMAP.hand
	cards.clear()

func test_hand_z_index():
	for _iter in range(0,8):
		cards.append(hand.draw_card())
		yield(yield_for(0.07), YIELD)
	yield(yield_for(1), YIELD)
	for card in cards:
		assert_eq(0,card.z_index,"Check if card in hand at index 0")
	
func test_table_hand_z_index():
	for _iter in range(0,8):
		cards.append(hand.draw_card())
		yield(yield_for(0.07), YIELD)
	yield(yield_for(1), YIELD)
	cards[0]._on_Card_mouse_entered()
	common.click_card(cards[0])
	yield(yield_for(0.2), YIELD) # Wait to allow dragging to start
	board.UT_interpolate_mouse_move(Vector2(300,100),cards[0].position,6)	
	yield(yield_for(0.3), YIELD)
	common.drop_card(cards[0],board.UT_mouse_position)
	yield(yield_for(0.3), YIELD)
	cards[1]._on_Card_mouse_entered()
	common.click_card(cards[1])
	yield(yield_for(0.2), YIELD) # Wait to allow dragging to start
	board.UT_interpolate_mouse_move(Vector2(300,200),cards[0].position,6)	
	yield(yield_for(0.3), YIELD)
	common.drop_card(cards[1],board.UT_mouse_position)
	yield(yield_for(0.3), YIELD)
	cards[5]._on_Card_mouse_entered()
	common.click_card(cards[5])
	yield(yield_for(0.2), YIELD) # Wait to allow dragging to start
	board.UT_interpolate_mouse_move(Vector2(300,300),cards[0].position,6)	
	yield(yield_for(0.3), YIELD)
	common.drop_card(cards[5],board.UT_mouse_position)
	yield(yield_for(0.3), YIELD)
	cards[7]._on_Card_mouse_entered()
	common.click_card(cards[7])
	yield(yield_for(0.2), YIELD) # Wait to allow dragging to start
	board.UT_interpolate_mouse_move(Vector2(300,400),cards[0].position,6)	
	yield(yield_for(0.3), YIELD)
	common.drop_card(cards[7],board.UT_mouse_position)
	yield(yield_for(0.3), YIELD)
	cards[0]._on_Card_mouse_entered()
	common.click_card(cards[0])
	yield(yield_for(0.2), YIELD) # Wait to allow dragging to start
	board.UT_interpolate_mouse_move(Vector2(300,600),cards[0].position,3)	
	yield(yield_for(0.6), YIELD)
	common.drop_card(cards[0],board.UT_mouse_position)
	yield(yield_for(0.3), YIELD)
	cards.append(hand.draw_card())
	yield(yield_for(0.1), YIELD)
	cards.append(hand.draw_card())
	yield(yield_for(0.7), YIELD)
	cards[1]._on_Card_mouse_entered()
	common.click_card(cards[1])
	yield(yield_for(0.2), YIELD) # Wait to allow dragging to start
	board.UT_interpolate_mouse_move(Vector2(300,600),cards[0].position,3)	
	yield(yield_for(0.6), YIELD)
	common.drop_card(cards[1],board.UT_mouse_position)
	yield(yield_for(1), YIELD)
	for card in cards:
		if card.get_parent() == cfc_config.NMAP.hand:
			assert_eq(0,card.z_index,"Check if card in hand at index 0")
	
