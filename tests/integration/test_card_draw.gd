extends "res://tests/UTcommon.gd"

func before_each():
	setup_board()

func test_single_card_draw_use_rectangle():
	cfc.hand_use_oval_shape = false
	var card0: Card = hand.draw_card()
	assert_eq(len(hand.get_children()), 3,
			"Correct amount of cards drawn")
	assert_true(card0.visible,
			"Cards drawn is visible")
	yield(yield_to(card0.get_node('Tween'), "tween_all_completed", 1), YIELD)
	yield(yield_to(card0.get_node('Tween'), "tween_all_completed", 1), YIELD)
	assert_almost_eq(415.0,card0.recalculate_position().x,2.0,
			"Card position x is recalculated correctly")
	assert_almost_eq(120.0,card0.recalculate_position().y,2.0,
			"Card position y is recalculated correctly")
	assert_almost_eq(hand.to_global(card0.recalculate_position()),
			card0.global_position,Vector2(2,2),
			"Card placed in correct global position")
	assert_almost_eq(card0.recalculate_position(),card0.position,Vector2(2,2),
			"Card placed in correct position")
	cfc.hand_use_oval_shape = true

func test_single_card_draw_use_oval():
	cfc.hand_use_oval_shape = true
	var card0: Card = hand.draw_card()
	assert_eq(len(hand.get_children()), 3,
			"Correct amount of cards drawn")
	assert_true(card0.visible,
			"Cards drawn is visible")
	yield(yield_to(card0.get_node('Tween'), "tween_all_completed", 1), YIELD)
	yield(yield_to(card0.get_node('Tween'), "tween_all_completed", 1), YIELD)
	assert_almost_eq(415.0,card0.recalculate_position().x,2.0,
			"Card position x is recalculated correctly")
	assert_almost_eq(-60.0,card0.recalculate_position().y,2.0,
			"Card position y is recalculated correctly")
	assert_almost_eq(hand.to_global(card0.recalculate_position()),
			card0.global_position,Vector2(2,2),
			"Card placed in correct global position")
	assert_almost_eq(card0.recalculate_position(),card0.position,Vector2(2,2),
			"Card placed in correct position")
	cfc.hand_use_oval_shape = true

func test_draw_multiple_cards_slow_use_rectangle():
	cfc.hand_use_oval_shape = false
	var card0: Card = hand.draw_card()
	yield(yield_to(card0.get_node('Tween'), "tween_all_completed", 1), YIELD)
	yield(yield_to(card0.get_node('Tween'), "tween_all_completed", 1), YIELD)
	var card1: Card = hand.draw_card()
	yield(yield_to(card1.get_node('Tween'), "tween_all_completed", 1), YIELD)
	yield(yield_to(card1.get_node('Tween'), "tween_all_completed", 1), YIELD)
	assert_almost_eq(card0.recalculate_position(),card0.position,Vector2(2,2),
			"Card at index 0 placed in correct position")
	assert_almost_eq(card1.recalculate_position(),card1.position,Vector2(2,2),
			"Card at index 1 placed in correct position")
	var card2: Card = hand.draw_card()
	yield(yield_to(card2.get_node('Tween'), "tween_all_completed", 1), YIELD)
	yield(yield_to(card2.get_node('Tween'), "tween_all_completed", 1), YIELD)
	assert_almost_eq(250.0,card0.recalculate_position().x,2.0,
			"Index 0 card position x is recalculated correctly")
	assert_almost_eq(120.0,card0.recalculate_position().y,2.0,
			"Index 0 card position y is recalculated correctly")
	assert_almost_eq(415.0,card1.recalculate_position().x,2.0,
			"Index 1 card position x is recalculated correctly")
	assert_almost_eq(120.0,card1.recalculate_position().y,2.0,
			"Index 1 card position y is recalculated correctly")
	assert_almost_eq(580.0,card2.recalculate_position().x,2.0,
			"Index 2 card position x is recalculated correctly")
	assert_almost_eq(120.0,card2.recalculate_position().y,2.0,
			"Index 2 card position y is recalculated correctly")
	assert_almost_eq(card0.recalculate_position(),card0.position,Vector2(2,2),
			"Card at index 0 placed in correct position")
	assert_almost_eq(card1.recalculate_position(),card1.position,Vector2(2,2),
			"Card at index 1 placed in correct position")
	assert_almost_eq(card2.recalculate_position(),card2.position,Vector2(2,2),
			"Card at index 2 placed in correct position")
	cfc.hand_use_oval_shape = true

