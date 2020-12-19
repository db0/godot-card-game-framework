extends "res://tests/UTcommon.gd"

var cards := []

func before_each():
	var confirm_return = setup_board()
	if confirm_return is GDScriptFunctionState: # Still working.
		confirm_return = yield(confirm_return, "completed")
	cards = draw_test_cards(5)
	yield(yield_for(1), YIELD)

func after_each():
	cfc.fancy_movement = true

func test_fancy_reshuffle_all():
	cfc.fancy_movement = true
	yield(drag_drop(cards[0], Vector2(300,300)), "completed")
	yield(drag_drop(cards[4], Vector2(1000,10)), "completed")
	board.reshuffle_all_in_pile()
	yield(yield_for(0.02), YIELD)
	assert_almost_eq(Vector2(300, 300),cards[0].global_position,Vector2(10,10), 
			"Card is not being teleported from where is expect by Tween")
	assert_almost_eq(Vector2(1000, 10),cards[4].global_position,Vector2(10,10), 
			"Card is not being teleported from where is expect by Tween")
	yield(yield_to(cards[4].get_node('Tween'), "tween_all_completed", 1), YIELD)

func test_basic_reshuffle_all():
	cfc.fancy_movement = false
	yield(drag_drop(cards[0], Vector2(300,300)), "completed")
	yield(drag_drop(cards[4], Vector2(1000,10)), "completed")
	board.reshuffle_all_in_pile()
	yield(yield_for(0.018), YIELD)
	assert_almost_eq(Vector2(300, 300),cards[0].global_position,Vector2(10,10), 
			"Card is not being teleported from where is expected by Tween")
	assert_almost_eq(Vector2(1000, 10),cards[4].global_position,Vector2(10,10), 
			"Card is not being teleported from where is expected by Tween")
	yield(yield_to(cards[4].get_node('Tween'), "tween_all_completed", 1), YIELD)

#func test_card_redraw_order():
#	# Don't think this is actually a bug.
#	var prev_idx
#	var card
#	var cards := []
#	for timer in range(0,5):
#		prev_idx = -1
#		cards.clear()
#		for iter in range(0,12):
#			card = hand.draw_card()
#			cards.append(card)
#			assert_lt(prev_idx,card.get_my_card_index(),"Check if card at index " + str(card.get_index()) + " was drawn again.")
#			prev_idx = card.get_my_card_index()
#			yield(yield_for(0.07), YIELD)
#		yield(yield_for(0.8), YIELD)
#		for c in board.allCards:
#			if c.get_parent() != cfc.NMAP.deck:
#				#assert_eq(2,c.get_index(),"Check if cards retrieved in order")
#				assert_eq(0,c.z_index,"Check if cards retrieved in order")
#				c.reHost(cfc.NMAP.deck)
#				yield(get_tree().create_timer(0.1), "timeout")
#		board._on_ReshuffleAll_pressed()
#		yield(yield_for(1.2), YIELD)
