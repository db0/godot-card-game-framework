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
	hand = cfc.NMAP.hand
	yield(yield_for(1), YIELD)

func test_move_to_container():
	cards[2]._on_Card_mouse_entered()
	common.click_card(cards[2])
	yield(yield_for(0.3), YIELD) # Wait to allow dragging to start
	board._UT_interpolate_mouse_move(cfc.NMAP.discard.position,cards[2].position)
	yield(yield_for(0.6), YIELD) # Wait to allow dragging to start
	common.drop_card(cards[2],board._UT_mouse_position)
	yield(yield_for(1), YIELD)
	assert_almost_eq(cards[2].global_position,cfc.NMAP.discard.position,Vector2(2,2), "Confirm Card's final position matches pile's position")
	assert_eq(1,cfc.NMAP.discard.get_card_count(), "Confirm the correct amount of cards are hosted")

func test_move_to_multiple_container():
	cards[2]._on_Card_mouse_entered()
	common.click_card(cards[2])
	yield(yield_for(0.3), YIELD) # Wait to allow dragging to start
	board._UT_interpolate_mouse_move(cfc.NMAP.discard.position,cards[2].position)
	yield(yield_for(0.6), YIELD) # Wait to allow dragging to start
	common.drop_card(cards[2],board._UT_mouse_position)
	yield(yield_for(0.1), YIELD)
	cards[4]._on_Card_mouse_entered()
	common.click_card(cards[4])
	yield(yield_for(0.3), YIELD) # Wait to allow dragging to start
	board._UT_interpolate_mouse_move(cfc.NMAP.deck.position,cards[4].position)
	yield(yield_for(0.6), YIELD) # Wait to allow dragging to start
	common.drop_card(cards[4],board._UT_mouse_position)
	yield(yield_for(0.1), YIELD)
	cards[1]._on_Card_mouse_entered()
	common.click_card(cards[1])
	yield(yield_for(0.3), YIELD) # Wait to allow dragging to start
	board._UT_interpolate_mouse_move(cfc.NMAP.discard.position,cards[1].position)
	yield(yield_for(0.6), YIELD) # Wait to allow dragging to start
	common.drop_card(cards[1],board._UT_mouse_position)
	yield(yield_for(0.1), YIELD)
	cards[0]._on_Card_mouse_entered()
	common.click_card(cards[0])
	yield(yield_for(0.3), YIELD) # Wait to allow dragging to start
	board._UT_interpolate_mouse_move(cfc.NMAP.deck.position,cards[0].position)
	yield(yield_for(0.6), YIELD) # Wait to allow dragging to start
	common.drop_card(cards[0],board._UT_mouse_position)
	yield(yield_for(1), YIELD)
	assert_almost_eq(cards[2].global_position,cfc.NMAP.discard.global_position,Vector2(2,2), "Confirm Card 2 final position matches pile's position")
	assert_almost_eq(cards[1].global_position,cfc.NMAP.discard.global_position,Vector2(2,2), "Confirm Card 1 final position matches pile's position")
	assert_almost_eq(cards[4].global_position,cfc.NMAP.deck.position,Vector2(2,2), "Confirm Card 3 final position matches pile's position")
	assert_almost_eq(cards[0].global_position,cfc.NMAP.deck.position,Vector2(2,2), "Confirm Card 0 final position matches pile's position")
	assert_eq(2,cfc.NMAP.discard.get_card_count(), "Confirm the correct amount of cards are hosted in discard")
	assert_eq(12,cfc.NMAP.deck.get_card_count(), "Confirm the correct amount of cards are hosted in deck")
	assert_eq(1,cfc.NMAP.hand.get_card_count(), "Confirm the correct amount of cards are hosted in hand")

func test_pile_functions():
	pending("Check that shuffle really does shuffle")

func test_popup_view():
	pending("Check that all cards all migrated to popup window")
	pending("Check that requesting all cards, includes cards in then popup")
	pending("Check that drawing a card from the pile, picks it from the popup")
	pending("Check that hosting a card in the pile, puts it in the popup")
