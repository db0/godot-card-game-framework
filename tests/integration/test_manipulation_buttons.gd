extends "res://tests/UTcommon.gd"

var cards := []

func before_each():
	setup_board()


func test_manipulation_buttons_not_messing_hand_focus_use_rectangle():
	cfc.hand_use_oval_shape = false
	cards = draw_test_cards(5)
	yield(yield_for(1), YIELD)
	cards[0]._on_Card_mouse_entered()
	yield(yield_for(0.05), YIELD)
	cards[0]._on_Card_mouse_exited()
	cards[0]._on_button_mouse_entered()
	yield(yield_for(0.01), YIELD)
	cards[0]._on_button_mouse_exited()
	cards[0]._on_Card_mouse_entered()
	yield(yield_to(cards[0].get_node('Tween'), "tween_all_completed", 1), YIELD)
	assert_almost_eq(Vector2(47.5, -240),cards[0].position,Vector2(2,2),
			"Card dragged in correct global position")
	assert_almost_eq(Vector2(1.5, 1.5),cards[0].scale,Vector2(0.1,0.1),
			"Card has correct scale")
	cfc.hand_use_oval_shape = true


func test_manipulation_buttons_not_messing_hand_focus_use_oval():
	cfc.hand_use_oval_shape = true
	cards = draw_test_cards(5)
	yield(yield_for(1), YIELD)
	cards[0]._on_Card_mouse_entered()
	yield(yield_for(0.05), YIELD)
	cards[0]._on_Card_mouse_exited()
	cards[0]._on_button_mouse_entered()
	yield(yield_for(0.01), YIELD)
	cards[0]._on_button_mouse_exited()
	cards[0]._on_Card_mouse_entered()
	yield(yield_to(cards[0].get_node('Tween'), "tween_all_completed", 1), YIELD)
	assert_almost_eq(Vector2(104.116, -271.632),cards[0].position,Vector2(2,2),
			"Card dragged in correct global position")
	assert_almost_eq(Vector2(1.5, 1.5),cards[0].scale,Vector2(0.1,0.1),
			"Card has correct scale")
	cfc.hand_use_oval_shape = true
