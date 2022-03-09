extends "res://tests/UTcommon.gd"

class TestStoreIntegetInverted:
	extends "res://tests/ScEng_common.gd"

	func test_store_integer_inverted():
	# warning-ignore:return_value_discarded
		board.counters.mod_counter("research", 3)
		card.scripts = {"manual": {
				"hand": [
					{
						"name": "mod_counter",
						"modification": 0,
						"set_to_mod": true,
						"counter_name":  "research",
						"store_integer": true
						# Should store a diffference of -3
					},
					{
						"name": "move_card_to_container",
						"src_container": "deck",
						"dest_container": "discard",
						"subject": "index",
						"subject_count": "retrieve_integer",
						"is_inverted": true,
						"subject_index": "top"
					}]}}
		card.execute_scripts()
		yield(yield_for(0.5), YIELD)
		assert_eq(discard.get_card_count(),3, "3 cards should have been discarded")

class TestStoreIntegerWithCounters:
	extends "res://tests/ScEng_common.gd"

	func test_store_integer_with_counters():
	# warning-ignore:return_value_discarded
		board.counters.mod_counter("research", 3)
	# warning-ignore:return_value_discarded
		board.counters.mod_counter("credits", 5, true)
		card.scripts = {"manual": {
				"hand": [
					{
						"name": "mod_counter",
						"modification": 5,
						"set_to_mod": true,
						"counter_name":  "research",
						"store_integer": true
						# Should store a difference of +2
					},
					{
						"name": "mod_counter",
						"counter_name": "credits",
						"modification": "retrieve_integer",
					}]}}
		card.execute_scripts()
		yield(yield_for(0.5), YIELD)
		assert_eq(board.counters.get_counter("credits"),7,
			"2 Credits added")

	func test_store_integer_with_tokens():
		yield(table_move(cards[1], Vector2(800,200)), "completed")
		yield(table_move(cards[2], Vector2(100,200)), "completed")
		cards[1].tokens.mod_token("void",7)
		cards[2].tokens.mod_token("void",1)
		# Set all cards on the board to 2 void tokens.
		# Mill a card for each extra token that exists on the board
		# at the end of this operation.
		card.scripts = {"manual": {"hand": [
				{
					"name": "mod_tokens",
					"subject": "boardseek",
					"subject_count": "all",
					"token_name": "void",
					"store_integer": true,
					"modification": 5,
					"set_to_mod": true},
					# The cumulative difference of tokens at the end
					# is going to be +2 (5-1 + 5-7)
				{
					"name": "move_card_to_container",
					"src_container": "deck",
					"dest_container": "discard",
					"subject": "index",
					"subject_count": "retrieve_integer",
					"subject_index": "top"
				}]}}
		card.execute_scripts()
		yield(yield_for(0.5), YIELD)
		assert_eq(discard.get_card_count(),2, "2 cards should have been discarded")

class TestRetrieveIntegerTempModProperties:
	extends "res://tests/ScEng_common.gd"

	func test_retrieve_integer_temp_mod_properties():
	# warning-ignore:return_value_discarded
		board.counters.mod_counter("research", 2)
	# warning-ignore:return_value_discarded
		target.modify_property("Cost", 1)
		card.scripts = {"manual": {"hand": [
				{
					"name": "mod_counter",
					"modification": 0,
					"set_to_mod": true,
					"counter_name":  "research",
					"store_integer": true
					# Should store a diffference of -2
				},
				{
					"name": "execute_scripts",
					"subject": "target",
					"exec_trigger":  "manual",
					"temp_mod_properties": {"Cost": "retrieve_integer"},
					"is_inverted": true,
					"require_exec_state": "hand"
				}]}}
		target.scripts = {"manual": {
			"hand": [
				{"name": "move_card_to_container",
				"subject": "index",
				"subject_count": "per_property",
				"src_container": "deck",
				"dest_container": "hand",
				"subject_index": "top",
				"per_property": {
					"subject": "self",
					"property_name": "Cost"}
				},
			]}
		}
		card.execute_scripts()
		yield(target_card(card,target, "slow"), "completed")
		yield(yield_for(0.5), YIELD)
		assert_eq(hand.get_card_count(), 8,
			"Draw the temp modified amount of cards")

class TestRetrieveIntegerTempModCounter:
	extends "res://tests/ScEng_common.gd"

	func test_retrieve_integer_temp_mod_counter():
	# warning-ignore:return_value_discarded
		board.counters.mod_counter("research", 5)
	# warning-ignore:return_value_discarded
		board.counters.mod_counter("credits", 2, true)
		card.scripts = {"manual": {"hand": [
				{
					"name": "mod_counter",
					"modification": -4,
					"counter_name":  "credits",
					"store_integer": true
					# Should store a diffference of -2
				},
				{"name": "execute_scripts",
				"subject": "target",
				"exec_trigger":  "manual",
				"temp_mod_counters": {"research": "retrieve_integer"},
				"require_exec_state": "hand"}]}}
		target.scripts = {"manual": {
			"hand": [
				{"name": "move_card_to_container",
				"subject": "index",
				"subject_count": "per_counter",
				"src_container": "deck",
				"dest_container": "hand",
				"subject_index": "top",
				"per_counter": {
					"counter_name": "research"}
				},
			]}
		}
		card.execute_scripts()
		yield(target_card(card,target, "slow"), "completed")
		yield(yield_for(0.5), YIELD)
		assert_eq(hand.get_card_count(), 8,
			"Draw the temp modified amount of cards")

class TestAdjustRetrievedInteger:
	extends "res://tests/ScEng_common.gd"

	func test_adjust_retrieved_integer():
	# warning-ignore:return_value_discarded
		board.counters.mod_counter("research", 3)
	# warning-ignore:return_value_discarded
		board.counters.mod_counter("credits", 5, true)
		card.scripts = {"manual": {
				"hand": [
					{
						"name": "mod_counter",
						"modification": 5,
						"set_to_mod": true,
						"counter_name":  "research",
						"store_integer": true
						# Should store a difference of +2
					},
					{
						"name": "mod_counter",
						"counter_name": "credits",
						"modification": "retrieve_integer",
						"adjust_retrieved_integer": 2,
					}]}}
		card.execute_scripts()
		yield(yield_for(0.5), YIELD)
		assert_eq(board.counters.get_counter("credits"),9,
			"4 Credits added")

	func test_adjust_retrieved_integer_inverted():
	# warning-ignore:return_value_discarded
		board.counters.mod_counter("research", 3)
	# warning-ignore:return_value_discarded
		board.counters.mod_counter("credits", 5, true)
		card.scripts = {"manual": {
				"hand": [
					{
						"name": "mod_counter",
						"modification": 7,
						"set_to_mod": true,
						"counter_name":  "research",
						"store_integer": true
						# Should store a difference of +4
					},
					{
						"name": "mod_counter",
						"counter_name": "credits",
						"modification": "retrieve_integer",
						"adjust_retrieved_integer": 2,
						"is_inverted": true
					}]}}
		card.execute_scripts()
		yield(yield_for(0.5), YIELD)
		assert_eq(board.counters.get_counter("credits"),3,
			"2 Credits Removed")

