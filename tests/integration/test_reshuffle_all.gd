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

func after_each():
	cfc.fancy_movement = true

func test_fancy_reshuffle_all():
	cfc.fancy_movement = true
	cards[0]._on_Card_mouse_entered()
	common.click_card(cards[0])
	yield(yield_for(0.5), YIELD) # Wait to allow dragging to start
	board._UT_interpolate_mouse_move(Vector2(300,300),cards[0].global_position)
	yield(yield_for(0.6), YIELD)
	common.drop_card(cards[0],board._UT_mouse_position)
	yield(yield_to(cards[0].get_node('Tween'), "tween_all_completed", 1), YIELD)
	cards[4]._on_Card_mouse_entered()
	common.click_card(cards[4])
	yield(yield_for(0.5), YIELD) # Wait to allow dragging to start
	board._UT_interpolate_mouse_move(Vector2(1000,10),cards[0].global_position)
	yield(yield_for(0.6), YIELD)
	common.drop_card(cards[4],board._UT_mouse_position)
	yield(yield_to(cards[4].get_node('Tween'), "tween_all_completed", 1), YIELD)
	board._on_ReshuffleAll_pressed()
	yield(yield_for(0.02), YIELD)
	assert_almost_eq(Vector2(300, 300),cards[0].global_position,Vector2(10,10), "Check that card is not being teleported from where is expect by Tween")
	assert_almost_eq(Vector2(1000, 10),cards[4].global_position,Vector2(10,10), "Check that card is not being teleported from where is expect by Tween")
	yield(yield_to(cards[4].get_node('Tween'), "tween_all_completed", 1), YIELD)

func test_basic_reshuffle_all():
	cfc.fancy_movement = false
	cards[0]._on_Card_mouse_entered()
	common.click_card(cards[0])
	yield(yield_for(0.5), YIELD) # Wait to allow dragging to start
	board._UT_interpolate_mouse_move(Vector2(300,300),cards[0].global_position)
	yield(yield_for(0.6), YIELD)
	common.drop_card(cards[0],board._UT_mouse_position)
	yield(yield_to(cards[0].get_node('Tween'), "tween_all_completed", 1), YIELD)
	cards[4]._on_Card_mouse_entered()
	common.click_card(cards[4])
	yield(yield_for(0.5), YIELD) # Wait to allow dragging to start
	board._UT_interpolate_mouse_move(Vector2(1000,10),cards[0].global_position)
	yield(yield_for(0.6), YIELD)
	common.drop_card(cards[4],board._UT_mouse_position)
	yield(yield_to(cards[4].get_node('Tween'), "tween_all_completed", 1), YIELD)
	board._on_ReshuffleAll_pressed()
	yield(yield_for(0.018), YIELD)
	assert_almost_eq(Vector2(300, 300),cards[0].global_position,Vector2(10,10), "Check that card is not being teleported from where is expect by Tween")
	assert_almost_eq(Vector2(1000, 10),cards[4].global_position,Vector2(10,10), "Check that card is not being teleported from where is expect by Tween")
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
