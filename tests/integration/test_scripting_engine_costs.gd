extends "res://tests/UTcommon.gd"

class TestSelfandRotate:
	extends "res://tests/ScEng_common.gd"

	func test_self_and_rotate_costs():
		card.scripts = {"manual": {"board": [
				{"name": "rotate_card",
				"subject": "self",
				"is_cost": true,
				"degrees": 90},
				{"name": "flip_card",
				"subject": "self",
				"set_faceup": false}]}}
		cards[1].scripts = {"manual": {"board": [
				{"name": "rotate_card",
				"subject": "self",
				"is_cost": true,
				"degrees": 90},
				{"name": "flip_card",
				"subject": "self",
				"set_faceup": false}]}}
		yield(table_move(card, Vector2(100,200)), "completed")
		card.execute_scripts()
		yield(yield_to(card._flip_tween, "tween_all_completed", 0.5), YIELD)
		assert_false(card.is_faceup,
				"card turn face-down because "
				+ "rotation cost could be paid")
		yield(table_move(cards[1], Vector2(500,200)), "completed")
		cards[1].card_rotation = 90
		cards[1].execute_scripts()
		yield(yield_to(cards[1]._flip_tween, "tween_all_completed", 0.4), YIELD)
		assert_true(cards[1].is_faceup,
				"card should stay face-up because "
				+ "rotation cost could not be paid")

class TestTargetCosts:
	extends "res://tests/ScEng_common.gd"
	
	func test_target_costs():
		card.scripts = {"manual": {"hand": [
				{"name": "rotate_card",
				"subject": "target",
				"is_cost": true,
				"degrees": 90},
				{"name": "flip_card",
				"subject": "self",
				"set_faceup": false}]}}
		cards[1].scripts = {"manual": {"hand": [
				{"name": "rotate_card",
				"subject": "target",
				"is_cost": true,
				"degrees": 90},
				{"name": "flip_card",
				"subject": "self",
				"set_faceup": false}]}}
		yield(table_move(target, Vector2(100,200)), "completed")
		card.execute_scripts()
		yield(target_card(card,target), "completed")
		yield(yield_to(card._flip_tween, "tween_all_completed", 0.5), YIELD)
		assert_false(card.is_faceup,
				"card should turn face-down because "
				+ "target rotation cost could be paid")
		cards[1].execute_scripts()
		yield(target_card(cards[1],target), "completed")
		yield(yield_to(cards[1]._flip_tween, "tween_all_completed", 0.5), YIELD)
		assert_true(cards[1].is_faceup,
				"Target should stay face-up because "
				+ "target rotation cost could not be paid")

class TestMultipleCosts:
	extends "res://tests/ScEng_common.gd"
	
	func test_multiple_costs():
		card.scripts = {"manual": {"hand": [
				{"name": "rotate_card",
				"subject": "target",
				"is_cost": true,
				"degrees": 90},
				{"name": "flip_card",
				"subject": "previous",
				"is_cost": true,
				"set_faceup": false},
				{"name": "flip_card",
				"subject": "self",
				"is_cost": true,
				"set_faceup": false}]}}
		yield(table_move(target, Vector2(100,200)), "completed")
		target.is_faceup = false
		yield(yield_to(card._flip_tween, "tween_all_completed", 0.5), YIELD)
		card.execute_scripts()
		yield(target_card(card,target), "completed")
		yield(yield_to(card._flip_tween, "tween_all_completed", 0.5), YIELD)
		assert_true(card.is_faceup,
				"card should stay face-up because "
				+ "some costs could not be paid")
		assert_eq(0,target.card_rotation,
				"target should not be rotated from a cost test")

class TestFlipCost:
	extends "res://tests/ScEng_common.gd"

	func test_flip_cost():
		card.scripts = {"manual": {"board": [
				{"name": "flip_card",
				"subject": "self",
				"is_cost": true,
				"set_faceup": false},
				{"name": "rotate_card",
				"subject": "self",
				"degrees": 90},]}}
		yield(table_move(card, Vector2(100,200)), "completed")
		card.is_faceup = false
		card.execute_scripts()
		yield(yield_to(card._tween, "tween_all_completed", 0.5), YIELD)
		assert_eq(0,target.card_rotation,
				"Card not rotated because flip cost could be paid")

