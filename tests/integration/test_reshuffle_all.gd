extends "res://tests/UTcommon.gd"

var cards := []

func before_each():
	await setup_board()
	cards = draw_test_cards(5)
	await yield_for(0.1).YIELD

func after_each():
	cfc.game_settings.fancy_movement = true

func test_fancy_reshuffle_all():
	cfc.game_settings.fancy_movement = true
	await drag_drop(cards[0], Vector2(300,300))
	await drag_drop(cards[4], Vector2(1000,10))
	board.reshuffle_all_in_pile()
	await yield_for(0.02).YIELD
	assert_almost_eq(Vector2(300, 300),cards[0].global_position,Vector2(10,10), 
			"Card is not being teleported from where is expect by Tween")
	assert_almost_eq(Vector2(1000, 10),cards[4].global_position,Vector2(10,10), 
			"Card is not being teleported from where is expect by Tween")
	#await yield_to(cards[4].get_node('Tween'), "finished", 1).YIELD

func test_basic_reshuffle_all():
	cfc.game_settings.fancy_movement = false
	await drag_drop(cards[0], Vector2(300,300))
	await drag_drop(cards[4], Vector2(1000,10))
	board.reshuffle_all_in_pile()
	await yield_for(0.018).YIELD
	assert_almost_eq(Vector2(300, 300),cards[0].global_position,Vector2(10,10), 
			"Card is not being teleported from where is expected by Tween")
	assert_almost_eq(Vector2(1000, 10),cards[4].global_position,Vector2(10,10), 
			"Card is not being teleported from where is expected by Tween")
	#await yield_to(cards[4].get_node('Tween'), "finished", 1).YIELD
