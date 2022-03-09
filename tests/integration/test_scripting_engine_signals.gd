extends "res://tests/UTcommon.gd"

class TestSignals:
	extends "res://tests/ScEng_common.gd"

	func test_signals():
		for sgn in  cfc.signal_propagator.known_card_signals:
			assert_connected(card, cfc.signal_propagator, sgn,
					"_on_signal_received")
			assert_connected(target, cfc.signal_propagator, sgn,
					"_on_signal_received")
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
					card,"card_flipped",[card,"card_flipped",{"is_faceup": false,
					"tags": ["Scripted"]}])
		assert_signal_emitted_with_parameters(
					card,"card_rotated",[card,"card_rotated",{"degrees": 90,
					"tags": ["Manual"]}])
		# Test "any" trigger works
		target.scripts = {"card_rotated": { "board": [
				{"name": "flip_card",
				"subject": "self",
				"set_faceup": false}]}}
		yield(table_move(target, Vector2(500,100)), "completed")
		target.card_rotation = 90
		yield(yield_to(target._flip_tween, "tween_all_completed", 1), YIELD)
		assert_signal_emitted_with_parameters(
					target,"card_flipped",[target,"card_flipped",
					{"is_faceup": false,
					"tags": ["Scripted"]}])
		assert_signal_emitted_with_parameters(
					target,"card_rotated",[target,"card_rotated",{"degrees": 90,
					"tags": ["Manual"]}])

class TestCardPropertiesFilter:
	extends "res://tests/ScEng_common.gd"
	func _init() -> void:
		initial_card_count = 9
		target_index = 1
		

	func test_card_properties_filter():
		cards += draw_test_cards(1)
		var target2: Card = cards[9]
		var ttype : String = target.properties["Type"]
		var ttype2 : String = target2.properties["Type"]
		card.scripts = {"card_rotated": {
				"hand": [
					{"name": "flip_card",
					"subject": "target",
					"filter_state_subject": [{"filter_properties": {"Type": ttype2}}],
					"set_faceup": false}],
				"filter_state_trigger": [{"filter_properties": {"Type": "FALSE"}}],
				"trigger": "another"}}
		cards[2].scripts = {"card_rotated": {
				"hand": [
					{"name": "flip_card",
					"subject": "self",
					"set_faceup": false}],
				"filter_state_trigger": [{"filter_properties": {"Type": "FALSE"}}],
				"trigger": "another"}}
		cards[3].scripts = {"card_rotated": {
				"hand": [
					{"name": "flip_card",
					"subject": "self",
					"set_faceup": false}],
				"filter_state_trigger": [{"filter_properties": {"Type": ttype}}],
				"trigger": "another"}}
		cards[4].scripts = {"card_rotated": {
				"hand": [
					{"name": "flip_card",
					"subject": "self",
					"set_faceup": false}],
				"filter_state_trigger": [{"filter_properties": {"Type": ttype, "Tags": "Tag 1"}}],
				"trigger": "another"}}
		cards[5].scripts = {"card_rotated": {
				"hand": [
					{"name": "flip_card",
					"subject": "self",
					"set_faceup": false}],
				"filter_state_trigger": [{"filter_properties": {"Type": "FALSE"}}],
				"trigger": "another"}}
		cards[6].scripts = {"card_rotated": {
				"hand": [
					{"name": "flip_card",
					"subject": "target",
					"filter_state_subject": [{"filter_properties": {"Type": ttype2}}],
					"set_faceup": false}],
				"filter_state_trigger": [{"filter_properties": {"Type": ttype}}],
				"trigger": "another"}}
		cards[7].scripts = {"card_rotated": {
				"hand": [
					{"name": "flip_card",
					"subject": "target",
					"filter_state_subject": [{"filter_properties": {"Type": "FALSE"}}],
					"set_faceup": false}],
				"filter_state_trigger": [{"filter_properties": {"Type": ttype2}}],
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

class TestCardRotates:
	extends "res://tests/ScEng_common.gd"

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
		cards[4].scripts = {"card_rotated": {
				"hand": [
					{"name": "flip_card",
					"subject": "self",
					"set_faceup": false}],
				"filter_degrees": 0,
				"trigger": "another"}}
		yield(table_move(target, Vector2(500,100)), "completed")
		target.card_rotation = 90
		yield(yield_to(card._tween, "tween_all_completed", 1), YIELD)
		assert_signal_emitted_with_parameters(
					target,"card_rotated",
					[target,"card_rotated",
					{"degrees": 90,
					"tags": ["Manual"]}])
		assert_false(card.is_faceup,
				"Card turned face-down after signal trigger")
		assert_true(cards[2].is_faceup,
				"Card stayed face-up since filter_degrees didn't match")
		assert_false(cards[3].is_faceup,
				"Card turned face-down since filter_degrees matches")
		assert_true(cards[4].is_faceup,
				"Card stayed face-up since 0 filter_degrees didn't match")

class TestCardFlipped:
	extends "res://tests/ScEng_common.gd"
	func _init() -> void:
		initial_card_count = 9
		target_index = 1

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
					{"is_faceup": false,
					"tags": ["Manual"]}])
		assert_false(card.is_faceup,
				"Card turned face-down after signal trigger")
		assert_true(cards[2].is_faceup,
			 "Card stayed face-up since filter_facup didn't match")
		assert_false(cards[3].is_faceup,
				"Card turned face-down since filter_facup matches")

