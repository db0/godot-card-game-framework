extends "res://tests/UTcommon.gd"

var cards := []

func before_each():
	setup_main()
	cards = draw_test_cards(5)
	yield(yield_for(1), YIELD)

func test_single_card_focus():
	yield(yield_for(1), YIELD)
	cards[0]._on_Card_mouse_entered()
	yield(yield_to(main.get_node('Focus/Tween'), "tween_all_completed", 1), YIELD)
	assert_eq(2,main.get_node('Focus/Viewport').get_child_count(),"Ensure duplicate card has been added for viewport focus")
	cards[0]._on_Card_mouse_exited()
	yield(yield_to(main.get_node('Focus/Tween'), "tween_all_completed", 1), YIELD)
	assert_eq(1,main.get_node('Focus/Viewport').get_child_count(),"Ensure duplicate card has been removed from focus")
	pending("Test that the focus object is always drawn with 0 rotation")

func test_for_leftover_focus_objects():
	cards[2]._on_Card_mouse_entered()
	click_card(cards[2])
	yield(yield_for(0.5), YIELD) # Wait to allow dragging to start
	board._UT_interpolate_mouse_move(cfc.NMAP.discard.position,cards[2].position)
	yield(yield_for(0.6), YIELD) # Wait to allow dragging to start
	drop_card(cards[2],board._UT_mouse_position)
	yield(yield_for(1), YIELD)
	yield(yield_to(main.get_node('Focus/Tween'), "tween_all_completed", 1), YIELD)
	assert_eq(1,main.get_node('Focus/Viewport').get_child_count(),"Ensure duplicate card has been removed from focus")
