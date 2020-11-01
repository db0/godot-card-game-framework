extends "res://addons/gut/test.gd"

var Board
var cards := []

func before_each():
	Board = autoqfree(load("res://Board.tscn").instance())
	self.add_child(Board)
	Board.UT = true
	cards = []
	for _iter in range(5):
		cards.append($Board/Hand.draw_card())

func test_single_card_focus():
	yield(yield_for(1), YIELD)
	cards[0]._on_Card_mouse_entered()
	yield(yield_to(cards[0].get_node('Tween'), "tween_all_completed", 1), YIELD)
	assert_almost_eq(Vector2(197.5, 360),cards[0].rect_global_position,Vector2(2,2), "Check card dragged in correct global position")
	assert_almost_eq(Vector2(1.5, 1.5),cards[0].rect_scale,Vector2(0.1,0.1), "Check card has correct scale")
	cards[0]._on_Card_mouse_exited()
	yield(yield_to(cards[0].get_node('Tween'), "tween_all_completed", 1), YIELD)
	assert_almost_eq(Vector2(235, 600),cards[0].rect_global_position,Vector2(2,2), "Check card placed in correct global position")
	assert_almost_eq(Vector2(1, 1),cards[0].rect_scale,Vector2(0.1,0.1), "Check card has correct scale")
#
func test_card_focus_neighbour_push():
	yield(yield_for(1), YIELD)
	cards[2]._on_Card_mouse_entered()
	yield(yield_for(1), YIELD)
	assert_almost_eq(Vector2(178.75, 600),cards[0].rect_global_position,Vector2(2,2), "Check card dragged in correct global position")
	assert_almost_eq(Vector2(287.5, 600),cards[1].rect_global_position,Vector2(2,2), "Check card dragged in correct global position")
	assert_almost_eq(Vector2(842.5, 600),cards[3].rect_global_position,Vector2(2,2), "Check card dragged in correct global position")	
	assert_almost_eq(Vector2(951.25, 600),cards[4].rect_global_position,Vector2(2,2), "Check card dragged in correct global position")	

#
func test_card_change_focus_to_neighbour():
	var YIELD_TIME := 0.07
	var YIELD_TIME2 := 0.2
	yield(yield_for(1), YIELD)
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
	assert_almost_eq(Vector2(235, 600),cards[0].rect_global_position,Vector2(2,2), "Check card dragged in correct global position")
	assert_almost_eq(Vector2(400, 600),cards[1].rect_global_position,Vector2(2,2), "Check card dragged in correct global position")
	assert_almost_eq(Vector2(565, 600),cards[2].rect_global_position,Vector2(2,2), "Check card dragged in correct global position")
	assert_almost_eq(Vector2(730, 600),cards[3].rect_global_position,Vector2(2,2), "Check card dragged in correct global position")	
	assert_almost_eq(Vector2(895, 600),cards[4].rect_global_position,Vector2(2,2), "Check card dragged in correct global position")	
