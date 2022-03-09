extends "res://tests/UTcommon.gd"

class Test:
	extends "res://tests/ScEng_common.gd"

class TestFilterGtGeLtLe:
	extends "res://tests/ScEng_common.gd"

	func test_property_filter_gt_ge_lt_le():
		yield(table_move(cards[1], Vector2(200,200)), "completed")
		yield(table_move(cards[2], Vector2(500,200)), "completed")
		yield(table_move(cards[3], Vector2(700,200)), "completed")
		cards[1].modify_property("Cost", 1)
		cards[2].modify_property("Cost", 2)
		cards[3].modify_property("Cost", 3)
		card.scripts = {"manual": {"hand": [
				{"name": "rotate_card",
				"subject": "boardseek",
				"subject_count": "all",
				"filter_state_seek": [{
					"filter_properties2": {"Cost": 2, "comparison": "gt"}
				}],
				"degrees": 90}]}}
		card.execute_scripts()
		yield(yield_to(cards[3]._tween, "tween_all_completed", 0.2), YIELD)
		assert_eq(cards[1].card_rotation, 0,
				"Card not matching comparison not rotated")
		assert_eq(cards[2].card_rotation, 0,
				"Card matching comparison rotated")
		assert_eq(cards[3].card_rotation, 90,
				"Card matching comparison rotated")
		card.scripts = {"manual": {"hand": [
				{"name": "rotate_card",
				"subject": "boardseek",
				"subject_count": "all",
				"filter_state_seek": [{
					"filter_properties2": {"Cost": 2, "comparison": "ge"}
				}],
				"degrees": 180}]}}
		card.execute_scripts()
		yield(yield_to(cards[3]._tween, "tween_all_completed", 0.2), YIELD)
		assert_eq(cards[1].card_rotation, 0,
				"Card not matching comparison not rotated")
		assert_eq(cards[2].card_rotation, 180,
				"Card matching comparison rotated")
		assert_eq(cards[3].card_rotation, 180,
				"Card matching comparison rotated")
		card.scripts = {"manual": {"hand": [
				{"name": "rotate_card",
				"subject": "boardseek",
				"subject_count": "all",
				"filter_state_seek": [{
					"filter_properties2": {"Cost": 2, "comparison": "lt"}
				}],
				"degrees": 270}]}}
		card.execute_scripts()
		yield(yield_to(cards[1]._tween, "tween_all_completed", 0.2), YIELD)
		assert_eq(cards[1].card_rotation, 270,
				"Card matching comparison rotated")
		assert_eq(cards[2].card_rotation, 180,
				"Card not matching comparison not rotated")
		assert_eq(cards[3].card_rotation, 180,
				"Card not matching comparison not rotated")
		card.scripts = {"manual": {"hand": [
				{"name": "rotate_card",
				"subject": "boardseek",
				"subject_count": "all",
				"filter_state_seek": [{
					"filter_properties2": {"Cost": 2, "comparison": "le"}
				}],
				"degrees": 0}]}}
		card.execute_scripts()
		yield(yield_to(cards[1]._tween, "tween_all_completed", 0.2), YIELD)
		assert_eq(cards[1].card_rotation, 0,
				"Card matching comparison rotated")
		assert_eq(cards[2].card_rotation, 0,
				"Card not matching comparison not rotated")
		assert_eq(cards[3].card_rotation, 180,
				"Card not matching comparison not rotated")