class TestCardViewed:
	extends "res://tests/ScEng_common.gd"

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

class TestCardMovedToHand:
	extends "res://tests/ScEng_common.gd"

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
					{"destination": "Hand", "source": "Deck",
					"tags": ["Manual"]}])
		assert_false(card.is_faceup,
				"Card turned face-down after signal trigger")

class TestCardMovedToBoard:
	extends "res://tests/ScEng_common.gd"

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
					{"destination": "Board", "source": "Hand",
					"tags": ["Manual"]}])
		assert_false(card.is_faceup,
				"Card turned face-down after signal trigger")


class TestCardMovedToPile:
	extends "res://tests/ScEng_common.gd"
	func _init() -> void:
		initial_card_count = 9

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
				"filter_destination": "Deck",
				"trigger": "another"}}
		# This card should stay face-up since limit will be false
		cards[3].scripts = {"card_moved_to_pile": {
				"hand": [
					{"name": "flip_card",
					"subject": "self",
					"set_faceup": false}],
				"filter_source": "Deck",
				"trigger": "another"}}
		# This card should turn face-down since both limits will be true
		cards[4].scripts = {"card_moved_to_pile": {
				"hand": [
					{"name": "flip_card",
					"subject": "self",
					"set_faceup": false}],
				"filter_source": "Hand",
				"filter_destination": "Discard",
				"trigger": "another"}}
		# This card should stay face-up since both limits will be false
		cards[5].scripts = {"card_moved_to_pile": {
				"hand": [
					{"name": "flip_card",
					"subject": "self",
					"set_faceup": false}],
				"filter_source": "Discard",
				"filter_destination": "Deck",
				"trigger": "another"}}
		cards[6].scripts = {"card_moved_to_pile": {
				"hand": [
					{"name": "flip_card",
					"subject": "self",
					"set_faceup": false}],
				"filter_destination": "Discard",
				"trigger": "another"}}
		target.move_to(discard)
		yield(yield_to(target._tween, "tween_all_completed", 1), YIELD)
		assert_signal_emitted_with_parameters(
					target,"card_moved_to_pile",
					[target,"card_moved_to_pile",
					{"destination": "Discard", "source": "Hand",
					"tags": ["Manual"]}])
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

