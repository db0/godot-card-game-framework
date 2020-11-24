extends "res://tests/UTcommon.gd"


var cards := []

func before_each():
	setup_board()
	cards = draw_test_cards(5)
	yield(yield_for(1), YIELD)

func test_move_to_container():
	var card: Card
	card = cards[2]
	yield(drag_drop(card, cfc.NMAP.discard.position), 'completed')
	yield(yield_to(card.get_node('Tween'), "tween_all_completed", 0.5), YIELD)	
	yield(yield_to(card.get_node('Tween'), "tween_all_completed", 0.5), YIELD)	
	assert_almost_eq(card.global_position,cfc.NMAP.discard.position,Vector2(2,2), 
			"Card's final position matches pile's position")
	assert_eq(1,cfc.NMAP.discard.get_card_count(), 
			"The correct amount of cards are hosted")

func test_move_to_multiple_container():
	yield(drag_drop(cards[2], cfc.NMAP.discard.position), 'completed')
	yield(drag_drop(cards[4], cfc.NMAP.deck.position), 'completed')
	yield(drag_drop(cards[1], cfc.NMAP.discard.position), 'completed')
	yield(drag_drop(cards[0], cfc.NMAP.deck.position), 'completed')
	yield(yield_to(cards[0].get_node('Tween'), "tween_all_completed", 0.5), YIELD)	
	yield(yield_to(cards[0].get_node('Tween'), "tween_all_completed", 0.5), YIELD)	
	assert_almost_eq(cards[2].global_position,
			cfc.NMAP.discard.global_position,Vector2(2,2), 
			"Card 2 final position matches pile's position")
	assert_almost_eq(cards[1].global_position,
			cfc.NMAP.discard.global_position,Vector2(2,2), 
			"Card 1 final position matches pile's position")
	assert_almost_eq(cards[4].global_position,
			cfc.NMAP.deck.position,Vector2(2,2), 
			"Card 3 final position matches pile's position")
	assert_almost_eq(cards[0].global_position,
			cfc.NMAP.deck.position,Vector2(2,2), 
			"Card 0 final position matches pile's position")
	assert_eq(2,cfc.NMAP.discard.get_card_count(), 
			"Correct amount of cards are hosted in discard")
	assert_eq(12,cfc.NMAP.deck.get_card_count(), 
			"Correct amount of cards are hosted in deck")
	assert_eq(1,cfc.NMAP.hand.get_card_count(), 
			"Correct amount of cards are hosted in hand")

func test_pile_functions():
	pending("Shuffle really does shuffle")

func test_popup_view():
	pending("All cards all migrated to popup window")
	pending("get_all_cards(), includes cards in the popup")
	pending("Drawing a card from the pile, picks it from the popup")
	pending("Hosting a card in the pile, puts it in the popup")
