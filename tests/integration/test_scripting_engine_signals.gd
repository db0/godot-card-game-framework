extends "res://tests/UTcommon.gd"

var cards := []
var card: Card
var target: Card

func before_all():
	cfc.fancy_movement = false

func after_all():
	cfc.fancy_movement = true

func before_each():
	setup_board()
	cards = draw_test_cards(5)
	yield(yield_for(0.5), YIELD)
	card = cards[0]
	target = cards[2]


func test_signals():
	for sgn in  cfc.signal_propagator.known_card_signals:
		assert_connected(card, cfc.signal_propagator, sgn, "_on_Card_signal_received")
		assert_connected(target, cfc.signal_propagator, sgn, "_on_Card_signal_received")
	watch_signals(card)
	watch_signals(target)
	card.scripts = {"card_rotated": { "board": [
			{"name": "rotate_card",
			"subject": "self",
			"trigger": "another",
			"degrees": 270}]}}
	yield(table_move(card, Vector2(100,100)), "completed")
	yield(table_move(target, Vector2(500,100)), "completed")
	target.card_rotation = 90
	yield(yield_to(target._tween, "tween_all_completed", 1), YIELD)
	assert_signal_emitted(target,"card_rotated")
	assert_signal_emitted(card,"card_rotated")
