extends "res://tests/UTcommon.gd"

var cards := []

func before_each():
	setup_board()
	cards = draw_test_cards(5)
	yield(yield_for(1), YIELD)

func test_game_seed():
	cfc.game_rng_seed = "godot"
	var all_index1 = []
	var all_cards = cfc.NMAP.hand.get_all_cards()
	cfc.NMAP.hand.shuffle_cards()
	var shuffle_cards = cfc.NMAP.hand.get_all_cards()
	yield(yield_for(0.2), YIELD)
	for card in shuffle_cards:
		all_index1.append(all_cards.find(card))

	cfc.game_rng_seed = "godot"
	randi()
	randomize()
	rand_range(1,2)
	var all_index2 = []
	all_cards = cfc.NMAP.hand.get_all_cards()
	cfc.NMAP.hand.shuffle_cards()
	shuffle_cards = cfc.NMAP.hand.get_all_cards()
	yield(yield_for(0.2), YIELD)
	for card in shuffle_cards:
		all_index2.append(all_cards.find(card))
	assert_eq(all_index1,all_index2,"The first random result is different from the second random result")
