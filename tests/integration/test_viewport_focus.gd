extends "res://addons/gut/test.gd"

var main
var board
var hand
var cards := []
var common = UTCommon.new()

func before_each():
	main = autoqfree(TestVars.new().mainScene.instance())
	get_tree().get_root().add_child(main)
	board = common.setup_main(main)
	cards = common.draw_test_cards(5)
	hand = cfc.NMAP.hand
	yield(yield_for(1), YIELD)

func test_single_card_focus():
	yield(yield_for(1), YIELD)
	cards[0]._on_Card_mouse_entered()
	yield(yield_to(main.get_node('Focus/Tween'), "tween_all_completed", 1), YIELD)
	assert_eq(2,main.get_node('Focus/Viewport').get_child_count(),"Ensure duplicate card has been added for viewport focus")
	cards[0]._on_Card_mouse_exited()
	yield(yield_to(main.get_node('Focus/Tween'), "tween_all_completed", 1), YIELD)
	assert_eq(1,main.get_node('Focus/Viewport').get_child_count(),"Ensure duplicate card has been removed from focus")

func test_for_leftover_focus_objects():
	cards[2]._on_Card_mouse_entered()
	common.click_card(cards[2])
	yield(yield_for(0.3), YIELD) # Wait to allow dragging to start
	board.UT_interpolate_mouse_move(cfc.NMAP.discard.position,cards[2].position)
	yield(yield_for(0.6), YIELD) # Wait to allow dragging to start
	common.drop_card(cards[2],board.UT_mouse_position)
	yield(yield_for(1), YIELD)
	yield(yield_to(main.get_node('Focus/Tween'), "tween_all_completed", 1), YIELD)
	assert_eq(1,main.get_node('Focus/Viewport').get_child_count(),"Ensure duplicate card has been removed from focus")
