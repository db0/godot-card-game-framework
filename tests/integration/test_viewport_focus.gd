extends "res://tests/UTcommon.gd"

var cards := []

func before_each():
	await setup_main()
	cards = draw_test_cards(5)
	await yield_for(0.1)

func test_single_card_focus():
	var card : Card = cards[0]
	await move_mouse(card.global_position)
	#await yield_to(main.card_focus.get_node('Tween'), "finished", 1)
	var focus_dupe = main._previously_focused_cards[card]
	assert_eq(main.card_focus.get_node('SubViewport').get_child_count(),2,
			"Duplicate card has been added for viewport focus")
	assert_eq(focus_dupe.scale,Vector2(1,1),
			"Duplicate card is scaled correctly")
	assert_eq(focus_dupe.get_node("Control").rotation,0.0,
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
	assert_eq(focus_dupe._control.size, CFConst.CARD_SIZE * CFConst.FOCUSED_SCALE,
			"Duplicate's control resized correctly")

	await move_mouse(Vector2(0,0))
	#await yield_to(main.card_focus.get_node('Tween'), "finished", 1)
	assert_eq(2,main.card_focus.get_node('SubViewport').get_child_count(),
			"Duplicate card object still remains")
	assert_false(main._previously_focused_cards[card].visible,
			"Duplicate is hidden")

func test_for_leftover_focus_objects():
	var card : Card = cards[2]
	await drag_drop(card,cfc.NMAP.discard.position)
	#await yield_to(main.card_focus.get_node('Tween'), "finished", 1)
	await yield_for(0.5)
	assert_eq(2,main.card_focus.get_node('SubViewport').get_child_count(),
			"The top face-up card of the deck is now in focus")
	await move_mouse(Vector2(0,0), 'slow')
	assert_eq(2,main.card_focus.get_node('SubViewport').get_child_count(),
			"Duplicate card object still remains")
	assert_false(main._previously_focused_cards[card].visible,
			"Duplicate is hidden")

func test_card_back_focus():
	var card : Card = cards[0]
	card.is_faceup = false
	await move_mouse(card.global_position)
	#await yield_to(main.card_focus.get_node('Tween'), "finished", 1)
	var focus_dupe = main._previously_focused_cards[card]
	assert_eq(focus_dupe.card_back.modulate.a, 1,
			"Duplicate card back does not modulate out")
	await move_mouse(Vector2(0,0))
	#await yield_to(main.card_focus.get_node('Tween'), "finished", 1)
	assert_eq(2,main.card_focus.get_node('SubViewport').get_child_count(),
			"Duplicate card object still remains")

func test_viewed_card_in_pile():
	var card : Card = deck.get_top_card()
	card.is_viewed = true
	await move_mouse(deck.global_position)
	#await yield_to(main.card_focus.get_node('Tween'), "finished", 1)
	assert_eq(2,main.card_focus.get_node('SubViewport').get_child_count(),
			"Duplicate card has been added for viewport focus")

func test_retain_properties():
	var card : Card = cards[0]
	# warning-ignore:return_value_discarded
	card.modify_property("Cost", 100, false, ["Init"])
	await move_mouse(card.global_position)
	#await yield_to(main.card_focus.get_node('Tween'), "finished", 1)
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
	await move_mouse(card2.global_position)
	#await yield_to(main.card_focus.get_node('Tween'), "finished", 1)
	@warning_ignore("unused_variable")
	var focus_dupe = main._previously_focused_cards[card2]
	assert_eq(main.focus_info.modulate.a, 1.0,
			"FocusInfoPanel visible when illustration exists")
	assert_true(main.focus_info.existing_details['illustration'].visible,
			"Illustration label visible")
	await move_mouse(Vector2(0,0), "slow")
	await move_mouse(card.global_position)
	#await yield_to(main.card_focus.get_node('Tween'), "finished", 1)
	focus_dupe = main._previously_focused_cards[card]
	assert_eq(main.focus_info.modulate.a, 0.0,
			"FocusInfoPanel visible when illustration does not exist")
	assert_false(main.focus_info.existing_details['illustration'].visible,
			"Illustration label invisible")
	await move_mouse(Vector2(0,0), "slow")
	await move_mouse(card3.global_position)
	#await yield_to(main.card_focus.get_node('Tween'), "finished", 1)
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
