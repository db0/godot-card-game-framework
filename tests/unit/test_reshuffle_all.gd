extends "res://addons/gut/test.gd"

var board
var hand
var cards := []
var tv = TestVars.new()

func fake_click(pressed,position, flags=0):
	var ev := InputEventMouseButton.new()
	ev.button_index=BUTTON_LEFT
	ev.pressed = pressed
	ev.position = position
	ev.meta = flags
	board.UT_mouse_position = position
	get_tree().input_event(ev)

func before_each():
	board = autoqfree(tv.boardScene.instance())
	get_tree().get_root().add_child(board)
	cfc_config._ready()
	board.UT = true
	hand = board.find_node('Hand')
	cards = []
	for _iter in range(5):
		cards.append(hand.draw_card())

func test_fancy_reshuffle_all():
	yield(yield_for(1), YIELD)
	cards[0]._on_Card_mouse_entered()
	fake_click(true,cards[0].rect_global_position)
	yield(yield_for(0.12), YIELD) # Wait to allow dragging to start
	board.UT_interpolate_mouse_move(Vector2(300,300),cards[0].rect_global_position)
	yield(yield_for(0.6), YIELD)
	fake_click(false,board.UT_mouse_position)
	yield(yield_to(cards[0].get_node('Tween'), "tween_all_completed", 1), YIELD)
	cards[4]._on_Card_mouse_entered()
	fake_click(true,cards[0].rect_global_position)
	yield(yield_for(0.12), YIELD) # Wait to allow dragging to start
	board.UT_interpolate_mouse_move(Vector2(1000,10),cards[0].rect_global_position)
	yield(yield_for(0.6), YIELD)
	fake_click(false,board.UT_mouse_position)
	yield(yield_to(cards[0].get_node('Tween'), "tween_all_completed", 1), YIELD)
	board._on_ReshuffleAll_pressed()
	yield(yield_for(0.02), YIELD)
	assert_almost_eq(Vector2(310, 310),cards[0].rect_global_position,Vector2(10,10), "Check that card is not being teleported from where is expect by Tween")
	assert_almost_eq(Vector2(1010, 20),cards[4].rect_global_position,Vector2(10,10), "Check that card is not being teleported from where is expect by Tween")
	yield(yield_to(cards[4].get_node('Tween'), "tween_all_completed", 1), YIELD)

func test_basic_reshuffle_all():
	cfc_config.fancy_movement = false
	yield(yield_for(1), YIELD)
	cards[0]._on_Card_mouse_entered()
	fake_click(true,cards[0].rect_global_position)
	yield(yield_for(0.12), YIELD) # Wait to allow dragging to start
	board.UT_interpolate_mouse_move(Vector2(300,300),cards[0].rect_global_position)
	yield(yield_for(0.6), YIELD)
	fake_click(false,board.UT_mouse_position)
	yield(yield_to(cards[0].get_node('Tween'), "tween_all_completed", 1), YIELD)
	cards[4]._on_Card_mouse_entered()
	fake_click(true,cards[0].rect_global_position)
	yield(yield_for(0.12), YIELD) # Wait to allow dragging to start
	board.UT_interpolate_mouse_move(Vector2(1000,10),cards[0].rect_global_position)
	yield(yield_for(0.6), YIELD)
	fake_click(false,board.UT_mouse_position)
	yield(yield_to(cards[0].get_node('Tween'), "tween_all_completed", 1), YIELD)
	board._on_ReshuffleAll_pressed()
	yield(yield_for(0.018), YIELD)
	assert_almost_eq(Vector2(310, 310),cards[0].rect_global_position,Vector2(10,10), "Check that card is not being teleported from where is expect by Tween")
	assert_almost_eq(Vector2(1010, 20),cards[4].rect_global_position,Vector2(10,10), "Check that card is not being teleported from where is expect by Tween")
	yield(yield_to(cards[4].get_node('Tween'), "tween_all_completed", 1), YIELD)
	
