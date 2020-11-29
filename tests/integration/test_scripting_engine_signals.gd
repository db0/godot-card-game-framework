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
	cards = draw_test_cards(8)
	yield(yield_for(0.5), YIELD)
	card = cards[0]
	target = cards[1]


func test_signals():
	for sgn in  cfc.signal_propagator.known_card_signals:
		assert_connected(card, cfc.signal_propagator, sgn,
				"_on_Card_signal_received")
		assert_connected(target, cfc.signal_propagator, sgn,
				"_on_Card_signal_received")
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
	assert_signal_emitted_with_parameters(
				card,"card_flipped",[card,"card_flipped",{"is_faceup": false}])
	assert_signal_emitted_with_parameters(
				card,"card_rotated",[card,"card_rotated",{"degrees": 90}])
	# Test "any" trigger works
	target.scripts = {"card_rotated": { "board": [
			{"name": "flip_card",
			"subject": "self",
			"set_faceup": false}]}}
	yield(table_move(target, Vector2(500,100)), "completed")
	target.card_rotation = 90
	yield(yield_to(target._flip_tween, "tween_all_completed", 1), YIELD)
	assert_signal_emitted_with_parameters(
				target,"card_flipped",[target,"card_flipped",{"is_faceup": false}])
	assert_signal_emitted_with_parameters(
				target,"card_rotated",[target,"card_rotated",{"degrees": 90}])

func test_card_rotated():
	watch_signals(card)
	watch_signals(target)
	card.scripts = {"card_rotated": { "hand": [
			{"name": "flip_card",
			"subject": "self",
			"trigger": "another",
			"set_faceup": false}]}}
	cards[2].scripts = {"card_rotated": { "hand": [
			{"name": "flip_card",
			"subject": "self",
			"trigger": "another",
			"limit_to_degrees": 270,
			"set_faceup": false}]}}
	cards[3].scripts = {"card_rotated": { "hand": [
			{"name": "flip_card",
			"subject": "self",
			"trigger": "another",
			"limit_to_degrees": 90,
			"set_faceup": false}]}}
	yield(table_move(target, Vector2(500,100)), "completed")
	target.card_rotation = 90
	yield(yield_to(card._tween, "tween_all_completed", 1), YIELD)
	assert_signal_emitted_with_parameters(
				target,"card_rotated",
				[target,"card_rotated",
				{"degrees": 90}])
	assert_false(card.is_faceup,
			"Card turned face-down after signal trigger")
	assert_true(cards[2].is_faceup,
			"Card stayed face-up since limit_to_degrees is false")
	assert_false(cards[3].is_faceup,
			"Card turned face-down since limit_to_degrees is true")


func test_card_flipped():
	watch_signals(card)
	watch_signals(target)
	card.scripts = {"card_flipped": { "hand": [
			{"name": "flip_card",
			"subject": "self",
			"trigger": "another",
			"set_faceup": false}]}}
	cards[2].scripts = {"card_flipped": { "hand": [
			{"name": "flip_card",
			"subject": "self",
			"trigger": "another",
			"limit_to_faceup": true,
			"set_faceup": false}]}}
	cards[3].scripts = {"card_flipped": { "hand": [
			{"name": "flip_card",
			"subject": "self",
			"trigger": "another",
			"limit_to_faceup": false,
			"set_faceup": false}]}}
	target.is_faceup = false
	yield(yield_to(target._flip_tween, "tween_all_completed", 1), YIELD)
	assert_signal_emitted_with_parameters(
				target,"card_flipped",
				[target,"card_flipped",
				{"is_faceup": false}])
	assert_false(card.is_faceup,
			"Card turned face-down after signal trigger")
	assert_true(cards[2].is_faceup,
			"Card stayed face-up since limit_to_facup is true")
	assert_false(cards[3].is_faceup,
			"Card turned face-down since limit_to_facup is false")

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
	assert_signal_emitted_with_parameters(
				target,"card_viewed",
				[target,"card_viewed",
				{"is_viewed": true}])
	assert_false(card.is_faceup,
			"Card turned face-down after signal trigger")

