extends "res://tests/UTcommon.gd"

class TestBasics:
	extends "res://tests/ScEng_common.gd"

	func test_basics():
		card.scripts = {"manual": { "hand": [
				{"name": "rotate_card",
				"subject": "self",
				"degrees": 270}]}}
		yield(table_move(card, Vector2(100,200)), "completed")
		card.execute_scripts()
		assert_eq(target.card_rotation, 0,
				"Script should not work from a different state")
		yield(yield_for(0.5), YIELD)
		# The below tests _common_target == false
		card.scripts = {"hand": [{}]}
		card.execute_scripts()
		pending("Empty does not create a ScriptingEngine object")
		card.is_faceup = false
		yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
		yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
		card.scripts = {"hand": [{"name": "flip_card","set_faceup": true}]}
		card.execute_scripts()
		yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
		yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
		assert_false(card.is_faceup,
				"Scripts should not fire while card is face-down")
		card.scripts = {"hand": [{}]}

class TestStateExecutions:
	extends "res://tests/ScEng_common.gd"

	func test_state_executions():
		card.scripts = {"manual": {"hand": [
				{"name": "flip_card",
				"subject": "self",
				"set_faceup": false}]}}
		card.execute_scripts()
		yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
		yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
		assert_false(card.is_faceup,
			"Target should be face-down")
		card.is_faceup = true
		card.state = Card.CardState.PUSHED_ASIDE
		card.execute_scripts()
		yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
		yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
		assert_false(card.is_faceup,
			"Target should be face-down")
		card.is_faceup = true
		yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
		yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
		card.state = Card.CardState.FOCUSED_IN_HAND
		card.execute_scripts()
		yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
		yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
		assert_false(card.is_faceup,
			"Target should be face-down")
		card.is_faceup = true
		yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
		yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
		card.scripts = {"manual": {"board": [
				{"name": "flip_card",
				"subject": "self",
				"set_faceup": false}]}}
		yield(table_move(card, Vector2(500,100)), "completed")
		card.execute_scripts()
		yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
		yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
		assert_false(card.is_faceup,
			"Target should be face-down")
		card.is_faceup = true
		yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
		yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
		card.state = Card.CardState.FOCUSED_ON_BOARD
		card.execute_scripts()
		yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
		yield(yield_to(target._flip_tween, "tween_all_completed", 0.5), YIELD)
		assert_false(card.is_faceup,
			"Target should be face-down")
		card.move_to(cfc.NMAP.discard)
		yield(yield_to(card._tween, "tween_all_completed", 1), YIELD)
		yield(yield_to(card._tween, "tween_all_completed", 0.5), YIELD)
		card.scripts = {"manual": {"pile": [
				{"name": "move_card_to_board",
				"subject": "self",
				"board_position":  Vector2(100,100)}]}}
		discard._on_View_Button_pressed()
		yield(yield_for(1), YIELD)
		card.execute_scripts()
		yield(yield_to(card._tween, "tween_all_completed", 1), YIELD)
		yield(yield_to(card._tween, "tween_all_completed", 0.5), YIELD)
		assert_eq(Vector2(100,100),card.global_position,
				"Card should have moved to specified position")
		card.move_to(cfc.NMAP.discard)
		yield(yield_to(card._tween, "tween_all_completed", 1), YIELD)
		card.state = Card.CardState.FOCUSED_IN_POPUP
		card.execute_scripts()
		yield(yield_to(card._tween, "tween_all_completed", 1), YIELD)
		assert_eq(Vector2(100,100),card.global_position,
				"Card should have moved to specified position")


