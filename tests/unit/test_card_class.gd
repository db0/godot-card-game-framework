extends "res://tests/UTcommon.gd"

var card: Card
var cards := []

func before_all():
	cfc.game_settings.fancy_movement = false

func after_all():
	cfc.game_settings.fancy_movement = true

func before_each():
	var confirm_return = setup_board()
	if confirm_return is GDScriptFunctionState: # Still working.
		confirm_return = yield(confirm_return, "completed")
	card = cfc.NMAP.deck.get_top_card()
	
	
func test_methods():
	assert_eq('Card',card.get_class(), 'class name returns correct value')

func test_focus_setget():
	card.set_focus(true)
	card.state = Card.CardState.FOCUSED_IN_HAND
	assert_true(card.highlight.visible,
			'Highlight is set correctly to visible')
	assert_true(card.get_focus(),
			'get_focus returns true correct value correctly')
	card.set_focus(false)
	card.state = Card.CardState.IN_HAND
	assert_false(card.highlight.visible,
			'Highlight is set correctly to invisible')
	assert_false(card.get_focus(),
			'get_focus returns false correct value correctly')

func test_move_to():
	var discard : Pile = cfc.NMAP.discard
	var card2 = cfc.NMAP.deck.get_card(1)
	var card3 = cfc.NMAP.deck.get_card(2)
	var card4 = cfc.NMAP.deck.get_card(3)
	var card5 = cfc.NMAP.deck.get_card(4)
	var card6 = cfc.NMAP.deck.get_card(5)
	card.move_to(discard)
	card2.move_to(discard)
	assert_eq(1,discard.get_card_index(card2),
			'move_to without arguments puts card at the end')
	card3.move_to(discard, 0)
	assert_eq(0,discard.get_card_index(card3),
			'move_to can move card to the top')
	card4.move_to(discard, 2)
	assert_eq(2,discard.get_card_index(card4),
			'move_to can move card between others')
	card5.move_to(discard,2)
	card6.move_to(discard,2)
	assert_eq(2,discard.get_card_index(card6),
			'move_to can takeover/push index spots of other cards')
	assert_eq(3,discard.get_card_index(card5),
			'move_to can takeover/push index spots of other cards')
	assert_eq(4,discard.get_card_index(card4),
			'move_to can takeover/push index spots of other cards')

func test_init_card_name():
	# We need a yield to allow the richtextlabel setup complete
	yield(yield_to(get_tree(), "idle_frame", 0.1), YIELD)
	# We know which are the last 3 card types of the test cards
	var test3 = cfc.NMAP.deck.get_card(15)
	var test2 = cfc.NMAP.deck.get_card(14)
	var test1 = cfc.NMAP.deck.get_card(13)
	assert_eq("Test Card 1",test1.canonical_name,
			'card_name variable is set correctly')
	assert_string_contains(test1.name, "Test Card 1")
	assert_eq("Test Card 1",test1.card_front.card_labels["Name"].text,
			'Name Label text is set correctly')
	assert_eq("Test Card 2",test2.canonical_name,
			'card_name variable is set correctly')
	assert_string_contains(test2.name, "Test Card 2")
	assert_eq("Test Card 2",test2.card_front.card_labels["Name"].text,
			'Name Label text is set correctly')
	assert_eq("Test Card 3",test3.canonical_name,
			'card_name variable is set correctly')
	assert_string_contains(test3.name, "Test Card 3")
	assert_eq("Test Card 3",test3.card_front.card_labels["Name"].text,
			'Name Label text is set correctly')

func test_card_name_setget():
	yield(yield_to(get_tree(), "idle_frame", 0.1), YIELD)
	card.set_name("Testing Name Change 1")
	# We need a yield to allow the richtextlabel setup complete
	assert_eq("Testing Name Change 1",card.canonical_name,
			'card_name variable is set correctly')
	assert_string_contains(card.name, "Testing Name Change 1")
	assert_eq("Testing Name Change 1",card.card_front.card_labels["Name"].text,
			'Name Label text is set correctly')
	card.canonical_name = "Testing Name Change 2"
	yield(yield_to(get_tree(), "idle_frame", 0.1), YIELD)
	assert_eq("Testing Name Change 2",card.canonical_name,
			'card_name variable is set correctly')
	assert_string_contains(card.name, "Testing Name Change 2")
	assert_eq("Testing Name Change 2",card.card_front.card_labels["Name"].text,
			'Name Label text is set correctly')

func test_CardDefinition_properties():
	cfc.card_definitions["GUT Card"] = {
		"Type": "Red",
		"Tags": ["Tag 1","Tag 2","GUT Tag"],
		"Requirements": "",
		"Abilities": "Gut Test",
		"_meta": "This is a meta property",
		"_meta2": "They are not displayed on the card",
		"Cost": 10,
		"Power": 0,
	}
	var new_card = cfc.instance_card("GUT Card")
	board.add_child(new_card)
	new_card._determine_idle_state()
	# We need a yield to allow the richtextlabel setup complete
	yield(yield_to(get_tree(), "idle_frame", 0.1), YIELD)
	assert_eq(new_card.card_front.card_labels["Tags"].text,"Tag 1 - Tag 2 - GUT Tag",
			"Array property uses the separator")
	assert_eq(new_card.card_front.card_labels["Cost"].text, "10",
			"Integer properties are converted into strings")