func test_card_moved_to_hand():
	target = cfc.NMAP.deck.get_top_card()
	watch_signals(card)
	watch_signals(target)
	card.scripts = {"card_moved_to_hand": { "hand": [
			{"name": "flip_card",
			"subject": "self",
			"trigger": "another",
			"set_faceup": false}]}}
	target.move_to(hand)
	yield(yield_to(target._tween, "tween_all_completed", 1), YIELD)
	assert_signal_emitted_with_parameters(
				target,"card_moved_to_hand",
				[target,"card_moved_to_hand",
				{"destination": hand, "source": deck}])
	assert_false(card.is_faceup,
			"Card turned face-down after signal trigger")

func test_card_moved_to_board():
	watch_signals(card)
	watch_signals(target)
	card.scripts = {"card_moved_to_board": { "hand": [
			{"name": "flip_card",
			"subject": "self",
			"trigger": "another",
			"set_faceup": false}]}}
	target.move_to(board, -1, Vector2(100,100))
	yield(yield_to(target._tween, "tween_all_completed", 1), YIELD)
	assert_signal_emitted_with_parameters(
				target,"card_moved_to_board",
				[target,"card_moved_to_board",
				{"destination": board, "source": hand}])
	assert_false(card.is_faceup,
			"Card turned face-down after signal trigger")

func test_card_moved_to_pile():
	watch_signals(card)
	watch_signals(target)
	# This card should turn face-down since there's no limit
	card.scripts = {"card_moved_to_pile": { "hand": [
			{"name": "flip_card",
			"subject": "self",
			"trigger": "another",
			"set_faceup": false}]}}
	# This card should stay face-up since destination limit will be false
	cards[2].scripts = {"card_moved_to_pile": { "hand": [
			{"name": "flip_card",
			"subject": "self",
			"trigger": "another",
			"limit_to_destination": deck,
			"set_faceup": false}]}}
	# This card should stay face-up since limit will be false
	cards[3].scripts = {"card_moved_to_pile": { "hand": [
			{"name": "flip_card",
			"subject": "self",
			"trigger": "another",
			"limit_to_source": deck,
			"set_faceup": false}]}}
	# This card should turn face-down since both limits will be true
	cards[4].scripts = {"card_moved_to_pile": { "hand": [
			{"name": "flip_card",
			"subject": "self",
			"trigger": "another",
			"limit_to_source": hand,
			"limit_to_destination": discard,
			"set_faceup": false}]}}
	# This card should stay face-up since both limits will be false
	cards[5].scripts = {"card_moved_to_pile": { "hand": [
			{"name": "flip_card",
			"subject": "self",
			"trigger": "another",
			"limit_to_source": discard,
			"limit_to_destination": deck,
			"set_faceup": false}]}}
	cards[6].scripts = {"card_moved_to_pile": { "hand": [
			{"name": "flip_card",
			"subject": "self",
			"trigger": "another",
			"limit_to_destination": discard,
			"set_faceup": false}]}}
	target.move_to(discard)
	yield(yield_to(target._tween, "tween_all_completed", 1), YIELD)
	assert_signal_emitted_with_parameters(
				target,"card_moved_to_pile",
				[target,"card_moved_to_pile",
				{"destination": discard, "source": hand}])
	assert_false(card.is_faceup,
			"Card turned face-down after signal trigger")
	assert_true(cards[2].is_faceup,
			"Card stayed face-up limit_to_destination limit does not match")
	assert_true(cards[3].is_faceup,
			"Card stayed face-up since limit_to_source does not match")
	assert_false(cards[4].is_faceup,
			"Card turned face-down since both limits match")
	assert_true(cards[5].is_faceup,
			"Card stayed face-up since both limits do not match")
	assert_false(cards[6].is_faceup,
			"Card turned face-down since limit_to_destination matches")
