extends "res://tests/UTcommon.gd"

var cards := []


func test_game_seed_consistency():
	cfc.game_rng_seed = "GUT"
	setup_board()
	cards = draw_test_cards(10)
	yield(yield_for(1), YIELD)
	var all_index1 := []
	hand.shuffle_cards()
	yield(yield_for(0.2), YIELD)
	for card in hand.get_all_cards():
		all_index1.append([card.card_name,card.get_my_card_index()])

	board.queue_free()
	yield(yield_for(0.2), YIELD)
	cfc.game_rng_seed = "GUT"
	setup_board()
	cards = draw_test_cards(10)
	yield(yield_for(1), YIELD)
	# warning-ignore:return_value_discarded
	randi()
	randomize()
	# warning-ignore:return_value_discarded
	rand_range(1,2)
	var all_index2 := []
	hand.shuffle_cards()
	yield(yield_for(0.2), YIELD)
	for card in hand.get_all_cards():
		all_index2.append([card.card_name,card.get_my_card_index()])
	assert_eq(all_index1,all_index2,
		"The random result should stay the same when using the same seed"
		+ " even when godot seed changes")

func test_game_seed_randomization():
	cfc.game_rng_seed = "GUT"
	setup_board()
	cards = draw_test_cards(10)
	yield(yield_for(1), YIELD)
	var all_index1 := []
	hand.shuffle_cards()
	yield(yield_for(0.2), YIELD)
	for card in hand.get_all_cards():
		all_index1.append([card.card_name,card.get_my_card_index()])

	board.queue_free()
	yield(yield_for(0.2), YIELD)
	cfc.game_rng_seed = "GUT"
	setup_board()
	cards = draw_test_cards(10)
	yield(yield_for(1), YIELD)
	cfc.game_rng.randomize()
	var all_index2 := []
	hand.shuffle_cards()
	yield(yield_for(0.2), YIELD)
	for card in hand.get_all_cards():
		all_index2.append([card.card_name,card.get_my_card_index()])
	assert_ne(all_index1,all_index2,
		"The random result should change after game_rng.randomize()")
