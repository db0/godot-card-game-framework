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
	cards = draw_test_cards(9)
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
			"set_faceup": false}],
			"trigger": "self"}}
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


func test_card_properties_filter():
	var target2: Card = cards[8]
	var ttype : String = target.properties["Type"]
	var ttype2 : String = target2.properties["Type"]
	card.scripts = {"card_rotated": {
			"hand": [
				{"name": "flip_card",
				"subject": "target",
				"filter_properties_subject": {"Type": ttype2},
				"set_faceup": false}],
			"filter_properties_trigger": {"Type": "FALSE"},
			"trigger": "another"}}
	cards[2].scripts = {"card_rotated": {
			"hand": [
				{"name": "flip_card",
				"subject": "self",
				"set_faceup": false}],
			"filter_properties_trigger": {"Type": "FALSE"},
			"trigger": "another"}}
	cards[3].scripts = {"card_rotated": {
			"hand": [
				{"name": "flip_card",
				"subject": "self",
				"set_faceup": false}],
			"filter_properties_trigger": {"Type": ttype},
			"trigger": "another"}}
	cards[4].scripts = {"card_rotated": {
			"hand": [
				{"name": "flip_card",
				"subject": "self",
				"set_faceup": false}],
			"filter_properties_trigger": {"Type": ttype, "Tags": "Tag 1"},
			"trigger": "another"}}
	cards[5].scripts = {"card_rotated": {
			"hand": [
				{"name": "flip_card",
				"subject": "self",
				"set_faceup": false}],
			"filter_properties_trigger": {"Type": "FALSE"},
			"trigger": "another"}}
	cards[6].scripts = {"card_rotated": {
			"hand": [
				{"name": "flip_card",
				"subject": "target",
				"filter_properties_subject": {"Type": ttype2},
				"set_faceup": false}],
			"filter_properties_trigger": {"Type": ttype},
			"trigger": "another"}}
	cards[7].scripts = {"card_rotated": {
			"hand": [
				{"name": "flip_card",
				"subject": "target",
				"filter_properties_subject": {"Type": "FALSE"},
				"set_faceup": false}],
			"filter_properties_trigger": {"Type": ttype2},
			"trigger": "another"}}
	yield(yield_for(0.5), YIELD)
	yield(table_move(target, Vector2(500,100)), "completed")
	yield(table_move(target2, Vector2(900,100)), "completed")
	target.card_rotation = 90
	yield(yield_for(0.5), YIELD)
	assert_false(card.targeting_arrow.is_targeting,
			"Card did not start targeting since filter_properties_trigger"
			+ "  did not match even though filter_properties_subject matched")
	yield(target_card(cards[6],target2), "completed")
	yield(yield_to(target._flip_tween, "tween_all_completed", 1), YIELD)
	assert_true(cards[2].is_faceup,
			"Card stayed face-up since filter_properties_trigger didn't match")
	assert_false(cards[3].is_faceup,
			"Card turned face-down since filter_properties_trigger matches")
	assert_false(cards[4].is_faceup,
			"Card turned face-down since multiple filter_properties_trigger match")
	assert_true(cards[5].is_faceup,
			"Card stayed face-up since filter_properties_trigger array property did not match")
	assert_true(target.is_faceup,
			"Card stayed face-up since filter_properties_subject didn't match"
			+ " even though filter_properties_trigger matches")
	assert_false(target2.is_faceup,
			"Card turned face-down since filter_properties_subject matched"
			+ " even though filter_properties_trigger does not match")
	target2.card_rotation = 90
	yield(yield_for(0.5), YIELD)
	assert_true(cards[7].targeting_arrow.is_targeting,
			"Card started targeting since filter_properties_trigger "
			+ "match even though filter_properties_subject don't match")
	assert_false(cards[6].targeting_arrow.is_targeting,
			"Card did not start targeting since filter_properties_trigger"
			+ "  did not match even though filter_properties_subject matched")
	yield(target_card(cards[7],target), "completed")
	yield(yield_to(target._flip_tween, "tween_all_completed", 1), YIELD)
	assert_true(target.is_faceup,
			"Card stayed face-up since filter_properties_subject didn't match"
			+ " even though filter_properties_trigger matches")