class TestTokensFilterGtGeLtLe:
	extends "res://tests/ScEng_common.gd"

	func test_tokens_filter_gt_ge_lt_le():
		yield(table_move(cards[1], Vector2(200,200)), "completed")
		yield(table_move(cards[2], Vector2(500,200)), "completed")
		yield(table_move(cards[3], Vector2(700,200)), "completed")
		yield(table_move(cards[4], Vector2(900,200)), "completed")
		cards[2].tokens.mod_token("void",1)
		cards[3].tokens.mod_token("void",2)
		cards[4].tokens.mod_token("void",3)
		card.scripts = {"manual": {"hand": [
				{"name": "rotate_card",
				"subject": "boardseek",
				"subject_count": "all",
				"filter_state_seek": [{
					"filter_tokens": [{
						"filter_token_name": "void",
						"filter_count": 2,
						"comparison": "gt"
						}]
				}],
				"degrees": 90}]}}
		card.execute_scripts()
		yield(yield_to(cards[3]._tween, "tween_all_completed", 0.2), YIELD)
		assert_eq(cards[1].card_rotation, 0,
				"Card not matching comparison not rotated")
		assert_eq(cards[2].card_rotation, 0,
				"Card not matching comparison not rotated")
		assert_eq(cards[3].card_rotation, 0,
				"Card matching comparison rotated")
		assert_eq(cards[4].card_rotation, 90,
				"Card matching comparison rotated")
		card.scripts = {"manual": {"hand": [
				{"name": "rotate_card",
				"subject": "boardseek",
				"subject_count": "all",
				"filter_state_seek": [{
					"filter_tokens": [{
						"filter_token_name": "void",
						"filter_count": 2,
						"comparison": "ge"
						}]
				}],
				"degrees": 180}]}}
		card.execute_scripts()
		yield(yield_to(cards[3]._tween, "tween_all_completed", 0.2), YIELD)
		assert_eq(cards[1].card_rotation, 0,
				"Card not matching comparison not rotated")
		assert_eq(cards[2].card_rotation, 0,
				"Card not matching comparison not rotated")
		assert_eq(cards[3].card_rotation, 180,
				"Card matching comparison rotated")
		assert_eq(cards[4].card_rotation, 180,
				"Card matching comparison rotated")
		card.scripts = {"manual": {"hand": [
				{"name": "rotate_card",
				"subject": "boardseek",
				"subject_count": "all",
				"filter_state_seek": [{
					"filter_tokens": [{
						"filter_token_name": "void",
						"filter_count": 2,
						"comparison": "lt"
						}]
				}],
				"degrees": 270}]}}
		card.execute_scripts()
		yield(yield_to(cards[1]._tween, "tween_all_completed", 0.2), YIELD)
		assert_eq(cards[1].card_rotation, 270,
				"Card matching comparison rotated")
		assert_eq(cards[2].card_rotation, 270,
				"Card matching comparison rotated")
		assert_eq(cards[3].card_rotation, 180,
				"Card not matching comparison not rotated")
		assert_eq(cards[4].card_rotation, 180,
				"Card not matching comparison not rotated")
		card.scripts = {"manual": {"hand": [
				{"name": "rotate_card",
				"subject": "boardseek",
				"subject_count": "all",
				"filter_state_seek": [{
					"filter_tokens": [{
						"filter_token_name": "void",
						"filter_count": 2,
						"comparison": "le"
						}]
				}],
				"degrees": 0}]}}
		card.execute_scripts()
		yield(yield_to(cards[1]._tween, "tween_all_completed", 0.2), YIELD)
		assert_eq(cards[1].card_rotation, 0,
				"Card matching comparison rotated")
		assert_eq(cards[2].card_rotation, 0,
				"Card matching comparison rotated")
		assert_eq(cards[3].card_rotation, 0,
				"Card not matching comparison not rotated")
		assert_eq(cards[4].card_rotation, 180,
				"Card not matching comparison not rotated")

class TestAnd:
	extends "res://tests/ScEng_common.gd"

	func test_and():
		var type : String = cards[0].properties["Type"]
		yield(table_move(cards[0], Vector2(500,200)), "completed")
		yield(table_move(cards[4], Vector2(800,200)), "completed")
		cards[4].modify_property("Cost", 2)
		cards[1].scripts = {"manual": {"hand": [
				{"name": "rotate_card",
				"subject": "boardseek",
				"subject_count": "all",
				"filter_state_seek": [{
					"filter_properties": {"Type": type},
					"filter_properties2": {"Cost": 0}
				}],
				"degrees": 180}]}}
		cards[1].execute_scripts()
		yield(yield_to(target._tween, "tween_all_completed", 0.2), YIELD)
		assert_eq(cards[0].card_rotation, 180,
				"Matching both properties will be rotated")
		assert_eq(cards[4].card_rotation, 0,
				"Card not matching both properties will not be rotated")

	func test_or():
		var type : String = target.properties["Type"]
		yield(table_move(target, Vector2(500,200)), "completed")
		yield(table_move(cards[4], Vector2(800,200)), "completed")
		cards[4].modify_property("Cost", 2)
		card.scripts = {"manual": {"hand": [
				{"name": "flip_card",
				"subject": "boardseek",
				"subject_count": "all",
				"filter_state_seek": [{
					"filter_properties": {"Cost": 2}
				},
				{
					"filter_properties": {"Type": type}
				}],
				"set_faceup": false}]}}
		card.execute_scripts()
		yield(yield_to(target._flip_tween, "tween_all_completed", 0.4), YIELD)
		assert_false(target.is_faceup,
				"Card turned face-down after matching or property")
		assert_false(cards[4].is_faceup,
				"Card turned face-down after matching or property")

