extends "res://tests/UTcommon.gd"

const PATH_DECKBUILDER = "res://src/custom/CGFDeckbuilder/CGFDeckBuilder.tscn"
var deckbuilder: DeckBuilder

func count_visible_list_cards() -> int:
	var visible_cards := 0
	for list_card_obj in deckbuilder._available_cards.get_children():
		if list_card_obj.visible:
			visible_cards += 1
	return(visible_cards)

func before_each():
	cfc._setup()
	deckbuilder = add_child_autofree(load(PATH_DECKBUILDER).instance())
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) # Always reveal the mouseon unclick

func test_setup():
	assert_eq(deckbuilder._deck_cards.get_child_count(), 0,
			"Deck List should be empty")
	assert_eq(deckbuilder._available_cards.get_child_count(),
			cfc.card_definitions.size() - 1, # because of the token
			"Available cards should match the unique cards defined")
	assert_eq(deckbuilder._filter_buttons.get_child_count(), 5,
			"Filter buttons match the amounts of types")
	var card_object: DBListCardObject = deckbuilder._available_cards.get_child(0)
	var quantity_nodes : Array = card_object.get_node("Quantity").get_children()
	card_object.setup_max_quantity(3)
	for n in quantity_nodes:
		match n.name:
			'0', '1', '2', '3':
				assert_true(n.visible, "Quantity buttons are visible")
			'4','5','Plus','Minus','IntegerLineEdit':
				assert_false(n.visible, "Freeform entry is invisible")
	card_object.setup_max_quantity(7)
	for n in quantity_nodes:
		match n.name:
			'0','Plus','Minus','IntegerLineEdit':
				assert_true(n.visible, "Freeform entry is visible")
			'1','2','3','4','5':
				assert_false(n.visible, "Quantity buttons are invisible")

func test_quantity_button_add_remove():
	var card_object: DBListCardObject = deckbuilder._available_cards.get_child(0)
	card_object.setup_max_quantity(5)
	var button4 : QuantityNumberButton = card_object._qbuttons[4]
	watch_signals(button4)
	button4._on_button_pressed()
	assert_signal_emitted_with_parameters(button4, "quantity_set", [4])
	assert_eq(deckbuilder._deck_cards.get_child_count(), 1,
			"Deck List should have 1 category")
	var deck_card_obj := card_object.deck_card_object
	assert_not_null(deck_card_obj)
	if deck_card_obj:
		assert_eq(deck_card_obj.quantity, 4)
	card_object._qbuttons[1]._on_button_pressed()
	assert_eq(deck_card_obj.quantity, 1)
	card_object._qbuttons[0]._on_button_pressed()
	assert_null(card_object.deck_card_object)

func test_plus_minus_freeform_add_remove():
	var card_object: DBListCardObject = deckbuilder._available_cards.get_child(1)
	card_object.setup_max_quantity(10)
	card_object._on_Plus_pressed()
	yield(yield_for(0.1), YIELD)
	var deck_card_obj := card_object.deck_card_object
	assert_not_null(deck_card_obj)
	if deck_card_obj:
		assert_eq(deck_card_obj.quantity, 1)
		card_object._on_Plus_pressed()
		assert_eq(deck_card_obj.quantity, 2)
		card_object._on_Minus_pressed()
		assert_eq(deck_card_obj.quantity, 1)
		card_object._on_Minus_pressed()
		yield(yield_for(0.1), YIELD)
		assert_null(card_object.deck_card_object)
	var iedit : IntegerLineEdit = card_object._quantity_edit
	watch_signals(iedit)
	iedit.text = "9"
	iedit._on_IntegerLineEdit_text_entered("9")
	yield(yield_for(0.1), YIELD)
	assert_signal_emitted_with_parameters(iedit, "int_entered", [9])
	deck_card_obj = card_object.deck_card_object
	assert_not_null(deck_card_obj)
	if deck_card_obj:
		assert_eq(deck_card_obj.quantity, 9)
		deck_card_obj._on_Plus_pressed()
		assert_eq(deck_card_obj.quantity, 10)
		deck_card_obj._on_Plus_pressed()
		assert_eq(deck_card_obj.quantity, 10)
		iedit._on_IntegerLineEdit_text_entered("2")
		deck_card_obj._on_Minus_pressed()
		assert_eq(deck_card_obj.quantity, 1)
		deck_card_obj._on_Minus_pressed()
		yield(yield_for(0.1), YIELD)
		assert_null(card_object.deck_card_object)