func test_card_rotated():
	watch_signals(target)
	card.scripts = {"card_rotated": {
			"hand": [
				{"name": "flip_card",
				"subject": "self",
				"set_faceup": false}],
			"trigger": "another"}}
	cards[2].scripts = {"card_rotated": {
			"hand": [
				{"name": "flip_card",
				"subject": "self",
				"set_faceup": false}],
			"filter_degrees": 270,
			"trigger": "another"}}
	cards[3].scripts = {"card_rotated": {
			"hand": [
				{"name": "flip_card",
				"subject": "self",
				"set_faceup": false}],
			"filter_degrees": 90,
			"trigger": "another"}}
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
			"Card stayed face-up since filter_degrees didn't match")
	assert_false(cards[3].is_faceup,
			"Card turned face-down since filter_degrees matches")


func test_card_flipped():
	watch_signals(target)
	card.scripts = {"card_flipped": {
			"hand": [
				{"name": "flip_card",
				"subject": "self",
				"set_faceup": false}],
			"trigger": "another"}}
	cards[2].scripts = {"card_flipped": {
			"hand": [
				{"name": "flip_card",
				"subject": "self",
				"set_faceup": false}],
			"filter_faceup": true,
			"trigger": "another"}}
	cards[3].scripts = {"card_flipped": {
			"hand": [
				{"name": "flip_card",
				"subject": "self",
				"set_faceup": false}],
			"filter_faceup": false,
			"trigger": "another"}}

	target.is_faceup = false
	yield(yield_to(target._flip_tween, "tween_all_completed", 1), YIELD)
	assert_signal_emitted_with_parameters(
				target,"card_flipped",
				[target,"card_flipped",
				{"is_faceup": false}])
	assert_false(card.is_faceup,
			"Card turned face-down after signal trigger")
	assert_true(cards[2].is_faceup,
			"Card stayed face-up since filter_facup didn't match")
	assert_false(cards[3].is_faceup,
			"Card turned face-down since filter_facup matches")

func test_card_viewed():
	watch_signals(target)
	card.scripts = {"card_viewed": {
			"hand": [
				{"name": "flip_card",
				"subject": "self",
				"set_faceup": false}],
			"trigger": "another"}}

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
	watch_signals(target)
	card.scripts = {"card_moved_to_hand": {
			"hand": [
				{"name": "flip_card",
				"subject": "self",
				"set_faceup": false}],
			"trigger": "another"}}
	target.move_to(hand)
	yield(yield_to(target._tween, "tween_all_completed", 1), YIELD)
	assert_signal_emitted_with_parameters(
				target,"card_moved_to_hand",
				[target,"card_moved_to_hand",
				{"destination": hand, "source": deck}])
	assert_false(card.is_faceup,
			"Card turned face-down after signal trigger")

func test_card_moved_to_board():
	watch_signals(target)
	card.scripts = {"card_moved_to_board": {
			"hand": [
				{"name": "flip_card",
				"subject": "self",
				"trigger": "another",
				"set_faceup": false}],
			"trigger": "another"}}
	target.move_to(board, -1, Vector2(100,100))
	yield(yield_to(target._tween, "tween_all_completed", 1), YIELD)
	assert_signal_emitted_with_parameters(
				target,"card_moved_to_board",
				[target,"card_moved_to_board",
				{"destination": board, "source": hand}])
	assert_false(card.is_faceup,
			"Card turned face-down after signal trigger")