class TestStateFilterRotation:
	extends "res://tests/ScEng_common.gd"

	func test_state_filter_rotation():
		yield(table_move(cards[1], Vector2(500,200)), "completed")
		yield(table_move(cards[2], Vector2(800,200)), "completed")
		card.scripts = {"manual": {"hand": [
				{"name": "rotate_card",
				"subject": "boardseek",
				"subject_count": "all",
				"filter_state_seek": [{"filter_degrees": 0}],
				"degrees": 90}]}}
		card.execute_scripts()
		yield(yield_for(0.2), YIELD)
		card.scripts = {"manual": {"hand": [
				{"name": "rotate_card",
				"subject": "boardseek",
				"subject_count": "all",
				"filter_state_seek": [{"filter_degrees": 0}],
				"degrees": 270}]}}
		card.execute_scripts()
		yield(yield_to(target._tween, "tween_all_completed", 0.2), YIELD)
		assert_eq(cards[1].card_rotation, 90,
				"Card on board matching rotation state should be rotated 90 degrees")
		assert_eq(cards[2].card_rotation, 90,
				"Card on board matching rotation state should be rotated 90 degrees")

	func test_state_filter_faceup():
		yield(table_move(cards[1], Vector2(500,200)), "completed")
		yield(table_move(cards[2], Vector2(800,200)), "completed")
		card.scripts = {"manual": {"hand": [
				{"name": "rotate_card",
				"subject": "boardseek",
				"subject_count": "all",
				"filter_state_seek": [{"filter_faceup": true}],
				"degrees": 90}]}}
		card.execute_scripts()
		yield(yield_for(0.2), YIELD)
		cards[1].is_faceup = false
		cards[2].is_faceup = false
		yield(yield_for(0.4), YIELD)
		card.scripts = {"manual": {"hand": [
				{"name": "rotate_card",
				"subject": "boardseek",
				"subject_count": "all",
				"filter_state_seek":[ {"filter_faceup": true}],
				"degrees": 270}]}}
		card.execute_scripts()
		yield(yield_to(target._tween, "tween_all_completed", 0.2), YIELD)
		assert_eq(cards[1].card_rotation, 90,
				"Card on board matching flip state should be rotated 90 degrees")
		assert_eq(cards[2].card_rotation, 90,
				"Card on board matching flip state should be rotated 90 degrees")

class TestFilterTokens:
	extends "res://tests/ScEng_common.gd"

	func test_state_filter_tokens():
		yield(table_move(cards[1], Vector2(500,200)), "completed")
		yield(table_move(cards[2], Vector2(800,200)), "completed")
		cards[1].tokens.mod_token("void",5)
		cards[2].tokens.mod_token("void",5)
		card.scripts = {"manual": {"hand": [
				{"name": "rotate_card",
				"subject": "boardseek",
				"subject_count": "all",
				"filter_state_seek": [{
					"filter_tokens": [
						{"filter_token_name": "void"}]}],
				"degrees": 90}]}}
		card.execute_scripts()
		yield(yield_to(cards[1]._tween, "tween_all_completed", 0.2), YIELD)
		card.scripts = {"manual": {"hand": [
				{"name": "rotate_card",
				"subject": "boardseek",
				"subject_count": "all",
				"filter_state_seek": [{
					"filter_tokens": [
						{"filter_token_name": "industry"}]}],
				"degrees": 270}]}}
		card.execute_scripts()
		yield(yield_to(cards[1]._tween, "tween_all_completed", 0.2), YIELD)
		assert_eq(cards[1].card_rotation, 90,
				"Card on board matching token name rotated 90 degrees")
		assert_eq(cards[2].card_rotation, 90,
				"Card on board matching token name rotated 90 degrees")
		cards[2].tokens.mod_token("void",-1)
		card.scripts = {"manual": {"hand": [
				{"name": "rotate_card",
				"subject": "boardseek",
				"subject_count": "all",
				"filter_state_seek": [{
					"filter_tokens": [{
						"filter_token_name": "void",
						"filter_count": 4
						}]
				}],
				"degrees": 0}]}}
		card.execute_scripts()
		yield(yield_to(cards[1]._tween, "tween_all_completed", 0.2), YIELD)
		assert_eq(cards[1].card_rotation, 90,
				"Card on board not matching token count stays 90 degrees")
		assert_eq(cards[2].card_rotation, 0,
				"Card on board matching token name rotated 0 degrees")
		cards[2].tokens.mod_token("bio",1)
		card.scripts = {"manual": {"hand": [
				{"name": "rotate_card",
				"subject": "boardseek",
				"subject_count": "all",
				"filter_state_seek": [{
					"filter_tokens": [
						{"filter_token_name": "void"},
						{"filter_token_name": "bio",
						"filter_count": 1},
						]
				}],
				"degrees": 270}]}}
		card.execute_scripts()
		yield(yield_to(cards[1]._tween, "tween_all_completed", 0.2), YIELD)
		assert_eq(cards[1].card_rotation, 90,
				"Card on board not matching tokens stays 90 degrees")
		assert_eq(cards[2].card_rotation, 270,
				"Card on board matching token name rotated 270 degrees")

