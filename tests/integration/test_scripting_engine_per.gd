extends "res://tests/UTcommon.gd"

class TestPerToken:
	extends "res://tests/ScEng_common.gd"

	func test_per_token_and_modify_token_per():
		yield(table_move(card, Vector2(100,200)), "completed")
	# warning-ignore:return_value_discarded
		card.tokens.mod_token("void",5)
		yield(yield_for(0.1), YIELD)
		card.scripts = {"manual": {
			"board": [
				{"name": "mod_tokens",
				"subject": "self",
				"token_name":  "bio",
				"modification": "per_token",
				"per_token": {
					"subject": "self",
					"token_name": "void"}
				},
			]}
		}
		card.execute_scripts()
		var bio_token = card.tokens.get_token("bio")
		assert_not_null(bio_token,
			"Put 1 Bio token per void token on this card")
		if bio_token:
			assert_eq(bio_token.count, 5)
		card.scripts = {"manual": {
			"board": [
				{"name": "move_card_to_container",
				"subject": "index",
				"subject_count": "per_token",
				"src_container": "deck",
				"dest_container": "hand",
				"subject_index": "top",
				"per_token": {
					"subject": "self",
					"token_name": "void"}
				},
			]}
		}
		card.execute_scripts()
		yield(yield_for(0.5), YIELD)
		assert_eq(hand.get_card_count(), 9,
				"Draw 1 card per void token on this card")