class TestCardTokenModified:
	extends "res://tests/ScEng_common.gd"
	func _init() -> void:
		initial_card_count = 9

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
				"filter_count": 10,
				"trigger": "another"}}
		# This card should stay face-up since token_difference will not have incr.
		cards[4].scripts = {"card_token_modified": {
				"hand": [
					{"name": "flip_card",
					"subject": "self",
					"set_faceup": false}],
				"filter_count_difference": "increased",
				"trigger": "another"}}
		# This card should turn face-down since token_difference will decrease
		cards[5].scripts = {"card_token_modified": {
				"hand": [
					{"name": "flip_card",
					"subject": "self",
					"set_faceup": false}],
				"filter_count_difference": "decreased",
				"trigger": "another"}}
		# This card should turn face-down since all limits will match
		cards[6].scripts = {"card_token_modified": {
				"hand": [
					{"name": "flip_card",
					"subject": "self",
					"set_faceup": false}],
				"filter_count_difference": "decreased",
				"filter_count": 1,
				"filter_token_name": "void",
				"trigger": "another"}}
		# This card should stay face-up since some limits will not match
		cards[7].scripts = {"card_token_modified": {
				"hand": [
					{"name": "flip_card",
					"subject": "self",
					"set_faceup": false}],
				"filter_count_difference": "decreased",
				"filter_count": 0,
				"filter_token_name": "Tech",
				"trigger": "another"}}
		# warning-ignore:return_value_discarded
		target.tokens.mod_token("void", -4)
		yield(yield_for(0.1), YIELD)
		assert_signal_emitted_with_parameters(
					target,"card_token_modified",
					[target,"card_token_modified",
					{"token_name": "void",
					"previous_count": 5,
					"new_count": 1,
					"tags": ["Manual"]}])
		assert_false(card.is_faceup,
				"Card turned face-down after signal trigger")
		assert_true(cards[2].is_faceup,
				"Card stayed face-up filter_token_name does not match")
		assert_true(cards[3].is_faceup,
				"Card stayed face-up since filter_count does not match")
		assert_true(cards[4].is_faceup,
				"Card stayed face-up since filter_difference does not match")
		assert_false(cards[5].is_faceup,
				"Card turned face-down since filter_difference matches")
		assert_false(cards[6].is_faceup,
				"Card turned face-down since all limits match")
		assert_true(cards[7].is_faceup,
				"Card stayed face-up since some limits do not match")

class TestCounterModified:
	extends "res://tests/ScEng_common.gd"
	func _init() -> void:
		initial_card_count = 9

	func test_counter_modified():
		# warning-ignore:return_value_discarded
		board.counters.mod_counter("research",5)
		watch_signals(board.counters)
		# This card should turn face-down since there's no limit
		card.scripts = {"counter_modified": {
				"hand": [
					{"name": "flip_card",
					"subject": "self",
					"set_faceup": false}],
				"trigger": "another"}}

		# This card should stay face-up since counter_name limit will not match
		cards[2].scripts = {"counter_modified": {
				"hand": [
					{"name": "flip_card",
					"subject": "self",
					"set_faceup": false}],
				"filter_counter_name": "Bio",
				"trigger": "another"}}
		# This card should stay face-up since count will not match
		cards[3].scripts = {"counter_modified": {
				"hand": [
					{"name": "flip_card",
					"subject": "self",
					"set_faceup": false}],
				"filter_count": 10,
				"trigger": "another"}}
		# This card should stay face-up since difference will not have incr.
		cards[4].scripts = {"counter_modified": {
				"hand": [
					{"name": "flip_card",
					"subject": "self",
					"set_faceup": false}],
				"filter_count_difference": "increased",
				"trigger": "another"}}
		# This card should turn face-down since difference will decrease
		cards[5].scripts = {"counter_modified": {
				"hand": [
					{"name": "flip_card",
					"subject": "self",
					"set_faceup": false}],
				"filter_count_difference": "decreased",
				"trigger": "another"}}
		# This card should turn face-down since all limits will match
		cards[6].scripts = {"counter_modified": {
				"hand": [
					{"name": "flip_card",
					"subject": "self",
					"set_faceup": false}],
				"filter_count_difference": "decreased",
				"filter_count": 1,
				"filter_counter_name": "research",
				"trigger": "another"}}
		# This card should stay face-up since some limits will not match
		cards[7].scripts = {"counter_modified": {
				"hand": [
					{"name": "flip_card",
					"subject": "self",
					"set_faceup": false}],
				"filter_count_difference": "decreased",
				"filter_count": 0,
				"filter_token_name": "Tech",
				"trigger": "another"}}
		# warning-ignore:return_value_discarded
		board.counters.mod_counter("research",-4)
		yield(yield_for(0.1), YIELD)
		assert_signal_emitted_with_parameters(
					board.counters,"counter_modified",
					[null,"counter_modified",
					{"counter_name": "research",
					"previous_count": 5,
					"new_count": 1,
					"tags": ["Manual"]}])
		assert_false(card.is_faceup,
				"Card turned face-down after signal trigger")
		assert_true(cards[2].is_faceup,
				"Card stayed face-up filter_counter_name does not match")
		assert_true(cards[3].is_faceup,
				"Card stayed face-up since filter_count does not match")
		assert_true(cards[4].is_faceup,
				"Card stayed face-up since filter_difference does not match")
		assert_false(cards[5].is_faceup,
				"Card turned face-down since filter_difference matches")
		assert_false(cards[6].is_faceup,
				"Card turned face-down since all limits match")
		assert_true(cards[7].is_faceup,
				"Card stayed face-up since some limits do not match")


