extends "res://tests/UTcommon.gd"

var cards := []

func before_each():
	setup_board()

func test_methods():
	var container : Pile = cfc.NMAP.deck
	assert_eq('CardContainer',container.get_class(), 'Check that class name returns correct value')

func test_get_card_methods():
	var container : Pile = cfc.NMAP.deck
	assert_eq(container.get_child(2),container.get_all_cards()[0],"Check that get_all_cards() works")
	assert_eq(container.get_child(12),container.get_card(10),"Check that get_card works")
	assert_eq(5,container.get_card_index(container.get_child(7)),"Check that get_card_index works")
	assert_eq(15,container.get_card_count(),"Check that get_card_count() works")
	var sameget := 0
	# We compare 2 random cards 5 times. Every time we have a match, we increment at 1.
	# If we get 5 matching pairs, something is going bad with rng
	for _iter in range(0,5):
		if container.get_random_card() == container.get_random_card():
			sameget += 1
	assert_lt(sameget,5, 'Check that get_random_card() works')

