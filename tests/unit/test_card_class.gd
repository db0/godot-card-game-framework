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
	card.state = 1
	assert_true(card.get_node('Control/FocusHighlight').visible, 'Check that highlight is set correctly to visible')
	assert_true(card.get_focus(), 'Check that get_focus returns true correct value correctly')
	card.set_focus(false)
	card.state = 0
	assert_false(card.get_node('Control/FocusHighlight').visible, 'Check that highlight is set correctly to invisible')
	assert_false(card.get_focus(), 'Check that get_focus returns false correct value correctly')

func test_moveTo():
	var discard : Pile = cfc_config.NMAP.discard
	var card2 = cfc_config.NMAP.deck.get_card(1)
	var card3 = cfc_config.NMAP.deck.get_card(2)
	var card4 = cfc_config.NMAP.deck.get_card(3)
	var card5 = cfc_config.NMAP.deck.get_card(4)
	var card6 = cfc_config.NMAP.deck.get_card(5)
	card.moveTo(discard)
	card2.moveTo(discard)
	assert_eq(1,discard.get_card_index(card2), 'Check that moveTo without arguments puts card at the end')
	card3.moveTo(discard, 0)
	assert_eq(0,discard.get_card_index(card3), 'Check that moveTo can move card to the top')
	card4.moveTo(discard, 2)
	assert_eq(2,discard.get_card_index(card4), 'Check that moveTo can move card between others')
	card5.moveTo(discard,2)
	card6.moveTo(discard,2)
	assert_eq(2,discard.get_card_index(card6), 'Check that moveTo can takeover/push index spots of other cards')
	assert_eq(3,discard.get_card_index(card5), 'Check that moveTo can takeover/push index spots of other cards')
	assert_eq(4,discard.get_card_index(card4), 'Check that moveTo can takeover/push index spots of other cards')