class TestTokenCost:
	extends "res://tests/ScEng_common.gd"

	func test_token_cost():
		card.scripts = {"manual": {"board": [
				{"name": "mod_tokens",
				"subject": "self",
				"is_cost": true,
				"token_name":  "bio",
				"modification": 3},
				{"name": "rotate_card",
				"subject": "self",
				"degrees": 90}]}}
		yield(table_move(card, Vector2(1000,200)), "completed")
		card.execute_scripts()
		yield(yield_to(card._tween, "tween_all_completed", 0.5), YIELD)
		assert_eq(90,card.card_rotation,
				"Card rotated because positive token cost can always be paid")
		card.scripts = {"manual": {"board": [
				{"name": "mod_tokens",
				"subject": "self",
				"is_cost": true,
				"token_name":  "bio",
				"modification": -2},
				{"name": "rotate_card",
				"subject": "self",
				"degrees": 180}]}}
		card.execute_scripts()
		yield(yield_to(card._tween, "tween_all_completed", 0.5), YIELD)
		assert_eq(180,card.card_rotation,
				"Card rotated because negative token cost could be be paid")
		card.scripts = {"manual": {"board": [
				{"name": "mod_tokens",
				"subject": "self",
				"is_cost": true,
				"token_name":  "bio",
				"modification": -2},
				{"name": "rotate_card",
				"subject": "self",
				"degrees": 0}]}}
		card.execute_scripts()
		yield(yield_to(card._tween, "tween_all_completed", 0.5), YIELD)
		assert_eq(180,card.card_rotation,
				"Card not rotated because negative token cost could not  be be paid")
		assert_eq(1,card.tokens.get_token("bio").count,
				"Token count that could not be paid remains the same")

class TestModifyProperties:
	extends "res://tests/ScEng_common.gd"

	func test_modify_properties_cost():
		card.scripts = {"manual": {"hand": [
				{"name": "modify_properties",
				"subject": "self",
				"is_cost": true,
				"set_properties": {"Type": card.properties["Type"]}},
				{"name": "flip_card",
				"subject": "self",
				"set_faceup": false}]}}
		card.execute_scripts()
		yield(yield_to(card._flip_tween, "tween_all_completed", 0.4), YIELD)
		assert_true(card.is_faceup,
				"card should stay face-up because "
				+ "property change cost could not be paid")
		card.scripts = {"manual": {"hand": [
				{"name": "modify_properties",
				"subject": "self",
				"is_cost": true,
				"set_properties": {"Type": "Orange"}},
				{"name": "flip_card",
				"subject": "self",
				"set_faceup": false}]}}
		card.execute_scripts()
		yield(yield_to(card._flip_tween, "tween_all_completed", 0.4), YIELD)
		assert_false(card.is_faceup,
				"card should turn face-down because "
				+ "property change cost could be paid")
		target.scripts = {"manual": {"hand": [
				{"name": "modify_properties",
				"subject": "self",
				"is_cost": true,
				"set_properties": {"Cost": "-100"}},
				{"name": "flip_card",
				"subject": "self",
				"set_faceup": false}]}}
		target.execute_scripts()
		yield(yield_to(target._flip_tween, "tween_all_completed", 0.4), YIELD)
		assert_true(target.is_faceup,
				"card stayed face-up because "
				+ "property reduction could not be paid")

class TestMoveCardContToCont:
	extends "res://tests/ScEng_common.gd"

	func test_move_card_cont_to_cont_cost():
		card.scripts = {"manual": {"hand": [
				{"name": "move_card_to_container",
				"is_cost": true,
				"subject": "index",
				"subject_index": "top",
				"subject_count": 7,
				"src_container": "deck",
				"dest_container": "discard"},
				{"name": "flip_card",
				"subject": "self",
				"set_faceup": false}]}}
		card.execute_scripts()
		yield(yield_to(card._flip_tween, "tween_all_completed", 0.4), YIELD)
		yield(yield_to(card._flip_tween, "tween_all_completed", 0.4), YIELD)
		assert_false(card.is_faceup,
				"card should turn face-down because "
				+ "property change cost could be paid")
		target.scripts = {"manual": {"hand": [
				{"name": "move_card_to_container",
				"is_cost": true,
				"subject": "index",
				"subject_index": "top",
				"subject_count": 7,
				"src_container": "deck",
				"dest_container": "discard"},
				{"name": "flip_card",
				"subject": "self",
				"set_faceup": false}]}}
		target.execute_scripts()
		yield(yield_to(target._flip_tween, "tween_all_completed", 0.4), YIELD)
		yield(yield_to(target._flip_tween, "tween_all_completed", 0.4), YIELD)
		assert_true(target.is_faceup,
				"card should stay face-up because "
				+ "property change cost could not be paid")

