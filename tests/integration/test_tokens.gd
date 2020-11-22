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

func test_manipulation_buttons_not_messing_hand_focus():
	pending("New token takes the correct name")
	pending("New token label takes the correct name")
	pending("New token texture uses the correct file")
	pending("New token starts at 1 counter")
	pending("New token 1 counter label has the correct number")
	pending("Token change increases label counter too")
	pending("Reducing counter to 0, removes the token completely")
	pending("When Tokens are added, drawer size expands")
	pending("When Tokens are removed, drawer size expands")
	pending("get_tokens() returns correct amount of tokens")
	pending("Drawer opens on card hover")
	pending("Drawer closes on hover left")
	pending("Token buttons increase amount")
	pending("Token buttons decrease amount")
	pending("Drawer closes on drag")
	pending("Drawer closes on moveTo")
	pending("Drawer closes while Flip is ongoing")
	pending("Drawer reopens once Flip is completed")
	pending("Tokens removed when card leaves table")
	pending("Tokens not removed when card leaves with cfc.TOKENS_ONLY_ON_BOARD == false")
	pending("Two tokens can use the same texture but different names")
	