class TestFilterParent:
	extends "res://tests/ScEng_common.gd"

	func test_state_filter_parent():
		yield(table_move(cards[1], Vector2(500,200)), "completed")
		card.scripts = {"manual": {"hand": [
				{"name": "flip_card",
				"subject": "target",
				"filter_state_subject": [{"filter_parent": "board"}],
				"set_faceup": false}]}}
		yield(execute_with_target(card,cards[1]), "completed")
		yield(execute_with_target(card,cards[2]), "completed")
		assert_true(cards[2].is_faceup,
				"Card stayed face-up since filter_parent didn't match")
		assert_false(cards[1].is_faceup,
				"Card turned face-down since filter_parent matches")

	func test_counter_comparison():
	# warning-ignore:return_value_discarded
		board.counters.mod_counter("research", 3)
		cards[4].modify_property("Cost", 2)
		cards[0].modify_property("Cost", 3)
		yield(table_move(cards[0], Vector2(500,200)), "completed")
		yield(table_move(cards[4], Vector2(800,200)), "completed")
		cards[1].scripts = {"manual": {"hand": [
				{"name": "rotate_card",
				"subject": "boardseek",
				"subject_count": "all",
				"filter_state_seek": [{
					"filter_properties2": {"Cost": "research"}
				}],
				"degrees": 180}]}}
		cards[1].execute_scripts()
		yield(yield_to(target._tween, "tween_all_completed", 0.2), YIELD)
		assert_eq(cards[0].card_rotation, 180,
				"Matching counter comparison rotated")
		assert_eq(cards[4].card_rotation, 0,
				"Card not matching  counter comparison not rotated")
		cards[1].scripts = {"manual": {"hand": [
				{"name": "rotate_card",
				"subject": "boardseek",
				"subject_count": "all",
				"filter_state_seek": [{
					"filter_properties2": {"Cost": "research", "comparison": "lt"}
				}],
				"degrees": 90}]}}
		cards[1].execute_scripts()
		yield(yield_to(target._tween, "tween_all_completed", 0.2), YIELD)
		assert_eq(cards[0].card_rotation, 180,
				"Failing comparison not rotated ")
		assert_eq(cards[4].card_rotation, 90,
				"Matching comparison  rotated")

class TestPerCounter:
	extends "res://tests/ScEng_common.gd"

	func test_per_counter():
		# warning-ignore:return_value_discarded
		board.counters.mod_counter("research", 3)
		card.scripts = {"manual": {"hand": [
				{"name": "flip_card",
				"subject": "self",
				"filter_per_counter": {
					"counter_name": "research",
					"filter_count": 3,
				},
				"set_faceup": false}]}}
		cards[1].scripts = {"manual": {"hand": [
				{"name": "flip_card",
				"subject": "self",
				"filter_per_counter": {
					"counter_name": "research",
					"filter_count": 3,
					"comparison": 'gt'
				},
				"set_faceup": false}]}}
		card.execute_scripts()
		cards[1].execute_scripts()
		yield(yield_to(card._flip_tween, "tween_all_completed", 0.4), YIELD)
		assert_false(card.is_faceup,
				"Card is facedown because counter comparison succeeded")
		assert_true(cards[1].is_faceup,
				"Card is faceup because counter comparison failed")
