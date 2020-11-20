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
	hand = cfc.NMAP.hand
	yield(yield_for(1), YIELD)

func test_facedown():
	pending("Test that front is invisible when card is turned face down")
	pending("Test that front is scaled.x to 0 when card is turned face down")
	pending("Test that front rect_position.x == rect_size.x/2 when card is turned face down")
	pending("Test that back is visible when card is turned face down")
	pending("Test that back is scaled.x to 0 when card is turned face down")
	pending("Test that back rect_position.x == 0 when card is turned face down")
	pending("Test that front is visible when card is turned face up again")
	pending("Test that front is scaled.x to 0 when card is turned face up again")
	pending("Test that front rect_position.x == 0 when card is turned face up again")
	pending("Test that back is invisible when card is turned face up again")
	pending("Test that back is scaled.x to 0 when card is turned face up again")
	pending("Test that back rect_position.x == rect_size.x/2 when card is turned face up again")
	pending("Test that dupe is turned face down along with the card")
	pending("Test that view button is invisible while card is face up")
	pending("Test that view button is visible while card is face down")
	pending("Test that view button is visible while card is face down")
	pending("Test that view function returns Changed when pressing first time with card facedown")
	pending("Test that view function returns OK  when pressing second time with card facedown")
	pending("Test that view function returns FAILED when card is_viewed == true while facedown")
	pending("Test that dupe is visible after pressing view button while still hovering the card")
	pending("Test that dupe is visible after restarting focus")
	pending("Test that view function returns FAILED when pressing while card is faceup")
	pending("Test that view function returns OK when pressing while card is faceup and is_viewed is false")
	pending("Test that view function returns CHANGED when pressing while card is faceup and is_viewed is true")
