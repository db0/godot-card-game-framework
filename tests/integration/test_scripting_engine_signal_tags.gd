extends "res://tests/UTcommon.gd"

class TestCardMovedToSignalTags:
	extends "res://tests/ScEng_common.gd"

	func test_card_moved_to_signal_tags():
		target = cfc.NMAP.deck.get_top_card()
		watch_signals(target)
		card.scripts = {"card_moved_to_hand": {
				"hand": [
					{"name": "flip_card",
					"subject": "self",
					"set_faceup": false}],
				"filter_tags": "Manual",
				"trigger": "another"}}
		cards[2].scripts = {"card_moved_to_hand": {
				"hand": [
					{"name": "flip_card",
					"subject": "self",
					"set_faceup": false}],
				"filter_tags": "Scripted",
				"trigger": "another"}}
		target.move_to(hand)
		yield(yield_to(target._tween, "tween_all_completed", 1), YIELD)
		assert_signal_emitted_with_parameters(
					target,"card_moved_to_hand",
					[target,"card_moved_to_hand",
					{"destination": "Hand", "source": "Deck", "tags": ["Manual"]}])
		assert_false(card.is_faceup,
				"Card turned face-down after signal trigger")
		assert_true(cards[2].is_faceup,
				"Card stayed up after signal trigger did not match tag")
		cards[4].scripts = {
			"manual": {
				"hand": [
						{"name": "move_card_to_container",
						"tags": ["GUT"],
						"subject": "index",
						"subject_index": "top",
						"src_container": "deck",
						"dest_container": "hand"}
				]
			},
			"card_moved_to_hand": {
				"hand": [
					{"name": "flip_card",
					"subject": "self",
					"set_faceup": false}],
				"filter_tags": "Manual",
				"trigger": "another"}}
		target = cfc.NMAP.deck.get_top_card()
		watch_signals(target)
		cards[4].execute_scripts()
		yield(yield_to(target._tween, "tween_all_completed", 1), YIELD)
		assert_signal_emitted_with_parameters(
					target,"card_moved_to_hand",
					[target,"card_moved_to_hand",
					{
						"destination": "Hand",
						"source": "Deck",
						"tags": ["Scripted", "GUT"]}])
		assert_false(cards[2].is_faceup,
				"Card turned face-down after signal trigger")
		assert_true(cards[4].is_faceup,
				"Card stayed up after signal trigger did not match tag")


class TestCardRotatedTags:
	extends "res://tests/ScEng_common.gd"
	func _init() -> void:
		initial_card_count = 6
		target_index = 1

	func test_card_rotated_tags():
		watch_signals(target)
		card.scripts = {"card_rotated": {
				"hand": [
					{"name": "flip_card",
					"subject": "self",
					"set_faceup": false}],
				"filter_tags": "Manual",
				"trigger": "another"}}
		cards[2].scripts = {"card_rotated": {
				"hand": [
					{"name": "flip_card",
					"subject": "self",
					"set_faceup": false}],
				"filter_tags": "Scripted",
				"trigger": "another"}}
		target.scripts = {"manual": {"board": [
				{"name": "rotate_card",
				"subject": "self",
				"tags": ["GUT"],
				"degrees": 180}]}}
		yield(table_move(target, Vector2(500,100)), "completed")
		target.card_rotation = 90
		yield(yield_to(card._tween, "tween_all_completed", 1), YIELD)
		assert_signal_emitted_with_parameters(
					target,"card_rotated",
					[target,"card_rotated",
					{"degrees": 90, "tags": ["Manual"]}])
		assert_false(card.is_faceup,
				"Card turned face-down after signal trigger matches tags")
		assert_true(cards[2].is_faceup,
				"Card stayed face-up since filter_tags didn't match")
		target.execute_scripts()
		yield(yield_to(card._tween, "tween_all_completed", 1), YIELD)
		assert_signal_emitted_with_parameters(
					target,"card_rotated",
					[target,"card_rotated",
					{"degrees": 180, "tags": ["Scripted", "GUT"]}])
		assert_false(cards[2].is_faceup,
				"Card turned face-down after signal trigger matches tags")

class TestCardFlippedTags:
	extends "res://tests/ScEng_common.gd"
	func _init() -> void:
		initial_card_count = 6
		target_index = 1

	func test_card_flipped_tags():
		watch_signals(target)
		watch_signals(cards[4])
		card.scripts = {"card_flipped": {
				"hand": [
					{"name": "flip_card",
					"subject": "self",
					"set_faceup": false}],
				"filter_tags": "Manual",
				"trigger": "another"}}
		cards[2].scripts = {"card_flipped": {
				"hand": [
					{"name": "flip_card",
					"subject": "self",
					"set_faceup": false}],
				"filter_tags": "GUT",
				"trigger": "another"}}
		cards[4].scripts = {"manual": {"hand": [
					{"name": "flip_card",
					"subject": "self",
					"tags": ["GUT"],
					"set_faceup": false}]}}
		target.is_faceup = false
		yield(yield_to(target._flip_tween, "tween_all_completed", 1), YIELD)
		assert_signal_emitted_with_parameters(
					target,"card_flipped",
					[target,"card_flipped",
					{"is_faceup": false, "tags": ["Manual"]}])
		assert_false(card.is_faceup,
				"Card turned face-down after signal trigger matched tags")
		assert_true(cards[2].is_faceup,
				"Card stayed face-up since filter_tags didn't match")
		cards[4].execute_scripts()
		yield(yield_to(cards[4]._flip_tween, "tween_all_completed", 1), YIELD)
		assert_signal_emitted_with_parameters(
					cards[4],"card_flipped",
					[cards[4],"card_flipped",
					{"is_faceup": false, "tags": ["Scripted", "GUT"]}])
		assert_false(cards[2].is_faceup,
				"Card turned face-down after signal trigger matches tags")

