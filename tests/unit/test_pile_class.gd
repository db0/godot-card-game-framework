extends "res://tests/UTcommon.gd"

var cards := []

func before_all():
	cfc.fancy_movement = false

func after_all():
	cfc.fancy_movement = true

func before_each():
	setup_board()

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
