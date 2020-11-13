extends "res://addons/gut/test.gd"

var board
var hand
var cards := []
var common = UTCommon.new()

	
func drag_and_drop_card(card: Card, drop_location: Vector2) -> void:
	# Doesn't work due to https://github.com/bitwes/Gut/issues/247
	card._on_Card_mouse_entered()
	common.click_card(card)
	yield(yield_for(0.3), YIELD) # Wait to allow dragging to start
	board.UT_interpolate_mouse_move(drop_location,card.position,6)	
	yield(yield_for(0.3), YIELD)
	common.drop_card(card,board.UT_mouse_position)
	card._on_Card_mouse_exited()
	yield(yield_for(0.3), YIELD)

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
#	drag_and_drop_card(cards[0],Vector2(300,100))
#	drag_and_drop_card(cards[1],Vector2(300,200))
#	drag_and_drop_card(cards[5],Vector2(300,300))
#	drag_and_drop_card(cards[7],Vector2(300,400))
	var card: Card

	card = cards[0]
	card._on_Card_mouse_entered()
	common.click_card(card)
	yield(yield_for(0.2), YIELD) # Wait to allow dragging to start
	board.UT_interpolate_mouse_move(Vector2(300,100),card.position,6)	
	yield(yield_for(0.3), YIELD)
	common.drop_card(card,board.UT_mouse_position)
	card._on_Card_mouse_exited()
	yield(yield_for(0.3), YIELD)
	
	card = cards[1]
	card._on_Card_mouse_entered()
	common.click_card(card)
	yield(yield_for(0.2), YIELD) # Wait to allow dragging to start
	board.UT_interpolate_mouse_move(Vector2(300,200),card.position,6)	
	yield(yield_for(0.3), YIELD)
	common.drop_card(card,board.UT_mouse_position)
	card._on_Card_mouse_exited()
	yield(yield_for(0.3), YIELD)

	card = cards[5]
	card._on_Card_mouse_entered()
	common.click_card(card)
	yield(yield_for(0.2), YIELD) # Wait to allow dragging to start
	board.UT_interpolate_mouse_move(Vector2(300,300),card.position,6)	
	yield(yield_for(0.3), YIELD)
	common.drop_card(card,board.UT_mouse_position)
	card._on_Card_mouse_exited()
	yield(yield_for(0.3), YIELD)

	card = cards[7]
	card._on_Card_mouse_entered()
	common.click_card(card)
	yield(yield_for(0.2), YIELD) # Wait to allow dragging to start
	board.UT_interpolate_mouse_move(Vector2(300,400),card.position,6)	
	yield(yield_for(0.3), YIELD)
	common.drop_card(card,board.UT_mouse_position)
	card._on_Card_mouse_exited()
	yield(yield_for(0.3), YIELD)

	card = cards[0]
	card._on_Card_mouse_entered()
	common.click_card(card)
	yield(yield_for(1), YIELD) # Wait to allow dragging to start
	board.UT_interpolate_mouse_move(Vector2(300,600),card.position,3)
	yield(yield_for(1), YIELD)
	common.drop_card(card,board.UT_mouse_position)
	card._on_Card_mouse_exited()
	yield(yield_for(1), YIELD)

	cards.append(hand.draw_card())
	yield(yield_for(0.1), YIELD)
	cards.append(hand.draw_card())
	yield(yield_for(0.7), YIELD)

	card = cards[1]
	card._on_Card_mouse_entered()
	common.click_card(card)
	yield(yield_for(0.2), YIELD) # Wait to allow dragging to start
	board.UT_interpolate_mouse_move(Vector2(300,600),card.position,3)
	yield(yield_for(0.6), YIELD)
	common.drop_card(card,board.UT_mouse_position)
	card._on_Card_mouse_exited()
	yield(yield_for(0.3), YIELD)

	yield(yield_for(0.7), YIELD)
	assert_eq(8,hand.get_card_count(),"Check if we have the correct amount of cards in hand")
	for c in cards:
		if c.get_parent() == cfc_config.NMAP.hand:
			assert_eq(0,c.z_index,"Check if card in hand at index 0")

