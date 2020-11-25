extends "res://tests/UTcommon.gd"

var cards := []

func before_each():
	setup_board()
	hand = cfc.NMAP.hand
	cards.clear()

func test_hand_z_index():
	for _iter in range(0,8):
		cards.append(hand.draw_card())
		yield(yield_for(0.07), YIELD)
	yield(yield_for(1), YIELD)
	for card in cards:
		assert_eq(0,card.z_index,"Card in hand at index 0")

func test_table_hand_z_index():
	for _iter in range(0,8):
		cards.append(hand.draw_card())
		yield(yield_for(0.07), YIELD)
	yield(yield_for(1), YIELD)
	yield(drag_drop(cards[0],Vector2(300,100)), 'completed')
	yield(drag_drop(cards[1],Vector2(300,200)), 'completed')
	yield(drag_drop(cards[5],Vector2(300,300)), 'completed')
	yield(drag_drop(cards[7],Vector2(300,400)), 'completed')
	yield(drag_drop(cards[0],Vector2(300,600)), 'completed')
	cards.append(hand.draw_card())
	yield(yield_for(0.1), YIELD)
	cards.append(hand.draw_card())
	yield(yield_for(0.7), YIELD)
	yield(drag_drop(cards[1],Vector2(300,600)), 'completed')
	yield(yield_for(0.7), YIELD)
	assert_eq(8,hand.get_card_count(),"Correct amount of cards in hand")
	for c in cards:
		if c.get_parent() == cfc.NMAP.hand:
			assert_eq(0,c.z_index,"Card in hand at index 0")

