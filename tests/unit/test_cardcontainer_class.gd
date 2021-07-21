extends "res://tests/UTcommon.gd"

var cards := []

func before_each():
	var confirm_return = setup_board()
	if confirm_return is GDScriptFunctionState: # Still working.
		confirm_return = yield(confirm_return, "completed")


func test_methods():
	var container : Pile = cfc.NMAP.deck
	assert_eq('CardContainer',container.get_class(),
			'Class name returns correct value')


func test_get_card_methods():
	var container : Pile = cfc.NMAP.deck
	assert_eq(container.get_child(5),container.get_all_cards()[0],
			"get_all_cards() works")
	assert_eq(container.get_child(15),container.get_card(10),
			"get_card works")
	assert_eq(4,container.get_card_index(container.get_child(9)),
			"get_card_index works")
	assert_eq(17,container.get_card_count(),
			"get_card_count() works")
	var sameget := 0
	# We compare 2 random cards 5 times. Every time we have a match, we increment at 1.
	# If we get 5 matching pairs, something is going bad with rng
	for _iter in range(0,5):
		if container.get_random_card() == container.get_random_card():
			sameget += 1
	assert_lt(sameget,5, 'get_random_card() works')


func test_manipulation_buttons():
	var deck : Pile = cfc.NMAP.deck
	assert_eq(1.0,deck.manipulation_buttons.modulate.a,
			"Buttons container should be visible")
	for button in deck.get_all_manipulation_buttons():
		assert_eq(0.0,button.modulate.a,
				"Buttons should start invisible")
	deck.show_buttons()
	yield(yield_to(deck.manipulation_buttons_tween, "tween_all_completed", 1), YIELD)
	for button in deck.get_all_manipulation_buttons():
		assert_eq(1.0,button.modulate.a,
				"Buttons are visible after shown")
	deck.hide_buttons()
	yield(yield_to(deck.manipulation_buttons_tween, "tween_all_completed", 1), YIELD)
	for button in deck.get_all_manipulation_buttons():
		assert_eq(0.0,button.modulate.a,
				"Buttons are invisible after hide")


func test_init_signal():
	var deck : Pile = cfc.NMAP.deck
	assert_connected(deck.control, deck, "mouse_entered")
	assert_connected(deck.control, deck, "mouse_exited")
	assert_connected(deck.shuffle_button, deck, "pressed")
	for button in deck.get_all_manipulation_buttons():
		assert_connected(button, deck, "mouse_entered")


func test_update_manipulation_buttons():
	var deck : Pile = cfc.NMAP.deck
	assert_eq(3,deck.get_all_manipulation_buttons().size(),
				"Expected number of manipulation buttons are there")
