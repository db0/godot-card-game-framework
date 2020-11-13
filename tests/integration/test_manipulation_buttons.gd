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
	yield(yield_for(1), YIELD)

func test_manipulation_buttons_not_messing_hand_focus():
	cards[0]._on_Card_mouse_entered()
	yield(yield_for(0.05), YIELD)
	cards[0]._on_Card_mouse_exited()
	cards[0]._on_button_mouse_entered()
	yield(yield_for(0.01), YIELD)
	cards[0]._on_button_mouse_exited()
	cards[0]._on_Card_mouse_entered()
	yield(yield_to(cards[0].get_node('Tween'), "tween_all_completed", 1), YIELD)
	assert_almost_eq(Vector2(47.5, -240),cards[0].position,Vector2(2,2), "Check card dragged in correct global position")
	assert_almost_eq(Vector2(1.5, 1.5),cards[0].scale,Vector2(0.1,0.1), "Check card has correct scale")
