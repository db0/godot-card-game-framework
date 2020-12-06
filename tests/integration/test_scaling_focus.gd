extends "res://tests/UTcommon.gd"

var cards := []

func before_each():
	setup_board()
	cards = draw_test_cards(5)
	yield(yield_for(1), YIELD)

func test_single_card_focus_use_rectangle():
	cfc.hand_use_oval_shape = false
	cards[0]._on_Card_mouse_entered()
	yield(yield_to(cards[0].get_node('Tween'), "tween_all_completed", 1), YIELD)
	assert_almost_eq(Vector2(47.5, -240),cards[0].position,Vector2(2,2),
			"Card dragged in correct global position")
	assert_almost_eq(Vector2(1.5, 1.5),cards[0].scale,Vector2(0.1,0.1),
			"Card has correct scale")
	cards[0]._on_Card_mouse_exited()
	yield(yield_to(cards[0].get_node('Tween'), "tween_all_completed", 1), YIELD)
	assert_almost_eq(cards[0].recalculate_position(),cards[0].position,Vector2(2,2),
			"Card placed in correct global position")
	assert_almost_eq(Vector2(1, 1),cards[0].scale,Vector2(0.1,0.1),
			"Card has correct scale")
	cfc.hand_use_oval_shape = true

func test_single_card_focus_use_oval():
	cfc.hand_use_oval_shape = true
	cards[0]._on_Card_mouse_entered()
	yield(yield_to(cards[0].get_node('Tween'), "tween_all_completed", 1), YIELD)
	assert_almost_eq(Vector2(104.116, -271.632),cards[0].position,Vector2(2,2),
			"Card dragged in correct global position")
	assert_almost_eq(Vector2(1.5, 1.5),cards[0].scale,Vector2(0.1,0.1),
			"Card has correct scale")
	cards[0]._on_Card_mouse_exited()
	yield(yield_to(cards[0].get_node('Tween'), "tween_all_completed", 1), YIELD)
	assert_almost_eq(cards[0].recalculate_position(),cards[0].position,Vector2(2,2),
			"Card placed in correct global position")
	assert_almost_eq(Vector2(1, 1),cards[0].scale,Vector2(0.1,0.1),
			"Card has correct scale")
	cfc.hand_use_oval_shape = true

func test_card_focus_neighbour_push_use_rectangle():
	cfc.hand_use_oval_shape = false
	cards[2]._on_Card_mouse_entered()
	yield(yield_for(1), YIELD)
	assert_almost_eq(Vector2(29, 0),cards[0].position,Vector2(2,2),
			"Card dragged in correct global position")
	assert_almost_eq(Vector2(137.5, 0),cards[1].position,Vector2(2,2),
			"Card dragged in correct global position")
	assert_almost_eq(Vector2(692.5, 0),cards[3].position,Vector2(2,2),
			"Card dragged in correct global position")
	assert_almost_eq(Vector2(801.25, 0),cards[4].position,Vector2(2,2),
			"Card dragged in correct global position")
	cfc.hand_use_oval_shape = true
func test_card_focus_neighbour_push_use_oval():
	cfc.hand_use_oval_shape = true
	cards[2]._on_Card_mouse_entered()
	yield(yield_for(1), YIELD)
	assert_almost_eq(Vector2(102.718, -22.392),cards[0].position,Vector2(2,2),
			"Card dragged in correct global position")
	assert_almost_eq(Vector2(181.942, -39.661),cards[1].position,Vector2(2,2),
			"Card dragged in correct global position")
	assert_almost_eq(Vector2(648.058, -39.661),cards[3].position,Vector2(2,2),
			"Card dragged in correct global position")
	assert_almost_eq(Vector2(727.282, -22.392),cards[4].position,Vector2(2,2),
			"Card dragged in correct global position")
	cfc.hand_use_oval_shape = true
func test_card_change_focus_to_neighbour():
	var YIELD_TIME := 0.07
	var YIELD_TIME2 := 0.5
	cards[2]._on_Card_mouse_entered()
	yield(yield_for(YIELD_TIME), YIELD)
	cards[2]._on_Card_mouse_exited()
	cards[3]._on_Card_mouse_entered()
	yield(yield_for(YIELD_TIME), YIELD)
	cards[3]._on_Card_mouse_exited()
	cards[4]._on_Card_mouse_entered()
	yield(yield_for(YIELD_TIME2), YIELD)
	cards[4]._on_Card_mouse_exited()
	cards[3]._on_Card_mouse_entered()
	yield(yield_for(YIELD_TIME), YIELD)
	cards[3]._on_Card_mouse_exited()
	cards[2]._on_Card_mouse_entered()
	yield(yield_for(YIELD_TIME), YIELD)
	cards[2]._on_Card_mouse_exited()
	cards[1]._on_Card_mouse_entered()
	yield(yield_for(YIELD_TIME2), YIELD)
	cards[1]._on_Card_mouse_exited()
	cards[0]._on_Card_mouse_entered()
	yield(yield_for(YIELD_TIME2), YIELD)
	cards[0]._on_Card_mouse_exited()
	yield(yield_to(cards[0].get_node('Tween'), "tween_all_completed", 1), YIELD)
	assert_almost_eq(cards[0].recalculate_position(),
			cards[0].position,Vector2(2,2),
			"Card dragged in correct global position")
	assert_almost_eq(cards[1].recalculate_position(),
			cards[1].position,Vector2(2,2),
			"Card dragged in correct global position")
	assert_almost_eq(cards[2].recalculate_position(),
			cards[2].position,Vector2(2,2),
			"Card dragged in correct global position")
	assert_almost_eq(cards[3].recalculate_position(),
			cards[3].position,Vector2(2,2),
			"Card dragged in correct global position")
	assert_almost_eq(cards[4].recalculate_position(),
			cards[4].position,Vector2(2,2),
			"Card dragged in correct global position")

func test_card_hand_mouseslide():
	var YIELD_TIME := 0.02
	cards[0]._on_Card_mouse_entered()
	yield(yield_for(YIELD_TIME), YIELD)
	cards[0]._on_Card_mouse_exited()
	yield(yield_for(YIELD_TIME), YIELD)
	cards[1]._on_Card_mouse_entered()
	yield(yield_for(YIELD_TIME), YIELD)
	cards[2]._on_Card_mouse_entered()
	yield(yield_for(YIELD_TIME), YIELD)
	cards[1]._on_Card_mouse_exited()
	yield(yield_for(YIELD_TIME), YIELD)
	cards[3]._on_Card_mouse_entered()
	yield(yield_for(YIELD_TIME), YIELD)
	cards[2]._on_Card_mouse_exited()
	yield(yield_for(YIELD_TIME), YIELD)
	cards[4]._on_Card_mouse_entered()
	yield(yield_for(YIELD_TIME), YIELD)
	cards[3]._on_Card_mouse_exited()
	yield(yield_for(YIELD_TIME), YIELD)
	#cards[4]._on_Card_mouse_entered()
	yield(yield_to(cards[4].get_node('Tween'), "tween_all_completed", 1), YIELD)
	assert_eq(cards[4].state,1, "Card is in Focused")