class TestPerProperty:
	extends "res://tests/ScEng_common.gd"

	func test_per_property():
	# warning-ignore:return_value_discarded
		card.modify_property("Cost", 3)
		card.scripts = {"manual": {
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
		yield(yield_for(0.5), YIELD)
		assert_eq(hand.get_card_count(), 8,
			"Draw 1 card per cost of this card.")

class TestTutor:
	extends "res://tests/ScEng_common.gd"

	func test_per_tutor_and_spawn_card_per():
		target.scripts = {"manual": {"hand": [
				{"name": "spawn_card",
				"card_name": "Spawn Card",
				"object_count": "per_tutor",
				"board_position":  Vector2(100,200),
				"per_tutor": {
					"subject": "tutor",
					"subject_count": "all",
					"src_container": "deck",
					"filter_state_tutor": [{"filter_properties": {"Type": "Blue"}}]
				}}]}}
		target.execute_scripts()
		yield(yield_for(0.3), YIELD)
		assert_eq(5,board.get_card_count(),
			"Spawn 1 card per Blue card in the deck")

class TestPerBoardseek:
	extends "res://tests/ScEng_common.gd"

	func test_per_boardseek():
		yield(table_move(cards[1], Vector2(100,200)), "completed")
		yield(table_move(cards[2], Vector2(300,200)), "completed")
		yield(table_move(cards[3], Vector2(500,200)), "completed")
		yield(table_move(cards[4], Vector2(700,200)), "completed")
		card.scripts = {"manual": {"hand": [
				{"name": "move_card_to_container",
				"subject": "index",
				"subject_count": "per_boardseek",
				"src_container": "deck",
				"dest_container": "hand",
				"subject_index": "top",
				"per_boardseek": {
					"subject": "boardseek",
					"subject_count": "all",
					"filter_state_seek": [{"filter_properties": {"Power": 0}}]
				}}]}}
		card.execute_scripts()
		yield(yield_for(0.3), YIELD)
		assert_eq(hand.get_card_count(), 3,
				"Draw 1 card per 0-cost card on board")

class TestPerCounter:
	extends "res://tests/ScEng_common.gd"

	func test_per_counter():
	# warning-ignore:return_value_discarded
		board.counters.mod_counter("research", 3)
		card.scripts = {"manual": {
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
		yield(yield_for(0.5), YIELD)
		assert_eq(hand.get_card_count(), 8,
			"Draw 1 card per counter specified")

class TestFilterPerBoardseek:
	extends "res://tests/ScEng_common.gd"

	func test_filter_per_boardseek():
		yield(table_move(cards[1], Vector2(100,200)), "completed")
		yield(table_move(cards[2], Vector2(300,200)), "completed")
		yield(table_move(cards[3], Vector2(500,200)), "completed")
		yield(table_move(cards[4], Vector2(700,200)), "completed")
		# Flip the card facedown if there's 3 cards on board
		card.scripts = {"manual": {
				"hand": [
					{"name": "flip_card",
					"subject": "self",
					"set_faceup": false}],
				"filter_per_boardseek_count": {
					"subject": "boardseek",
					"subject_count": "all",
					"filter_card_count": 3,}}}
		card.execute_scripts()
		yield(yield_for(0.3), YIELD)
		assert_true(card.is_faceup,
				"Card stayed face-up since filter_per_boardseek didn't match")
		# Flip the card facedown if there's 4 cards on board
		card.scripts = {"manual": {
				"hand": [
					{"name": "flip_card",
					"subject": "self",
					"set_faceup": false}],
				"filter_per_boardseek_count": {
					"subject": "boardseek",
					"subject_count": "all",
					"filter_card_count": 4,}}}
		card.execute_scripts()
		yield(yield_for(0.3), YIELD)
		assert_false(card.is_faceup,
				"Card flipped face-down since filter_per_boardseek matched")

class TestFilterPerTutor:
	extends "res://tests/ScEng_common.gd"

	func test_filter_per_tutor():
		# Flip the card facedown if there's less than 5 cards in deck
		card.scripts = {"manual": {
				"hand": [
					{"name": "flip_card",
					"subject": "self",
					"set_faceup": false}],
				"filter_per_tutor_count": {
					"subject": "tutor",
					"subject_count": "all",
					"comparison": "lt",
					"src_container": "deck",
					"filter_card_count": 5,}}}
		card.execute_scripts()
		yield(yield_for(0.3), YIELD)
		assert_true(card.is_faceup,
				"Card stayed face-up since filter_per_tutor didn't match")
		# Flip the card facedown if there's more than 5 cards in deck
		card.scripts = {"manual": {
				"hand": [
					{"name": "flip_card",
					"subject": "self",
					"set_faceup": false}],
				"filter_per_tutor_count": {
					"subject": "tutor",
					"subject_count": "all",
					"comparison": "gt",
					"src_container": "deck",
					"filter_card_count": 5,}}}
		card.execute_scripts()
		yield(yield_for(0.3), YIELD)
		assert_false(card.is_faceup,
				"Card flipped face-down since filter_per_tutor matched")

	func test_filter_per_tutor_in_hand():
		# Flip the card facedown if there's 1 blue cards in hand
		card.scripts = {"manual": {
				"hand": [
					{"name": "flip_card",
					"subject": "self",
					"set_faceup": false}],
				"filter_per_tutor_count": {
					"subject": "tutor",
					"subject_count": "all",
					"src_container": "hand",
					"filter_state_tutor": [{"filter_properties": {"Type": "Blue"}}],
					"filter_card_count": 1,}}}
		card.execute_scripts()
		yield(yield_for(0.3), YIELD)
		assert_true(card.is_faceup,
				"Card stayed face-up since filter_per_tutor didn't match")
		# Flip the card facedown if there's 3 or more blue cards in hand
		card.scripts = {"manual": {
				"hand": [
					{"name": "flip_card",
					"subject": "self",
					"set_faceup": false}],
				"filter_per_tutor_count": {
					"subject": "tutor",
					"subject_count": "all",
					"src_container": "hand",
					"comparison": "ge",
					"filter_state_tutor": [{"filter_properties": {"Type": "Blue"}}],
					"filter_card_count": 2,}}}
		card.execute_scripts()
		yield(yield_for(0.3), YIELD)
		assert_false(card.is_faceup,
				"Card flipped face-down since filter_per_tutor matched")

class TestPerPrevious:
	extends "res://tests/ScEng_common.gd"

	func test_per_previous():
		target.properties['Cost'] = 5
		card.scripts = {"manual": {
			"hand": [
				{
					"name": "move_card_to_container",
					"dest_container": "discard",
					"subject": "target",
					"filter_state_subject": [{"filter_parent": "hand"}],
					"is_cost": true
				},
				{
					"name": "mod_counter",
					"counter_name": "research",
					"modification": "per_property",
					"subject": "previous",
					"per_property": {
						"subject": "previous",
						"property_name": "Cost"}
				},
			]}
		}
		yield(execute_with_target(card,target), "completed")
		assert_eq(5,board.counters.get_counter("research"),
				"Counter set to the specified amount")

class TestPerInverted:
	extends "res://tests/ScEng_common.gd"

	func test_per_inverted():
		# warning-ignore:return_value_discarded
		board.counters.mod_counter("research", 3)
		# warning-ignore:return_value_discarded
		board.counters.mod_counter("credits", 10, true)
		card.scripts = {"manual": {
			"hand": [
				{"name": "mod_counter",
				"counter_name": "credits",
				"modification": "per_counter",
				"per_counter": {
					"is_inverted": true,
					"counter_name": "research"}
				},
			]}
		}
		card.execute_scripts()
		yield(yield_for(0.1), YIELD)
		assert_eq(board.counters.get_counter("credits"),7,
				"Counter set to the specified amount")
	#

class TestFilterPerUnique:
	extends "res://tests/ScEng_common.gd"

	func test_filter_per_count_unique():
		# Put one bio counter per unique card in deck
		yield(table_move(card, Vector2(100,200)), "completed")
		card.scripts = {"manual": {
			"board": [
				{
					"name": "mod_tokens",
					"subject": "self",
					"token_name":  "bio",
					"modification": "per_tutor",
					"per_tutor": {
						"subject": "tutor",
						"subject_count": "all",
						"src_container": "deck",
						"count_unique": true}
				},
			]
		}}
		card.execute_scripts()
		var bio_token = card.tokens.get_token("bio")
		assert_not_null(bio_token,
			"Put 1 Bio token per unique card in deck")
		if bio_token:
			assert_eq(bio_token.count, 5)

class TestModifyPropertiesPer:
	extends "res://tests/ScEng_common.gd"

	func test_modify_properties_per():
		# warning-ignore:return_value_discarded
		board.counters.mod_counter("research", 3)
		# warning-ignore:return_value_discarded
		card.modify_property("Power", 0)
		# warning-ignore:return_value_discarded
		card.modify_property("Cost", 2)
		card.scripts = {"manual": {
			"hand": [
				{"name": "modify_properties",
				"set_properties": {
					"Power": "per_counter",
					"Cost": "+per_counter",
				},
				"subject": "self",
				"per_counter": {
					"counter_name": "research"}
				},
			]}
		}
		card.execute_scripts()
		yield(yield_for(0.5), YIELD)
		assert_eq(card.get_property("Power"), 3,
			"Power set equal to research")
		assert_eq(card.get_property("Cost"), 5,
			"Cost increased by the amount of research")


class TestOriginalPrevious:
	extends "res://tests/ScEng_common.gd"

	func test_original_previous():
		yield(table_move(card, Vector2(100,200)), "completed")
		yield(table_move(target, Vector2(300,200)), "completed")
		yield(yield_for(0.1), YIELD)
		card.scripts = {"manual": {
			"board": [
				{
					"name": "mod_tokens",
					"subject": "target",
					"token_name":  "bio",
					"modification": 5,
				},
				{
					"name": "mod_tokens",
					"subject": "self",
					"token_name":  "blood",
					"modification": "per_token",
					"per_token": {
						"subject": "previous",
						"token_name": "bio",
						"original_previous": true}
					},
			]}
		}
		yield(execute_with_target(card,target), "completed")
	# warning-ignore:unused_variable
		var bio_token_card = card.tokens.get_token("bio")
		var bio_token_target = target.tokens.get_token("bio")
		var blood_token_card = card.tokens.get_token("blood")
	# warning-ignore:unused_variable
		var blood_token_target = target.tokens.get_token("blood")
		assert_not_null(bio_token_target,
			"Put 5 Bio tokens on target")
		assert_not_null(blood_token_card,
			"Put 5 Blood tokens on card")
		if bio_token_target:
			assert_eq(bio_token_target.count, 5)
		if blood_token_card:
			assert_eq(blood_token_card.count, 5)
