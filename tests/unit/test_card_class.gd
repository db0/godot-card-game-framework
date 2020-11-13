extends "res://addons/gut/test.gd"

var card: Card
var board
var cards := []
var common = UTCommon.new()

func before_each():
	board = autoqfree(TestVars.new().boardScene.instance())
	get_tree().get_root().add_child(board)
	common.setup_board(board)
	card = cfc_config.NMAP.deck.get_card(0)

func test_methods():
	assert_eq('Card',card.get_class(), 'Check that class name returns correct value')

func test_focus_setget():
	card.set_focus(true)
	assert_true(card.get_node('Control/FocusHighlight').visible, 'Check that highlight is set correctly to visible')
	assert_true(card.get_focus(), 'Check that get_focus returns true correct value correctly')
	card.set_focus(false)
	assert_false(card.get_node('Control/FocusHighlight').visible, 'Check that highlight is set correctly to invisible')
	assert_false(card.get_focus(), 'Check that get_focus returns false correct value correctly')
	
