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

func test_move_to_container():
	yield(yield_for(1), YIELD)

	cards[2]._on_Card_mouse_entered()
	common.click_card(cards[2])
	yield(yield_for(0.3), YIELD) # Wait to allow dragging to start
	board.UT_interpolate_mouse_move(cfc_config.NMAP.discard.position,cards[2].position)
	yield(yield_for(0.6), YIELD) # Wait to allow dragging to start
	common.drop_card(cards[2],board.UT_mouse_position)
	yield(yield_for(1), YIELD)
	assert_almost_eq(cards[2].global_position,cfc_config.NMAP.discard.position,Vector2(2,2), "Confirm Card's final position matches pile's position")
	assert_eq(1,cfc_config.NMAP.discard.get_card_count(), "Confirm the correct amount of cards are hosted")

func test_move_to_multiple_container():
	yield(yield_for(1), YIELD)
	cards[2]._on_Card_mouse_entered()
	common.click_card(cards[2])
	yield(yield_for(0.3), YIELD) # Wait to allow dragging to start
	board.UT_interpolate_mouse_move(cfc_config.NMAP.discard.position,cards[2].position)
	yield(yield_for(0.6), YIELD) # Wait to allow dragging to start
	common.drop_card(cards[2],board.UT_mouse_position)
	yield(yield_for(0.1), YIELD)
	cards[4]._on_Card_mouse_entered()
	common.click_card(cards[4])
	yield(yield_for(0.3), YIELD) # Wait to allow dragging to start
	board.UT_interpolate_mouse_move(cfc_config.NMAP.deck.position,cards[4].position)
	yield(yield_for(0.6), YIELD) # Wait to allow dragging to start
	common.drop_card(cards[4],board.UT_mouse_position)
	yield(yield_for(0.1), YIELD)
	cards[1]._on_Card_mouse_entered()
	common.click_card(cards[1])
	yield(yield_for(0.3), YIELD) # Wait to allow dragging to start
	board.UT_interpolate_mouse_move(cfc_config.NMAP.discard.position,cards[1].position)
	yield(yield_for(0.6), YIELD) # Wait to allow dragging to start
	common.drop_card(cards[1],board.UT_mouse_position)
	yield(yield_for(0.1), YIELD)
	cards[0]._on_Card_mouse_entered()
	common.click_card(cards[0])
	yield(yield_for(0.3), YIELD) # Wait to allow dragging to start
	board.UT_interpolate_mouse_move(cfc_config.NMAP.deck.position,cards[0].position)
	yield(yield_for(0.6), YIELD) # Wait to allow dragging to start
	common.drop_card(cards[0],board.UT_mouse_position)
	yield(yield_for(1), YIELD)
	assert_almost_eq(cards[2].global_position,cfc_config.NMAP.discard.global_position,Vector2(2,2), "Confirm Card 2 final position matches pile's position")
	assert_almost_eq(cards[1].global_position,cfc_config.NMAP.discard.global_position,Vector2(2,2), "Confirm Card 1 final position matches pile's position")
	assert_almost_eq(cards[4].global_position,cfc_config.NMAP.deck.position,Vector2(2,2), "Confirm Card 3 final position matches pile's position")
	assert_almost_eq(cards[0].global_position,cfc_config.NMAP.deck.position,Vector2(2,2), "Confirm Card 0 final position matches pile's position")
	assert_eq(2,cfc_config.NMAP.discard.get_card_count(), "Confirm the correct amount of cards are hosted in discard")
	assert_eq(17,cfc_config.NMAP.deck.get_card_count(), "Confirm the correct amount of cards are hosted in deck")
	assert_eq(1,cfc_config.NMAP.hand.get_card_count(), "Confirm the correct amount of cards are hosted in hand")
#
#func test_board_container_interaction():
#	pending("Check that card from board moves correctly to new position on board")
#	pending("Check that card from board moves correctly back to hand")