func test_font_size():
	var text_node = card.card_front.card_labels["Abilities"]
	var labels_rect = card.card_front._card_text.rect_size
	var lorem = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed vitae laoreet nunc. Etiam vitae tempus ligula. Vestibulum pellentesque mauris vel ultricies pharetra. Curabitur iaculis dolor vitae leo aliquet viverra sit amet vitae eros. Nulla eros turpis, mollis non elit eget, iaculis porta magna. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae; Nulla sem dui, consectetur ut nulla ut, vestibulum venenatis dui. Fusce sollicitudin bibendum quam, at scelerisque risus fringilla eu. Curabitur elementum sem sed nisi malesuada molestie. Nulla finibus, eros quis volutpat vehicula, dui mauris dictum metus, quis pellentesque sem quam eget mi. Vivamus convallis massa non ex laoreet pharetra. Proin sed leo at dui varius dapibus sit amet ac purus."
	card.card_front.set_rich_label_text(text_node, lorem)
	assert_eq(card.card_front._card_text.rect_size,labels_rect)

func test_number_properties_with_string_value():
	cfc.card_definitions["GUT Card"] = {
		"Type": "Red",
		"Tags": ["Tag 1","Tag 2","GUT Tag"],
		"Requirements": "",
		"Abilities": "Gut Test",
		"_meta": "This is a meta property",
		"_meta2": "They are not displayed on the card",
		"Cost": 'X',
		"Power": '1',
	}
	var new_card = cfc.instance_card("GUT Card")
	board.add_child(new_card)
	new_card._determine_idle_state()
	# We need a yield to allow the richtextlabel setup complete
	yield(yield_to(get_tree(), "idle_frame", 0.1), YIELD)
	assert_eq(new_card.card_front.card_labels["Cost"].text,"X",
			"Numerical array allowed string value")
	assert_eq(new_card.card_front.card_labels["Power"].text, '1',
			"String number handled properly")
	assert_eq(new_card.properties.Power, 1,
			"Number property changed to integer")
	new_card.modify_property('Power', 'U')
	yield(yield_to(get_tree(), "idle_frame", 0.1), YIELD)
	assert_eq(new_card.card_front.card_labels["Power"].text,"U",
			"Numerical array allowed string value")


func test_number_properties_adjust():
	cfc.card_definitions["GUT Card"] = {
		"Type": "Red",
		"Tags": ["Tag 1","Tag 2","GUT Tag"],
		"Requirements": "",
		"Abilities": "Gut Test",
		"Cost": '1',
		"Power": '5',
	}
	var new_card = cfc.instance_card("GUT Card")
	board.add_child(new_card)
	new_card._determine_idle_state()
	# We need a yield to allow the richtextlabel setup complete
	yield(yield_to(get_tree(), "idle_frame", 0.1), YIELD)
	new_card.modify_property("Cost", "+3")
	new_card.modify_property("Power", "-3")
	yield(yield_to(get_tree(), "idle_frame", 0.1), YIELD)
	assert_eq(new_card.card_front.card_labels["Cost"].text,"4",
			"Number property label adjusted upwards")
	assert_eq(new_card.properties.Cost, 4,
			"Number property adjusted upwards")
	assert_eq(new_card.card_front.card_labels["Power"].text, '2',
			"Number property label adjusted downwards")
	assert_eq(new_card.properties.Power, 2,
			"Number property adjusted upwards")



func test_refresh_card_front():
	cfc.card_definitions["GUT Card"] = {
		"Type": "Red",
		"Tags": ["Tag 1","Tag 2","GUT Tag"],
		"Requirements": "",
		"Abilities": "Gut Test",
		"Cost": '1',
		"Power": '5',
	}
	var new_card = cfc.instance_card("GUT Card")
	board.add_child(new_card)
	new_card._determine_idle_state()
	# We need a yield to allow the richtextlabel setup complete
	yield(yield_to(get_tree(), "idle_frame", 0.1), YIELD)
	new_card.properties = {
		"Type": "Red",
		"Tags": ["Tag 3","Tag 4"],
		"Requirements": "",
		"Abilities": "Property Refreshed",
		"Cost": 'U',
		"Power": "+3",
	}
	new_card.refresh_card_front()
	yield(yield_to(get_tree(), "idle_frame", 0.1), YIELD)
	assert_eq(new_card.card_front.card_labels["Cost"].text,"U",
			"Number Property refreshed as string")
	assert_eq(new_card.card_front.card_labels["Power"].text, '3',
			"String refreshed to int")
	assert_eq(new_card.card_front.card_labels["Tags"].text, "Tag 3 - Tag 4",
			"Tags refreshed")
	assert_eq(new_card.card_front.card_labels["Abilities"].text, "Property Refreshed",
			"Abilities refreshed")