func test_card_moved_to_pile():
	watch_signals(target)
	# This card should turn face-down since there's no limit
	card.scripts = {"card_moved_to_pile": {
			"hand": [
				{"name": "flip_card",
				"subject": "self",
				"set_faceup": false}],
			"trigger": "another"}}
	# This card should stay face-up since destination limit will be false
	cards[2].scripts = {"card_moved_to_pile": {
			"hand": [
				{"name": "flip_card",
				"subject": "self",
				"set_faceup": false}],
			"filter_destination": deck,
			"trigger": "another"}}
	# This card should stay face-up since limit will be false
	cards[3].scripts = {"card_moved_to_pile": {
			"hand": [
				{"name": "flip_card",
				"subject": "self",
				"set_faceup": false}],
			"filter_source": deck,
			"trigger": "another"}}
	# This card should turn face-down since both limits will be true
	cards[4].scripts = {"card_moved_to_pile": {
			"hand": [
				{"name": "flip_card",
				"subject": "self",
				"set_faceup": false}],
			"filter_source": hand,
			"filter_destination": discard,
			"trigger": "another"}}
	# This card should stay face-up since both limits will be false
	cards[5].scripts = {"card_moved_to_pile": {
			"hand": [
				{"name": "flip_card",
				"subject": "self",
				"set_faceup": false}],
			"filter_source": discard,
			"filter_destination": deck,
			"trigger": "another"}}
	cards[6].scripts = {"card_moved_to_pile": {
			"hand": [
				{"name": "flip_card",
				"subject": "self",
				"set_faceup": false}],
			"filter_destination": discard,
			"trigger": "another"}}
	target.move_to(discard)
	yield(yield_to(target._tween, "tween_all_completed", 1), YIELD)
	assert_signal_emitted_with_parameters(
				target,"card_moved_to_pile",
				[target,"card_moved_to_pile",
				{"destination": discard, "source": hand}])
	assert_false(card.is_faceup,
			"Card turned face-down after signal trigger")
	assert_true(cards[2].is_faceup,
			"Card stayed face-up filter_destination limit does not match")
	assert_true(cards[3].is_faceup,
			"Card stayed face-up since filter_source does not match")
	assert_false(cards[4].is_faceup,
			"Card turned face-down since both limits match")
	assert_true(cards[5].is_faceup,
			"Card stayed face-up since both limits do not match")
	assert_false(cards[6].is_faceup,
			"Card turned face-down since filter_destination matches")

func test_card_token_modified():
	# warning-ignore:return_value_discarded
	target.tokens.mod_token("void",5)
	yield(yield_for(0.1), YIELD)
	watch_signals(target)
	# This card should turn face-down since there's no limit
	card.scripts = {"card_token_modified": {
			"hand": [
				{"name": "flip_card",
				"subject": "self",
				"set_faceup": false}],
			"trigger": "another"}}

	# This card should stay face-up since token_name limit will not match
	cards[2].scripts = {"card_token_modified": {
			"hand": [
				{"name": "flip_card",
				"subject": "self",
				"set_faceup": false}],
			"filter_token_name": "Bio",
			"trigger": "another"}}
	# This card should stay face-up since token_count will not match
	cards[3].scripts = {"card_token_modified": {
			"hand": [
				{"name": "flip_card",
				"subject": "self",
				"set_faceup": false}],
			"filter_token_count": 10,
			"trigger": "another"}}
	# This card should stay face-up since token_difference will not have incr.
	cards[4].scripts = {"card_token_modified": {
			"hand": [
				{"name": "flip_card",
				"subject": "self",
				"set_faceup": false}],
			"filter_token_difference": "increased",
			"trigger": "another"}}
	# This card should turn face-down since token_difference will decrease
	cards[5].scripts = {"card_token_modified": {
			"hand": [
				{"name": "flip_card",
				"subject": "self",
				"set_faceup": false}],
			"filter_token_difference": "decreased",
			"trigger": "another"}}
	# This card should turn face-down since all limits will match
	cards[6].scripts = {"card_token_modified": {
			"hand": [
				{"name": "flip_card",
				"subject": "self",
				"set_faceup": false}],
			"filter_token_difference": "decreased",
			"filter_token_count": 0,
			"filter_token_name": "Void",
			"trigger": "another"}}
	# This card should stay face-up since some limits will not match
	cards[7].scripts = {"card_token_modified": {
			"hand": [
				{"name": "flip_card",
				"subject": "self",
				"set_faceup": false}],
			"filter_token_difference": "decreased",
			"filter_token_count": 1,
			"filter_token_name": "Tech",
			"trigger": "another"}}
	# warning-ignore:return_value_discarded
	target.tokens.mod_token("void", -5)
	yield(yield_for(0.1), YIELD)
	assert_signal_emitted_with_parameters(
				target,"card_token_modified",
				[target,"card_token_modified",
				{"token_name": "Void",
				"previous_token_value": 5,
				"new_token_value": 0}])
	assert_false(card.is_faceup,
			"Card turned face-down after signal trigger")
	assert_true(cards[2].is_faceup,
			"Card stayed face-up filter_token_name does not match")
	assert_true(cards[3].is_faceup,
			"Card stayed face-up since filter_token_count does not match")
	assert_true(cards[4].is_faceup,
			"Card stayed face-up since filter_token_difference does not match")
	assert_false(cards[5].is_faceup,
			"Card turned face-down since filter_token_difference matches")
	assert_false(cards[6].is_faceup,
			"Card turned face-down since all limits match")
	assert_true(cards[7].is_faceup,
			"Card stayed face-up since some limits do not match")