class TestMoveCardContToBoard:
	extends "res://tests/ScEng_common.gd"

	func test_move_card_cont_to_board_cost():
		card.scripts = {"manual": {"hand": [
				{"name": "move_card_to_board",
				"is_cost": true,
				"subject": "index",
				"subject_index": "top",
				"subject_count": 7,
				"src_container": "deck",
				"board_position":  Vector2(100,100)},
				{"name": "flip_card",
				"subject": "self",
				"set_faceup": false}]}}
		card.execute_scripts()
		yield(yield_to(card._flip_tween, "tween_all_completed", 0.4), YIELD)
		yield(yield_to(card._flip_tween, "tween_all_completed", 0.4), YIELD)
		assert_false(card.is_faceup,
				"card should turn face-down because "
				+ "enough cards could be moved from the deck")
		target.scripts = {"manual": {"hand": [
				{"name": "move_card_to_board",
				"is_cost": true,
				"subject": "index",
				"subject_index": "top",
				"subject_count": 7,
				"src_container": "deck",
				"board_position":  Vector2(100,100)},
				{"name": "flip_card",
				"subject": "self",
				"set_faceup": false}]}}
		target.execute_scripts()
		yield(yield_to(target._flip_tween, "tween_all_completed", 0.4), YIELD)
		yield(yield_to(target._flip_tween, "tween_all_completed", 0.4), YIELD)
		assert_true(target.is_faceup,
				"card should stay face-up because "
				+ "not enough cards could be found in the deck")

class TestMoveCardToGrid:
	extends "res://tests/ScEng_common.gd"

	func test_move_card_to_grid_cost():
		card.scripts = {"manual": {"hand": [
				{"name": "move_card_to_board",
				"is_cost": true,
				"subject": "index",
				"subject_index": "top",
				"subject_count": 3,
				"src_container": "deck",
				"grid_name":  "BoardPlacementGrid"},
				{"name": "flip_card",
				"subject": "self",
				"set_faceup": false}]}}
		card.execute_scripts()
		yield(yield_to(card._flip_tween, "tween_all_completed", 0.4), YIELD)
		yield(yield_to(card._flip_tween, "tween_all_completed", 0.4), YIELD)
		assert_false(card.is_faceup,
				"card should turn face-down because "
				+ "grid had enough slots for all cards")
		target._debugger_hook = true
		target.scripts = {"manual": {"hand": [
				{"name": "move_card_to_board",
				"is_cost": true,
				"subject": "index",
				"subject_index": "top",
				"subject_count": 3,
				"src_container": "deck",
				"grid_name":  "BoardPlacementGrid"},
				{"name": "flip_card",
				"subject": "self",
				"set_faceup": false}]}}
		target.execute_scripts()
		yield(yield_to(target._flip_tween, "tween_all_completed", 0.4), YIELD)
		yield(yield_to(target._flip_tween, "tween_all_completed", 0.4), YIELD)
		assert_true(target.is_faceup,
				"card should stay face-up because "
				+ "grid did not have enough slots for all cards")
		var grid = board.get_grid("BoardPlacementGrid")
		grid.auto_extend = true
		target.execute_scripts()
		yield(yield_to(target._flip_tween, "tween_all_completed", 0.4), YIELD)
		yield(yield_to(target._flip_tween, "tween_all_completed", 0.4), YIELD)
		assert_false(target.is_faceup,
				"card should turn face-down because "
				+ "grid auto-extended to host all cards")

class TestCountersCost:
	extends "res://tests/ScEng_common.gd"

	func test_counters_cost():
		card.scripts = {"manual": {"board": [
				{"name": "mod_counter",
				"is_cost": true,
				"counter_name":  "research",
				"modification": 3},
				{"name": "rotate_card",
				"subject": "self",
				"degrees": 90}]}}
		yield(table_move(card, Vector2(200,200)), "completed")
		card.execute_scripts()
		yield(yield_to(card._tween, "tween_all_completed", 0.5), YIELD)
		assert_eq(90,card.card_rotation,
				"Card rotated because positive counter cost can always be paid")
		card.scripts = {"manual": {"board": [
				{"name": "mod_counter",
				"is_cost": true,
				"counter_name":  "research",
				"modification": -2},
				{"name": "rotate_card",
				"subject": "self",
				"degrees": 180}]}}
		card.execute_scripts()
		yield(yield_to(card._tween, "tween_all_completed", 0.5), YIELD)
		assert_eq(180,card.card_rotation,
				"Card rotated because negative counter cost could be be paid")
		card.scripts = {"manual": {"board": [
				{"name": "mod_counter",
				"is_cost": true,
				"counter_name":  "research",
				"modification": -2},
				{"name": "rotate_card",
				"subject": "self",
				"degrees": 0}]}}
		card.execute_scripts()
		yield(yield_to(card._tween, "tween_all_completed", 0.5), YIELD)
		assert_eq(180,card.card_rotation,
				"Card not rotated because negative counter cost could not be be paid")
		assert_eq(1,board.counters.get_counter("research"),
				"Token count that could not be paid remains the same")
