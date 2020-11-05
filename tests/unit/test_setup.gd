extends "res://addons/gut/test.gd"

var board
var hand
var cards := []
var common = UTCommon.new()

func before_each():
	board = autoqfree(TestVars.new().boardScene.instance())
	get_tree().get_root().add_child(board)
	common.setup_board(board)
	cards = common.draw_test_cards(5)
	hand = cfc_config.NMAP.hand

func test_signals():
	yield(yield_for(1), YIELD)
	for node in cfc_config.piles + cfc_config.hands:
		assert_connected(cards[0], node, "card_dropped", "_on_dropped_card")
	assert_connected(cards[0], cfc_config.NMAP.board, "card_dropped", "_on_dropped_card")