func test_card_targeted():
	watch_signals(target)
	card.scripts = {"card_targeted": {
			"hand": [
				{"name": "flip_card",
				"subject": "self",
				"set_faceup": false}],
			"trigger": "another"}}
	cards[4].targeting_arrow.initiate_targeting()
	yield(target_card(cards[4], target), "completed")
	yield(yield_for(0.1), YIELD)

	assert_signal_emitted_with_parameters(
				target,"card_targeted",
				[target,"card_targeted",
				{"targeting_source": cards[4]}])
	assert_false(card.is_faceup,
			"Card turned face-down after signal trigger")

func test_card_un_attached():
	watch_signals(target)
	var host = cards[2]
	card.scripts = {"card_attached": {
			"hand": [
				{"name": "flip_card",
				"subject": "self",
				"set_faceup": false}],
			"trigger": "another"}}
	cards[3].scripts = {"card_unattached": {
			"hand": [
				{"name": "flip_card",
				"subject": "self",
				"set_faceup": false}],
			"trigger": "another"}}
	yield(table_move(host, Vector2(500,100)), "completed")
	yield(table_move(target, Vector2(500,50)), "completed")
	target.attach_to_host(host)
	yield(yield_for(0.1), YIELD)
	assert_signal_emitted_with_parameters(
				target,"card_attached",
				[target,"card_attached",
				{"host": host}])
	assert_false(card.is_faceup,
			"Card turned face-down after signal trigger")
	target.move_to(discard)
	yield(yield_for(0.5), YIELD)
	assert_signal_emitted_with_parameters(
				target,"card_unattached",
				[target,"card_unattached",
				{"host": host}])
	assert_false(cards[3].is_faceup,
			"Card turned face-down after signal trigger")

func test_card_properties_modified():
	watch_signals(target)
	card.scripts = {"card_properties_modified": {
			"hand": [
				{"name": "flip_card",
				"subject": "self",
				"set_faceup": false}],
			"filter_modified_properties": {"Type": {}},
			"trigger": "another"}}
	cards[2].scripts = {"card_properties_modified": {
			"hand": [
				{"name": "flip_card",
				"subject": "self",
				"set_faceup": false}],
			"filter_modified_properties": {"Tag": {}},
			"trigger": "another"}}
	cards[3].scripts = {"card_properties_modified": {
			"hand": [
				{"name": "flip_card",
				"subject": "self",
				"set_faceup": false}],
			"filter_modified_properties": {"Type":
				{"new_value": "Orange",
				"previous_value": "Green"}},
			"trigger": "another"}}
	cards[4].scripts = {"card_properties_modified": {
			"hand": [
				{"name": "flip_card",
				"subject": "self",
				"set_faceup": false}],
			"filter_modified_properties": {"Type":
				{"new_value": "Purple"}},
			"trigger": "another"}}
	target.modify_property("Type", "Orange")
	cards[4]._debugger_hook = true
	yield(yield_for(0.1), YIELD)
	assert_signal_emitted_with_parameters(
				target,"card_properties_modified",
				[target,"card_properties_modified",
				{"property_name": "Type",
				"new_property_value": "Orange",
				"previous_property_value": "Green"}])
	assert_false(card.is_faceup,
			"Card turned face-down after signal trigger match")
	assert_true(cards[2].is_faceup,
			"Card stayed face-up after signal trigger not matching")
	assert_false(cards[3].is_faceup,
			"Card turned face-down after all property filters match")
	assert_true(cards[4].is_faceup,
			"Card stayed face-up after after one property filters not matching")