func test_save_load_reset():
	var card_object: DBListCardObject = deckbuilder._available_cards.get_child(4)
	# To ensure the max allowed allows the 3 cards we want to add
	print_debug(card_object.card_name)
	card_object.max_allowed = 10
	card_object._qbuttons[3]._on_button_pressed()
	var deck_name : String = deckbuilder._deck_name.text
	deckbuilder._on_Save_pressed()
	assert_eq(deckbuilder._notice.text, "Deck saved")
	assert_true(deckbuilder._notice.get_node("Tween").is_active(),
			"notice started tweening")
	var dir = Directory.new()
	assert_true(dir.dir_exists(CFConst.DECKS_PATH),
			"Deck path exists")
	assert_true(dir.file_exists(CFConst.DECKS_PATH + deck_name + ".json"),
			"Deck saved correctly")
	var file = File.new()
	file.open(CFConst.DECKS_PATH + deck_name + '.json', File.READ)
	var data = JSON.parse(file.get_as_text())
	file.close()
	assert_eq(typeof(data.result), TYPE_DICTIONARY)
	if typeof(data.result) == TYPE_DICTIONARY:
		assert_eq(data.result.name, deck_name,
				"Deck name stored correctly")
		assert_eq(data.result.cards.get(card_object.card_name,0), 3.0,
				"Deck card contents stored correctly")
		assert_eq(data.result.total, 3.0,
				"Deck card total stored correctly")
	deckbuilder._on_Reset_pressed()
	yield(yield_for(0.5), YIELD)
	assert_eq(deckbuilder._deck_name.text, deck_name,
			"Reset Deck Name not randomized")
	assert_eq(deckbuilder._deck_cards.get_child_count(), 0,
			"Deck List empty after reset")
	deckbuilder._load_button._on_about_to_show()
	assert_gt(deckbuilder._load_button.get_popup().get_item_count(), 0,
			"Deck list populated correctly")
	deckbuilder._load_button._on_deck_load(0)
	yield(yield_for(0.1), YIELD)
	assert_ne(deckbuilder._deck_cards.get_child_count(), 0,
			"Deck List has contents after deck load")
	deckbuilder._on_deck_loaded(data.result)
	yield(yield_for(0.1), YIELD)
	assert_eq(deckbuilder._notice.text,
			"Deck loaded")
	var deck_card_obj := card_object.deck_card_object
	assert_not_null(deck_card_obj)
	if deck_card_obj:
		assert_eq(deck_card_obj.quantity, 3,
				"Quantity should be set according to the loaded deck")
	for list_card_obj in deckbuilder._available_cards.get_children():
		if list_card_obj != card_object:
			assert_eq(list_card_obj.quantity, 0,
					"Other ListCardObjects are empty")
			assert_null(list_card_obj.deck_card_object,
					"No Other Deck cards exist")
	assert_eq(deckbuilder._deck_name.text, deck_name,
			"Deck Name set to previous after load")
	deckbuilder._on_Delete_pressed()
	assert_eq(deckbuilder._notice.text,
			"Deck deleted from disk. Current list not cleared")
	assert_true(deckbuilder._notice.get_node("Tween").is_active())
	assert_true(dir.dir_exists(CFConst.DECKS_PATH),
			"Deck path not deleted")
	assert_false(dir.file_exists(CFConst.DECKS_PATH + deck_name + ".json"),
			"GUT Deck deleted")

func test_filters() -> void:
	var all_visible := count_visible_list_cards()
	for fbutton in deckbuilder._filter_buttons.get_children():
		fbutton.pressed = false
		fbutton.emit_signal("pressed")
	assert_eq(count_visible_list_cards(), 0)
	deckbuilder._filter_buttons.get_child(0).pressed = true
	deckbuilder._filter_buttons.get_child(0).emit_signal("pressed")
	assert_ne(count_visible_list_cards(), 0)
	for fbutton in deckbuilder._filter_buttons.get_children():
		fbutton.pressed = true
		fbutton.emit_signal("pressed")
	var fline := deckbuilder._filter_line
	fline.on_text_changed("p>0")
	assert_eq(count_visible_list_cards(), 2,
			"Number comparison filter works")
	fline.on_text_changed("p>0 c<1")
	assert_eq(count_visible_list_cards(), 1,
			"Multiple comparison filters work")
	deckbuilder._on_ClearFilters_pressed()
	assert_eq(count_visible_list_cards(), all_visible)
	fline.on_text_changed("!Choice")
	assert_eq(count_visible_list_cards(), 5,
			"filter on name works")
	fline.on_text_changed("a:blood")
	assert_eq(count_visible_list_cards(), 1,
			"filter on criteria works")
	fline.text = "a!blood"
	fline.on_text_changed("a!blood")
	assert_eq(count_visible_list_cards(), 5,
			"negative filter works")
	deckbuilder._filter_buttons.get_node("Red").pressed = false
	deckbuilder._filter_buttons.get_node("Red").emit_signal("pressed")
	assert_eq(count_visible_list_cards(), 4,
			"filter buttons and filter line working together")

func test_name_randomize():
	var deck_name : String = deckbuilder._deck_name.text
	deckbuilder._on_RandomizeName_pressed()
	assert_ne(deckbuilder._deck_name.text, deck_name,
			"Reset Deck Name  randomized")

