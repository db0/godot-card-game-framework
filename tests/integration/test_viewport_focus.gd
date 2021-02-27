extends "res://tests/UTcommon.gd"

var cards := []

func before_each():
	var confirm_return = setup_main()
	if confirm_return is GDScriptFunctionState: # Still working.
		confirm_return = yield(confirm_return, "completed")
	cards = draw_test_cards(5)
	yield(yield_for(0.1), YIELD)

func test_single_card_focus():
	var card : Card = cards[0]
	yield(move_mouse(card.global_position), 'completed')
	yield(yield_to(main.get_node('Focus/Tween'), "tween_all_completed", 1), YIELD)
	var focus_dupe = main._previously_focused_cards[0]
	assert_eq(2,main.get_node('Focus/Viewport').get_child_count(),
			"Duplicate card has been added for viewport focus")
	assert_eq(Vector2(1.5,1.5),focus_dupe.scale,
			"Duplicate card is scaled correctly")
	assert_eq(0.0,focus_dupe.get_node("Control").rect_rotation,
			"Duplicate card is rotated correctly")
	assert_false(focus_dupe.is_in_group("cards"),
			"Duplicate card does not belong to the 'cards' group")
	assert_false(focus_dupe.highlight.visible,
			"Duplicate card does not have visible highlight")
	assert_not_null(focus_dupe.card_back, "card_back variable is populated")
	assert_eq(focus_dupe.get_node("Control/Back").get_child_count(), 1,
			"Duplicate card does not have duplicate card backs")
	assert_eq(focus_dupe.card_back.modulate.a, 1,
			"Duplicate card does not have visible highlight")

	yield(move_mouse(Vector2(0,0)), 'completed')
	yield(yield_to(main.get_node('Focus/Tween'), "tween_all_completed", 1), YIELD)
	assert_eq(1,main.get_node('Focus/Viewport').get_child_count(),
			"Duplicate card has been removed from focus")

func test_for_leftover_focus_objects():
	var card : Card = cards[2]
	yield(drag_drop(card,cfc.NMAP.discard.position), 'completed')
	yield(yield_to(main.get_node('Focus/Tween'), "tween_all_completed", 1), YIELD)
	yield(yield_for(0.5), YIELD)
	assert_eq(2,main.get_node('Focus/Viewport').get_child_count(),
			"The top face-up card of the deck is now in focus")
	yield(move_mouse(Vector2(0,0), 'slow'), 'completed')
	assert_eq(1,main.get_node('Focus/Viewport').get_child_count(),
			"Duplicate card has been removed from focus")

func test_card_back_focus():
	var card : Card = cards[0]
	card.is_faceup = false
	yield(move_mouse(card.global_position), 'completed')
	yield(yield_to(main.get_node('Focus/Tween'), "tween_all_completed", 1), YIELD)
	var focus_dupe = main._previously_focused_cards[0]
	assert_eq(focus_dupe.card_back.modulate.a, 1,
			"Duplicate card back does not modulate out")
	yield(move_mouse(Vector2(0,0)), 'completed')
	yield(yield_to(main.get_node('Focus/Tween'), "tween_all_completed", 1), YIELD)
	assert_eq(1,main.get_node('Focus/Viewport').get_child_count(),
			"Duplicate card has been removed from focus")

func test_viewed_card_in_pile():
	var card : Card = deck.get_top_card()
	card.is_viewed = true
	yield(move_mouse(deck.global_position), 'completed')
	yield(yield_to(main.get_node('Focus/Tween'), "tween_all_completed", 1), YIELD)
	assert_eq(2,main.get_node('Focus/Viewport').get_child_count(),
			"Duplicate card has been added for viewport focus")

func test_retain_properties():
	var card : Card = cards[0]
	# warning-ignore:return_value_discarded
	card.modify_property("Cost", 100, false, ["Init"])
	yield(move_mouse(card.global_position), 'completed')
	yield(yield_to(main.get_node('Focus/Tween'), "tween_all_completed", 1), YIELD)
	var focus_dupe = main._previously_focused_cards[0]
	assert_eq(focus_dupe.get_property("Cost"), 100,
			"Focus retains modified property values from original")