class TestCardScripts:
	extends "res://tests/ScEng_common.gd"

	# Checks that scripts from the CardScriptDefinitions.gd have been loaded correctly
	func test_CardScripts():
		card = cards[1]
		target = cards[3]
		yield(table_move(target, Vector2(800,200)), "completed")
		yield(table_move(card, Vector2(100,200)), "completed")
		card.execute_scripts()
		yield(target_card(card,target,"slow"), "completed")
		yield(yield_to(target.get_node("Tween"), "tween_all_completed", 1), YIELD)
		# This also tests the _common_target set
		assert_false(target.is_faceup,
				"Test1 script leaves target facedown")
		assert_eq(target.card_rotation, 180,
				"Test1 script rotates 180 degrees")
		yield(table_move(cards[4], Vector2(500,200)), "completed")
		card.execute_scripts()
		yield(target_card(card,cards[4]), "completed")
		yield(yield_to(cards[4].get_node("Tween"), "tween_all_completed", 1), YIELD)
		assert_false(cards[4].is_faceup,
				"Ensure targeting is cleared after first ScriptingEngine")

class TestTargetScriptOnDragFromHand:
	extends "res://tests/ScEng_common.gd"
	func _init() -> void:
		target_index = 1
		initial_wait = 0.5

	func test_target_script_on_drag_from_hand():
		cfc.NMAP.board.counters.mod_counter("credits", 10, true)
		card.scripts = {"manual": {"hand": [
					{"name": "mod_counter",
					"modification": -2,
					"is_cost": true,
					"counter_name": "credits"},
					{"name": "flip_card",
					"subject": "target",
					"set_faceup": false}]}}
		card.hand_drag_starts_targeting = true
		yield(drag_card(card, Vector2(300,300)), 'completed')
		assert_true(card.targeting_arrow.get_node("ArrowHead").visible,
				"Targeting has started on long-click")
		yield(target_card(card,target), "completed")
		assert_eq(board.counters.get_counter("credits"),8,
				"Counter reduced by 2")
		assert_false(target.is_faceup,
				"Target is face-down")
		card.scripts = {"manual": {"hand": [
					{"name": "mod_counter",
					"modification": -10,
					"is_cost": true,
					"counter_name": "credits"},
					{"name": "flip_card",
					"subject": "target",
					"set_faceup": false}]}}
		target = cards[2]
		yield(drag_card(card, Vector2(300,300)), 'completed')
		assert_false(card.targeting_arrow.get_node("ArrowHead").visible,
				"Targeting not started because costs cannot be paid")
		yield(target_card(card,target), "completed")
		assert_eq(board.counters.get_counter("credits"),8,
				"Counter not reduced")
		assert_true(target.is_faceup,
				"Target stayed face-up since cost could not be paid")
		card.scripts = {"manual": {"hand": [
					{"name": "flip_card",
					"subject": "target",
					"is_cost": true,
					"set_faceup": false},
					{"name": "mod_counter",
					"modification": -10,
					"is_cost": true,
					"counter_name": "credits"}]}}
		yield(drag_card(card, Vector2(300,300)), 'completed')
		assert_true(card.targeting_arrow.get_node("ArrowHead").visible,
				"Targeting started because targeting is_cost")
		yield(target_card(card,target), "completed")
		assert_eq(board.counters.get_counter("credits"),8,
				"Counter not reduced")
		assert_true(target.is_faceup,
				"Target stayed face-up since cost could not be paid")
		card.scripts = {"manual": {"hand": [
					{"name": "flip_card",
					"subject": "target",
					"is_cost": true,
					"set_faceup": false},
					{"name": "mod_counter",
					"modification": -3,
					"counter_name": "credits"}]}}
		yield(drag_card(card, Vector2(300,300)), 'completed')
		unclick_card_anywhere(card)
		yield(yield_for(0.1), YIELD)
		assert_eq(board.counters.get_counter("credits"),8,
				"Counter not reduced since nothing was targeted")
		card.scripts = {"manual": {"hand": [
					{"name": "flip_card",
					"subject": "target",
					"set_faceup": false},
					{"name": "mod_counter",
					"modification": -3,
					"is_cost": true,
					"counter_name": "credits"}]}}
		yield(drag_card(card, Vector2(300,300)), 'completed')
		unclick_card_anywhere(card)
		assert_eq(board.counters.get_counter("credits"),5,
				"Counter reduced since targeting was not a cost")