func test_draw_multiple_cards_slow_use_oval():
	cfc.hand_use_oval_shape = true
	var card0: Card = hand.draw_card()
	yield(yield_to(card0.get_node('Tween'), "tween_all_completed", 1), YIELD)
	yield(yield_to(card0.get_node('Tween'), "tween_all_completed", 1), YIELD)
	var card1: Card = hand.draw_card()
	yield(yield_to(card1.get_node('Tween'), "tween_all_completed", 1), YIELD)
	yield(yield_to(card1.get_node('Tween'), "tween_all_completed", 1), YIELD)
	assert_almost_eq(card0.recalculate_position(),card0.position,Vector2(2,2),
			"Card at index 0 placed in correct position")
	assert_almost_eq(card1.recalculate_position(),card1.position,Vector2(2,2),
			"Card at index 1 placed in correct position")
	var card2: Card = hand.draw_card()
	yield(yield_to(card2.get_node('Tween'), "tween_all_completed", 1), YIELD)
	yield(yield_to(card2.get_node('Tween'), "tween_all_completed", 1), YIELD)
	assert_almost_eq(280.383,card0.recalculate_position().x,2.0,
			"Index 0 card position x is recalculated correctly")
	assert_almost_eq(-48.754,card0.recalculate_position().y,2.0,
			"Index 0 card position y is recalculated correctly")
	assert_almost_eq(415.0,card1.recalculate_position().x,2.0,
			"Index 1 card position x is recalculated correctly")
	assert_almost_eq(-60.0,card1.recalculate_position().y,2.0,
			"Index 1 card position y is recalculated correctly")
	assert_almost_eq(589.617,card2.recalculate_position().x,2.0,
			"Index 2 card position x is recalculated correctly")
	assert_almost_eq(-48.754,card2.recalculate_position().y,2.0,
			"Index 2 card position y is recalculated correctly")
	assert_almost_eq(card0.recalculate_position(),card0.position,Vector2(2,2),
			"Card at index 0 placed in correct position")
	assert_almost_eq(card1.recalculate_position(),card1.position,Vector2(2,2),
			"Card at index 1 placed in correct position")
	assert_almost_eq(card2.recalculate_position(),card2.position,Vector2(2,2),
			"Card at index 2 placed in correct position")
	cfc.hand_use_oval_shape = true

func test_draw_multiple_cards_fast():
	var card0: Card = hand.draw_card()
	yield(yield_for(0.2), YIELD)
	var card1: Card = hand.draw_card()
	yield(yield_for(0.1), YIELD)
	var card2: Card = hand.draw_card()
	yield(yield_for(0.3), YIELD)
	var card3: Card = hand.draw_card()
	yield(yield_for(0.5), YIELD)
	var card4: Card = hand.draw_card()
	yield(yield_for(0.1), YIELD)
	var card5: Card = hand.draw_card()
	yield(yield_to(card5.get_node('Tween'), "tween_all_completed", 1), YIELD)
	yield(yield_to(card5.get_node('Tween'), "tween_all_completed", 1), YIELD)
	assert_almost_eq(card0.recalculate_position(),card0.position,Vector2(2,2),
			"Card at index 0 placed in correct position")
	assert_almost_eq(card1.recalculate_position(),card1.position,Vector2(2,2),
			"Card at index 1 placed in correct position")
	assert_almost_eq(card2.recalculate_position(),card2.position,Vector2(2,2),
			"Card at index 2 placed in correct position")
	assert_almost_eq(card3.recalculate_position(),card3.position,Vector2(2,2),
			"Card at index 3 placed in correct position")
	assert_almost_eq(card4.recalculate_position(),card4.position,Vector2(2,2),
			"Card at index 4 placed in correct position")
	assert_almost_eq(card5.recalculate_position(),card5.position,Vector2(2,2),
			"Card at index 5 placed in correct position")

func test_container_custom_card_functions():
	hand.draw_card()
	hand.draw_card()
	hand.draw_card()
	hand.draw_card()
	hand.draw_card()
	var card5: Card = hand.draw_card()
	yield(yield_to(card5.get_node('Tween'), "tween_all_completed", 1), YIELD)
	assert_eq(len(hand.get_all_cards()), 6,
			"get_all_cards() returns right amount of cards")
	assert_eq(hand.get_card_count(), 6,
			"get_card_count() returns right amount of cards")
	assert_eq(hand.get_card(5), card5,
			"get_card() returns the card at the correct index")
	assert_eq(hand.get_card_index(card5), 5,
			"get_card_index() returns the correct index")

func test_card_does_not_become_focused_during_movement():
	var card0 = hand.draw_card()
	yield(yield_for(0.2), YIELD)
	card0._on_Card_mouse_entered()
	assert_eq(2, card0.state, "Card state is still MovingToContainer")
