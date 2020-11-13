extends "res://addons/gut/test.gd"

var card: Card
var board
var cards := []
var common = UTCommon.new()

func before_each():
	board = autoqfree(TestVars.new().boardScene.instance())
	get_tree().get_root().add_child(board)
	common.setup_board(board)

func test_get_card_methods():
	var pile : Pile = cfc_config.NMAP.deck
	# The Panel is always put to the bottom with code. Therefore the third child node is always a card
	assert_eq(pile.get_child(2),pile.get_top_card(), 'Check that get_top_card() returns top card')
	# Likewise, the first card from the bottom is the previous to last.
	assert_eq(pile.get_child(pile.get_child_count() - 2),pile.get_bottom_card(), 'Check that get_bottom_card returns() bottom card')
	var sameget := 0
	# We compare 2 random cards 5 times. Every time we have a match, we increment at 1.
	# If we get 5 matching pairs, something is going bad with rng
	for iter in range(0,5):
		if pile.get_random_card() == pile.get_random_card():
			sameget += 1
	assert_lt(sameget,5, 'Check that get_random_card() works')
	assert_eq(pile.get_top_card(),pile.get_all_cards()[0],"Check that get_all_cards() works without anything in viewpile")
