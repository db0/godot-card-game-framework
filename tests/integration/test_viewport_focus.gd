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
	yield(yield_to(main.card_focus.get_node('Tween'), "tween_all_completed", 1), YIELD)
	var focus_dupe = main._previously_focused_cards[card]
	assert_eq(main.card_focus.get_node('Viewport').get_child_count(),2,
			"Duplicate card has been added for viewport focus")
	assert_eq(focus_dupe.scale,Vector2(1,1),
			"Duplicate card is scaled correctly")
	assert_eq(focus_dupe.get_node("Control").rect_rotation,0.0,
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
	assert_eq(focus_dupe.card_size, CFConst.CARD_SIZE * CFConst.FOCUSED_SCALE,
			"Duplicate resized correctly")
	assert_eq(focus_dupe._control.rect_size, CFConst.CARD_SIZE * CFConst.FOCUSED_SCALE,
			"Duplicate's control resized correctly")

	yield(move_mouse(Vector2(0,0)), 'completed')
	yield(yield_to(main.card_focus.get_node('Tween'), "tween_all_completed", 1), YIELD)
	assert_eq(2,main.card_focus.get_node('Viewport').get_child_count(),
			"Duplicate card object still remains")
	assert_false(main._previously_focused_cards[card].visible,
			"Duplicate is hidden")

func test_for_leftover_focus_objects():
	var card : Card = cards[2]
	yield(drag_drop(card,cfc.NMAP.discard.position), 'completed')
	yield(yield_to(main.card_focus.get_node('Tween'), "tween_all_completed", 1), YIELD)
	yield(yield_for(0.5), YIELD)
	assert_eq(2,main.card_focus.get_node('Viewport').get_child_count(),
			"The top face-up card of the deck is now in focus")
	yield(move_mouse(Vector2(0,0), 'slow'), 'completed')
	assert_eq(2,main.card_focus.get_node('Viewport').get_child_count(),
			"Duplicate card object still remains")
	assert_false(main._previously_focused_cards[card].visible,
			"Duplicate is hidden")

func test_card_back_focus():
	var card : Card = cards[0]
	card.is_faceup = false
	yield(move_mouse(card.global_position), 'completed')
	yield(yield_to(main.card_focus.get_node('Tween'), "tween_all_completed", 1), YIELD)
	var focus_dupe = main._previously_focused_cards[card]
	assert_eq(focus_dupe.card_back.modulate.a, 1,
			"Duplicate card back does not modulate out")
	yield(move_mouse(Vector2(0,0)), 'completed')
	yield(yield_to(main.card_focus.get_node('Tween'), "tween_all_completed", 1), YIELD)
	assert_eq(2,main.card_focus.get_node('Viewport').get_child_count(),
			"Duplicate card object still remains")

func test_viewed_card_in_pile():
	var card : Card = deck.get_top_card()
	card.is_viewed = true
	yield(move_mouse(deck.global_position), 'completed')
	yield(yield_to(main.card_focus.get_node('Tween'), "tween_all_completed", 1), YIELD)
	assert_eq(2,main.card_focus.get_node('Viewport').get_child_count(),
			"Duplicate card has been added for viewport focus")

func test_retain_properties():
	var card : Card = cards[0]
	# warning-ignore:return_value_discarded
	card.modify_property("Cost", 100, false, ["Init"])
	yield(move_mouse(card.global_position), 'completed')
	yield(yield_to(main.card_focus.get_node('Tween'), "tween_all_completed", 1), YIELD)
	var focus_dupe = main._previously_focused_cards[card]
	assert_eq(focus_dupe.get_property("Cost"), 100,
			"Focus retains modified property values from original")

func test_FocusInfoPanel():
	var card : Card = cards[0]
	var card2 : Card = cards[2]
	var card3 : Card = cards[4]
	card2.properties["_illustration"] = "GUT"
	card.properties["_illustration"] = null
	card3.properties["_illustration"] = null
	card3.properties["Tags"] = []
	card3.properties["_keywords"] = ["Clarification A"]
	yield(move_mouse(card2.global_position), 'completed')
	yield(yield_to(main.card_focus.get_node('Tween'), "tween_all_completed", 1), YIELD)
	# warning-ignore:unused_variable
	var focus_dupe = main._previously_focused_cards[card2]
	assert_eq(main.focus_info.modulate.a, 1.0,
			"FocusInfoPanel visible when illustration exists")
	assert_true(main.focus_info.existing_details['illustration'].visible,
			"Illustration label visible")
	yield(move_mouse(Vector2(0,0), "slow"), 'completed')
	yield(move_mouse(card.global_position), 'completed')
	yield(yield_to(main.card_focus.get_node('Tween'), "tween_all_completed", 1), YIELD)
	focus_dupe = main._previously_focused_cards[card]
	assert_eq(main.focus_info.modulate.a, 0.0,
			"FocusInfoPanel visible when illustration does not exist")
	assert_false(main.focus_info.existing_details['illustration'].visible,
			"Illustration label invisible")
	yield(move_mouse(Vector2(0,0), "slow"), 'completed')
	yield(move_mouse(card3.global_position), 'completed')
	yield(yield_to(main.card_focus.get_node('Tween'), "tween_all_completed", 1), YIELD)
	focus_dupe = main._previously_focused_cards[card3]
	assert_eq(main.focus_info.modulate.a, 1.0,
			"FocusInfoPanel visible")
	assert_false(main.focus_info.existing_details['illustration'].visible,
			"Illustration label invisible")
	assert_not_null(main.focus_info.existing_details['Tag 1'])
	if main.focus_info.existing_details.get('Tag 1'):
		assert_false(main.focus_info.existing_details['Tag 1'].visible,
				"Tag 1 label invisible")
	assert_not_null(main.focus_info.existing_details["Clarification A"])
	if main.focus_info.existing_details.get("Clarification A"):
		assert_true(main.focus_info.existing_details["Clarification A"].visible,
				"Clarification visible")
