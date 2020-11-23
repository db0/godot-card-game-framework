extends "res://addons/gut/test.gd"

var board
var hand
var cards := []
var common = UTCommon.new()


# Takes care of simple drag&drop requests
func drag_drop(card: Card, target_position: Vector2, interpolation_speed := "fast") -> void:
	var mouse_yield_wait: float
	var mouse_speed: int
	if interpolation_speed == "fast":
		mouse_yield_wait = 0.3
		mouse_speed = 10
	else:
		mouse_yield_wait = 0.6
		mouse_speed = 3
	card._on_Card_mouse_entered()
	common.click_card(card)
	yield(yield_for(0.5), YIELD) # Wait to allow dragging to start
	board._UT_interpolate_mouse_move(target_position,card.position,mouse_speed)
	yield(yield_for(mouse_yield_wait), YIELD)
	common.drop_card(card,board._UT_mouse_position)
	card._on_Card_mouse_exited()
	yield(yield_to(card.get_node('Tween'), "tween_all_completed", 1), YIELD)


func before_each():
	board = autoqfree(TestVars.new().boardScene.instance())
	get_tree().get_root().add_child(board)
	common.setup_board(board)
	hand = cfc.NMAP.hand
	cards.clear()

func test_hand_z_index():
	for _iter in range(0,8):
		cards.append(hand.draw_card())
		yield(yield_for(0.07), YIELD)
	yield(yield_for(1), YIELD)
	for card in cards:
		assert_eq(0,card.z_index,"Check if card in hand at index 0")

func test_table_hand_z_index():
	for _iter in range(0,8):
		cards.append(hand.draw_card())
		yield(yield_for(0.07), YIELD)
	yield(yield_for(1), YIELD)
	yield(drag_drop(cards[0],Vector2(300,100)), 'completed')
	yield(drag_drop(cards[1],Vector2(300,200)), 'completed')
	yield(drag_drop(cards[5],Vector2(300,300)), 'completed')
	yield(drag_drop(cards[7],Vector2(300,400)), 'completed')

	yield(drag_drop(cards[0],Vector2(300,600)), 'completed')

	var card: Card

	cards.append(hand.draw_card())
	yield(yield_for(0.1), YIELD)
	cards.append(hand.draw_card())
	yield(yield_for(0.7), YIELD)
	yield(drag_drop(cards[1],Vector2(300,600)), 'completed')
	yield(yield_for(0.7), YIELD)
	assert_eq(8,hand.get_card_count(),"Check if we have the correct amount of cards in hand")
	for c in cards:
		if c.get_parent() == cfc.NMAP.hand:
			assert_eq(0,c.z_index,"Check if card in hand at index 0")

