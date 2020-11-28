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
	watch_signals(target)
	watch_signals(card)
	# Test "self" trigger works
	card.scripts = {"card_rotated": { "board": [
			{"name": "flip_card",
			"subject": "self",
			"trigger": "self",
			"set_faceup": false}]}}
	yield(table_move(card, Vector2(100,100)), "completed")
	card.card_rotation = 90
	yield(yield_to(card._flip_tween, "tween_all_completed", 1), YIELD)
	assert_signal_emitted_with_parameters(card,"card_flipped",[card,"card_flipped",[false]])
	assert_signal_emitted_with_parameters(card,"card_rotated",[card,"card_rotated",[90]])
	# Test "any" trigger works
	target.scripts = {"card_rotated": { "board": [
			{"name": "flip_card",
			"subject": "self",
			"set_faceup": false}]}}
	yield(table_move(target, Vector2(500,100)), "completed")
	target.card_rotation = 90
	yield(yield_to(target._flip_tween, "tween_all_completed", 1), YIELD)
	assert_signal_emitted_with_parameters(target,"card_flipped",[target,"card_flipped",[false]])
	assert_signal_emitted_with_parameters(target,"card_rotated",[target,"card_rotated",[90]])

func test_card_rotated():
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
	yield(yield_to(card._tween, "tween_all_completed", 1), YIELD)
	assert_signal_emitted_with_parameters(target,"card_rotated",[target,"card_rotated",[90]])
	assert_signal_emitted_with_parameters(card,"card_rotated",[card,"card_rotated",[270]])


func test_card_flipped():
	watch_signals(card)
	watch_signals(target)
	card.scripts = {"card_flipped": { "hand": [
			{"name": "flip_card",
			"subject": "self",
			"trigger": "another",
			"set_faceup": false}]}}
	target.is_faceup = false
	yield(yield_to(target._flip_tween, "tween_all_completed", 1), YIELD)
	assert_signal_emitted_with_parameters(target,"card_flipped",[target,"card_flipped",[false]])
	assert_signal_emitted_with_parameters(card,"card_flipped",[card,"card_flipped",[false]])

func test_card_viewed():
	watch_signals(card)
	watch_signals(target)
	card.scripts = {"card_viewed": { "hand": [
			{"name": "flip_card",
			"subject": "self",
			"trigger": "another",
			"set_faceup": false}]}}
	yield(table_move(target, Vector2(600,100)), "completed")
	target.is_faceup = false
	yield(yield_to(target._flip_tween, "tween_all_completed", 1), YIELD)
	target.is_viewed = true
	yield(yield_for(0.5), YIELD)
	assert_signal_emitted_with_parameters(target,"card_viewed",[target,"card_viewed",[true]])
	assert_signal_emitted_with_parameters(card,"card_flipped",[card,"card_flipped",[false]])
