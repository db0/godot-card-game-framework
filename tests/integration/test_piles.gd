extends "res://tests/UTcommon.gd"

class TestMoveToContainer:
	extends "res://tests/Basic_common.gd"

	func test_move_to_container():
		var card: Card
		card = cards[2]
		await drag_drop(card, cfc.NMAP.discard.position)
		if card._tween:
			await yield_to(card._tween, "finished", 0.5) 
		assert_almost_eq(card.global_position,cfc.NMAP.discard.position,Vector2(2,2),
				"Card's final position matches pile's position")
		assert_eq(1,cfc.NMAP.discard.get_card_count(),
				"The correct amount of cards are hosted")

	func test_move_to_multiple_container():
		await drag_drop(cards[2], cfc.NMAP.discard.position + Vector2(10,10))
		await move_mouse(Vector2(500,300))
		await drag_drop(cards[4], cfc.NMAP.deck.position + Vector2(10,10))
		await move_mouse(Vector2(500,300))
		await drag_drop(cards[1], cfc.NMAP.discard.position + Vector2(10,10))
		await move_mouse(Vector2(500,300))
		await drag_drop(cards[0], cfc.NMAP.deck.position + Vector2(10,10))
		if cards[0]._tween:
			await yield_to(cards[0]._tween, "finished", 0.5) 
		#await yield_to(cards[0]._tween, "finished", 0.5) 
		assert_almost_eq(cards[2].global_position,
				cfc.NMAP.discard.global_position,Vector2(2,2),
				"Card 2 final position matches pile's position")
		assert_almost_eq(cards[1].global_position,
				cfc.NMAP.discard.global_position,Vector2(2,2),
				"Card 1 final position matches pile's position")
		assert_almost_eq(cards[4].global_position,
				cfc.NMAP.deck.position + cfc.NMAP.deck.get_stack_position(cards[4]),
				Vector2(2,2),
				"Card 3 final position matches pile's position")
		assert_almost_eq(cards[0].global_position,
				cfc.NMAP.deck.to_global(cfc.NMAP.deck.get_stack_position(cards[0])),Vector2(2,2),
				"Card 0 final position matches pile's position")
		assert_eq(2,cfc.NMAP.discard.get_card_count(),
				"Correct amount of cards are hosted in discard")
		assert_eq(14,cfc.NMAP.deck.get_card_count(),
				"Correct amount of cards are hosted in deck")
		assert_eq(1,cfc.NMAP.hand.get_card_count(),
				"Correct amount of cards are hosted in hand")

	func test_move_from_board_to_deck_to_hand():
		var card: Card
		card = cards[2]
		await drag_drop(card, Vector2(1000,100))
		await drag_drop(card, cfc.NMAP.deck.position)
		if card._tween:
			await yield_to(card._tween, "finished", 0.5) 
	# warning-ignore:return_value_discarded
		hand.draw_card()
		if card._tween:
			await yield_to(card._tween, "finished", 0.5) 
		assert_almost_eq(hand.to_global(card.recalculate_position()),
				card.global_position,Vector2(2,2),
				"Card finished move to hand from deck from board")

class TestPileFacing:
	extends "res://tests/Basic_common.gd"

	func test_pile_facing():
		var card: Card = cfc.NMAP.deck.get_top_card()
		card.move_to(cfc.NMAP.discard)
		if card._tween:
			await yield_to(card._tween, "finished", 0.5) 
		assert_true(card.is_faceup, "Card should be faceup in discard")
		card = cards[0]
		card.move_to(cfc.NMAP.deck)
		if card._tween:
			await yield_to(card._tween, "finished", 0.5) 
		assert_false(card.is_faceup,"Card should be facedown in deck")

class TestPopupView:
	extends "res://tests/Basic_common.gd"

	func test_popup_discard_view():
		var discard = cfc.NMAP.discard
		for card in cfc.NMAP.deck.get_all_cards():
			card.move_to(discard)
		await yield_for(1) 
		discard._on_View_Button_pressed()
		await yield_for(1) 
		assert_eq(6,len(discard.get_children()),
				"No cards should appear in the pile root after popup")
		assert_eq(12,discard.get_card_count(),
				"Cards in popup should be returned with get_all_cards()")
		assert_eq(12,discard.get_node("ViewPopup/CardView").get_child_count(),
				"All cards all migrated to popup window")
		#94: ViewPopup is now a Window, not a Control and cannot modulate
		#assert_eq(1.0,discard.get_node("ViewPopup").modulate[3],
				#"ViewPopup should be visible")
		cards[1].move_to(discard)
		await yield_for(1) 
		assert_eq(13,discard.get_node("ViewPopup/CardView").get_child_count(),
				"Hosting a card in the pile, while popup is open, puts it in the popup")
		assert_eq(Vector2(0.75,0.75),cards[1].scale,
				"Moving a card into the popup, should scale it")
		pending("Drawing a card from the pile, picks it from the popup")
		assert_false(discard.get_node("Control/ManipulationButtons").visible,
				"Manipulation Buttons should be hidden while popup is active")
		discard.get_node("ViewPopup").hide()
		await yield_for(1) 
		assert_true(cards[1].is_faceup,
				"Cards returning from popup should respect piles card facing")

	func test_popup_deck_view():
		var deck = cfc.NMAP.deck
		var card: Card = deck.get_top_card()
		deck._on_View_Button_pressed()
		#await yield_to(deck.get_node('ViewPopup/Tween'), "finished", 0.5) 
		card.move_to(deck)
		await yield_for(0.3) 
		assert_eq(Vector2(0,0),card.position,
				"Moving card from popup back to the same pile, should do nothing")
		assert_eq(Vector2(0.75,0.75),card.scale,
				"Moving card from popup back to the same pile, should do nothing")
		assert_true(card.is_faceup,
				"Moving card from popup back to the same pile, should do nothing")
		deck.get_node("ViewPopup").hide()
		await yield_for(1) 
		assert_false(card.is_faceup,
				"Cards returning from popup should respect piles card facing")

class TestStacking:
	extends "res://tests/Basic_common.gd"

	func test_stacking():
		var deck : Pile = cfc.NMAP.deck
		var card: Card = cards[4]
		card.move_to(deck)
		if card._tween:
			await yield_to(card._tween, "finished", 0.5) 
		assert_eq(deck.get_stack_position(card),card.position,
				"Card moved in, placed in stack position")
		card = cards[2]
		card.move_to(deck)
		if card._tween:
			await yield_to(card._tween, "finished", 0.5) 
		assert_eq(deck.get_stack_position(card),card.position,
				"Card moved in, placed in stack position")
		deck.shuffle_cards(false)
		assert_eq(deck.get_stack_position(card),card.position,
				"Reshuffle, restacks cards correctly.")

class TestShuffleRng:
	extends "res://tests/Basic_common.gd"

	func test_shuffle_rng():
		var rng_threshold: int = 0
		var card = deck.get_bottom_card()
		var prev_index = card.get_my_card_index()
		deck.shuffle_cards()
		await yield_for(1) 
		if prev_index == card.get_my_card_index():
			rng_threshold += 1
		prev_index = card.get_my_card_index()
		deck.shuffle_cards()
		await yield_for(1) 
		if prev_index == card.get_my_card_index():
			rng_threshold += 1
		prev_index = card.get_my_card_index()
		deck.shuffle_cards()
		await yield_for(1) 
		if prev_index == card.get_my_card_index():
			rng_threshold += 1
		prev_index = card.get_my_card_index()
		assert_gt(2,rng_threshold,
			"Card should not fall in he same spot too many times")