class TestCardTargeted:
	extends "res://tests/ScEng_common.gd"

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

class TestCardUnattached:
	extends "res://tests/ScEng_common.gd"

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
					{"host": host,
					"tags": ["Manual"]}])
		assert_false(card.is_faceup,
				"Card turned face-down after signal trigger")
		target.move_to(discard)
		yield(yield_for(1), YIELD)
		assert_signal_emitted_with_parameters(
					target,"card_unattached",
					[target,"card_unattached",
					{"host": host,
					"tags": ["Manual"]}])
		assert_false(cards[3].is_faceup,
				"Card turned face-down after signal trigger")

class TestCardPropertiesModified:
	extends "res://tests/ScEng_common.gd"
	func _init() -> void:
		initial_card_count = 9
		target_index = 1

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
		# warning-ignore:return_value_discarded
		target.modify_property("Type", "Orange")
		cards[4]._debugger_hook = true
		yield(yield_for(0.1), YIELD)
		assert_signal_emitted_with_parameters(
					target,"card_properties_modified",
					[target,"card_properties_modified",
					{"property_name": "Type",
					"new_property_value": "Orange",
					"previous_property_value": "Green",
					"tags": ["Manual"]}])
		assert_false(card.is_faceup,
				"Card turned face-down after signal trigger match")
		assert_true(cards[2].is_faceup,
				"Card stayed face-up after signal trigger not matching")
		assert_false(cards[3].is_faceup,
				"Card turned face-down after all property filters match")
		assert_true(cards[4].is_faceup,
				"Card stayed face-up after after one property filters not matching")

class TestSameSignalDiffTargets:
	extends "res://tests/ScEng_common.gd"

	func test_same_signal_different_trigger():
		card.scripts = {"card_moved_to_board": {
				"board": [
						{
							"name": "mod_tokens",
							"modification": 2,
							"token_name": "void",
							"subject": "self",
							"trigger": "self",
						},
						{
							"name": "mod_tokens",
							"modification": -1,
							"token_name": "void",
							"subject": "self",
							"trigger": "another",
							"is_cost": true
						},
						{
							"name": "mod_tokens",
							"modification": 1,
							"token_name": "industry",
							"subject": "trigger",
							"trigger": "another",
						}]}}
		yield(drag_drop(card, Vector2(300,300)), "completed")
		yield(yield_for(0.2), YIELD)
		var void_token: Token = card.tokens.get_token("void")
		assert_not_null(void_token)
		if void_token:
			assert_eq(void_token.count,2,"Token set to specified amount")
		yield(drag_drop(target, Vector2(800,300)), "completed")
		var industry_token: Token = target.tokens.get_token("industry")
		assert_not_null(industry_token)
		if industry_token:
			assert_eq(industry_token.count,1,"Token set to specified amount")
		if void_token:
			assert_eq(void_token.count,1,"Token set to specified amount")
