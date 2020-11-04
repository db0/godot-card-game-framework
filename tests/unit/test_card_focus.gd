extends "res://addons/gut/test.gd"

var board
var hand
var cards := []
var tv = TestVars.new()

func before_each():
	board = autoqfree(tv.boardScene.instance())
	get_tree().get_root().add_child(board)
	cfc_config._ready()
	board.UT = true
	cards = []
	hand = board.find_node('Hand')
	for _iter in range(5):
		cards.append(hand.draw_card())

func test_single_card_focus():
	yield(yield_for(1), YIELD)
	cards[0]._on_Card_mouse_entered()
	yield(yield_to(cards[0].get_node('Tween'), "tween_all_completed", 1), YIELD)
	assert_almost_eq(Vector2(47.5, -120),cards[0].rect_position,Vector2(2,2), "Check card dragged in correct global position")
	assert_almost_eq(Vector2(1.5, 1.5),cards[0].rect_scale,Vector2(0.1,0.1), "Check card has correct scale")
	cards[0]._on_Card_mouse_exited()
	yield(yield_to(cards[0].get_node('Tween'), "tween_all_completed", 1), YIELD)
	assert_almost_eq(cards[0].recalculatePosition(),cards[0].rect_position,Vector2(2,2), "Check card placed in correct global position")
	assert_almost_eq(Vector2(1, 1),cards[0].rect_scale,Vector2(0.1,0.1), "Check card has correct scale")
#
func test_card_focus_neighbour_push():
	yield(yield_for(1), YIELD)
	cards[2]._on_Card_mouse_entered()
	yield(yield_for(1), YIELD)
	assert_almost_eq(Vector2(29, 120),cards[0].rect_position,Vector2(2,2), "Check card dragged in correct global position")
	assert_almost_eq(Vector2(137.5, 120),cards[1].rect_position,Vector2(2,2), "Check card dragged in correct global position")
	assert_almost_eq(Vector2(692.5, 120),cards[3].rect_position,Vector2(2,2), "Check card dragged in correct global position")	
	assert_almost_eq(Vector2(801.25, 120),cards[4].rect_position,Vector2(2,2), "Check card dragged in correct global position")	

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
	assert_almost_eq(cards[0].recalculatePosition(),cards[0].rect_position,Vector2(2,2), "Check card dragged in correct global position")
	assert_almost_eq(cards[1].recalculatePosition(),cards[1].rect_position,Vector2(2,2), "Check card dragged in correct global position")
	assert_almost_eq(cards[2].recalculatePosition(),cards[2].rect_position,Vector2(2,2), "Check card dragged in correct global position")
	assert_almost_eq(cards[3].recalculatePosition(),cards[3].rect_position,Vector2(2,2), "Check card dragged in correct global position")	
	assert_almost_eq(cards[4].recalculatePosition(),cards[4].rect_position,Vector2(2,2), "Check card dragged in correct global position")	
