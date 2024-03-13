extends "res://tests/UTcommon.gd"

var cards := []

func before_each():
	await setup_board()
	hand = cfc.NMAP.hand
	cards.clear()

func test_hand_z_index():
	for _iter in range(0,8):
		cards.append(hand.draw_card())
		await yield_for(0.07) 
	await yield_for(1) 
	for card in cards:
		assert_eq(0,card.z_index,"Card in hand at index 0")

func test_table_hand_z_index():
	for _iter in range(0,8):
		cards.append(hand.draw_card())
		await yield_for(0.07) 
	await yield_for(1) 
	await table_move(cards[0],Vector2(300,100))
	await table_move(cards[1],Vector2(300,200))
	await table_move(cards[5],Vector2(300,300))
	await table_move(cards[7],Vector2(300,400))
	await drag_drop(cards[0],Vector2(300,600))
	cards.append(hand.draw_card())
	await yield_for(0.1) 
	cards.append(hand.draw_card())
	await yield_for(0.7) 
	await drag_drop(cards[1],Vector2(300,600))
	await move_mouse(Vector2(0,0))
	assert_eq(8,hand.get_card_count(),"Correct amount of cards in hand")
	for c in cards:
		if c.get_parent() == cfc.NMAP.hand:
			assert_eq(0,c.z_index,"Card in hand at index 0")