class TestCardTokenModifiedTags:
	extends "res://tests/ScEng_common.gd"
	func _init() -> void:
		initial_card_count = 6
		target_index = 1
		
	func test_card_token_modified_tags():
		yield(table_move(target, Vector2(500,100)), "completed")
		yield(table_move(cards[5], Vector2(100,100)), "completed")
		# warning-ignore:return_value_discarded
		watch_signals(target)
		watch_signals(cards[5])
		card.scripts = {"card_token_modified": {
				"hand": [
					{"name": "flip_card",
					"subject": "self",
					"set_faceup": false}],
				"filter_tags": "Manual",
				"trigger": "another"}}
		cards[2].scripts = {"card_token_modified": {
				"hand": [
					{"name": "flip_card",
					"subject": "self",
					"set_faceup": false}],
				"filter_tags": ["GUT"],
				"trigger": "another"}}
		cards[3].scripts = {"card_token_modified": {
				"hand": [
					{"name": "flip_card",
					"subject": "self",
					"set_faceup": false}],
				"filter_tags": ["GUT", "Scripted"],
				"trigger": "another"}}
		cards[4].scripts = {"card_token_modified": {
				"hand": [
					{"name": "flip_card",
					"subject": "self",
					"set_faceup": false}],
				"filter_tags": ["GUT", "Manual"],
				"trigger": "another"}}
		target.tokens.mod_token("void",5)
		yield(yield_for(0.1), YIELD)
		assert_signal_emitted_with_parameters(
					target,"card_token_modified",
					[target,"card_token_modified",
					{"token_name": "void",
					"previous_count": 0,
					"new_count": 5,
					"tags": ["Manual"]}])
		assert_false(card.is_faceup,
				"Card turned face-down since filter_tags matched")
		assert_true(cards[2].is_faceup,
				"Card stayed face-up since filter_tags didn't match")
		assert_true(cards[3].is_faceup,
				"Card stayed face-up since filter_tags didn't match")
		assert_true(cards[4].is_faceup,
				"Card stayed face-up since both filter_tags didn't match")
		cards[5].scripts = {"manual": {"board": [
				{"name": "mod_tokens",
				"subject": "self",
				"modification": 5,
				"tags": ["GUT"],
				"token_name":  "industry"}]}}
		cards[5].execute_scripts()
		yield(yield_for(0.1), YIELD)
		assert_signal_emitted_with_parameters(
					cards[5],"card_token_modified",
					[cards[5],"card_token_modified",
					{"token_name": "industry",
					"previous_count": 0,
					"new_count": 5,
					"tags": ["Scripted", "GUT"]}])
		assert_false(cards[2].is_faceup,
				"Card turned face-down since filter_tags matched")
		assert_false(cards[3].is_faceup,
				"Card turned face-down since both filter_tags matched")
		assert_true(cards[4].is_faceup,
				"Card turned face-down since both filter_tags didn't match")

class TestCounterModifiedTags:
	extends "res://tests/ScEng_common.gd"

	func test_counter_modified_tags():
		# warning-ignore:return_value_discarded
		board.counters.mod_counter("research",5)
		watch_signals(board.counters)
		card.scripts = {"counter_modified": {
				"hand": [
					{"name": "flip_card",
					"subject": "self",
					"set_faceup": false}],
				"filter_tags": "Manual",
				"trigger": "another"}}
		cards[2].scripts = {"counter_modified": {
				"hand": [
					{"name": "flip_card",
					"subject": "self",
					"set_faceup": false}],
				"filter_tags": "GUT",
				"trigger": "another"}}
		cards[3].scripts = {"manual": {"hand": [
				{"name": "mod_counter",
				"tags": ["GUT"],
				"modification": 5,
				"counter_name":  "research"}]}}
		# warning-ignore:return_value_discarded
		board.counters.mod_counter("research",-4)
		yield(yield_for(0.1), YIELD)
		assert_signal_emitted_with_parameters(
					board.counters,"counter_modified",
					[null,"counter_modified",
					{
						"counter_name": "research",
						"previous_count": 5,
						"new_count": 1,
						"tags": ["Manual"]
					}])
		assert_false(card.is_faceup,
				"Card turned face-down after signal trigger")
		assert_true(cards[2].is_faceup,
				"Card stayed face-up filter_tags does not match")
		cards[3].execute_scripts()
		assert_signal_emitted_with_parameters(
					board.counters,"counter_modified",
					[cards[3],"counter_modified",
					{
						"counter_name": "research",
						"previous_count": 1,
						"new_count": 6,
						"tags": ["Scripted", "GUT"]
					}])
		assert_false(card.is_faceup,
				"Card turned face-down after signal trigger")
