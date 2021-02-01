extends "res://tests/UTcommon.gd"

var cards := []

func before_all():
	cfc.game_settings.fancy_movement = false

func after_all():
	cfc.game_settings.fancy_movement = true

func before_each():
	var confirm_return = setup_board()
	if confirm_return is GDScriptFunctionState: # Still working.
		confirm_return = yield(confirm_return, "completed")

func test_get_card_methods():
	var pile : Pile = cfc.NMAP.deck
	# The Panel is always put to the bottom with code. Therefore the third child node is always a card
	assert_eq(pile.get_child(4),pile.get_bottom_card(),
			'get_top_card() returns top card')
	# Likewise, the first card from the bottom is the previous to last.
	assert_eq(pile.get_child(pile.get_child_count() - 2),pile.get_top_card(),
			'get_bottom_card returns() bottom card')
	assert_eq(pile.get_bottom_card(),pile.get_all_cards()[0],
			"get_all_cards() works without anything in viewpile")
	pending("Card has to be facedown when moved into pile")
	pending("Card has to be faceup when viewed in popup")

func test_set_pile_name():
	var pile : Pile = cfc.NMAP.discard
	pile.pile_name = "GUT Test"
	assert_eq(pile.pile_name, pile.pile_name_label.text,
			"Label is renamed whe pile_name changes")
