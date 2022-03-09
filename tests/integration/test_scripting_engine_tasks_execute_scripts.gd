extends "res://tests/UTcommon.gd"

class TestExecuteScripts:
	extends "res://tests/ScEng_common.gd"

	func test_execute_scripts():
		card.scripts = {"manual": {"hand": [
				{"name": "execute_scripts",
				"subject": "target",
				"exec_trigger":  "manual",
				"require_exec_state": "hand"}]}}
		target.scripts = {"manual": {"hand": [
				{"name": "move_card_to_board",
				"subject": "self",
				"board_position":  Vector2(100,100)}]}}
		card.execute_scripts()
		yield(target_card(card,target), "completed")
		yield(yield_to(card._tween, "tween_all_completed", 1), YIELD)
		assert_eq(target.get_parent(),cfc.NMAP.board,
				"Card should have moved to board")
		target.scripts = {"manual": {"board": [
				{"name": "mod_tokens",
				"subject": "self",
				"modification": 1,
				"token_name":  "industry"}]}}
		card.execute_scripts()
		yield(target_card(card,target), "completed")
		var industry_token: Token = target.tokens.get_token("industry")
		assert_null(industry_token,
				"scripts not executed because exec state does not match")
		card.scripts = {"manual": {"hand": [
				{"name": "execute_scripts",
				"subject": "target",
				"exec_trigger":  "manual",}]}}
		card.execute_scripts()
		yield(target_card(card,target), "completed")
		yield(yield_for(0.1), YIELD)
		industry_token = target.tokens.get_token("industry")
		assert_not_null(industry_token,
				"scripts executed because exec state not defined")
		card.scripts = {"manual": {"hand": [
				{"name": "execute_scripts",
				"subject": "target",
				"exec_trigger":  "false",}]}}
		card.execute_scripts()
		yield(target_card(card,target), "completed")
		yield(yield_for(0.1), YIELD)
		industry_token = target.tokens.get_token("industry")
		assert_not_null(industry_token)
		if industry_token:
			assert_eq(industry_token.count, 1,
					"scripts not executed because exec_trigger does not match")

class TestExecuteScriptsWithTempModProp:
	extends "res://tests/ScEng_common.gd"

	func test_execute_scripts_with_temp_mod_property():
		# warning-ignore:return_value_discarded
		target.modify_property("Cost", 1)
		card.scripts = {"manual": {"hand": [
				{"name": "execute_scripts",
				"subject": "target",
				"exec_trigger":  "manual",
				"temp_mod_properties": {"Cost": 1},
				"require_exec_state": "hand"}]}}
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
		assert_eq(hand.get_card_count(), 7,
			"Draw the temp modified amount of cards")
		card.scripts = {"manual": {"hand": [
				{"name": "execute_scripts",
				"subject": "target",
				"exec_trigger":  "manual",
				"temp_mod_properties": {"Cost": -5},
				"require_exec_state": "hand"}]}}
		card.execute_scripts()
		yield(target_card(card,target, "slow"), "completed")
		yield(yield_for(0.5), YIELD)
		assert_eq(hand.get_card_count(), 7,
			"Ensure the property does not go negative")
		target.execute_scripts()
		yield(yield_for(0.1), YIELD)
		assert_eq(hand.get_card_count(), 8,
			"Ensure temp property modifiers don't remain")

class TestExecuteScriptsWithTempModCounter:
	extends "res://tests/ScEng_common.gd"

	func test_execute_scripts_with_temp_mod_counter():
		cfc.NMAP.board.counters.mod_counter("research", 1)
		card.scripts = {"manual": {"hand": [
				{"name": "execute_scripts",
				"subject": "target",
				"exec_trigger":  "manual",
				"temp_mod_counters": {"research": 1},
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
		assert_eq(hand.get_card_count(), 7,
			"Draw the temp modified amount of cards")
		card.scripts = {"manual": {"hand": [
				{"name": "execute_scripts",
				"subject": "target",
				"exec_trigger":  "manual",
				"temp_mod_counters": {"research": -5},
				"require_exec_state": "hand"}]}}
		card.execute_scripts()
		yield(target_card(card,target, "slow"), "completed")
		yield(yield_for(0.5), YIELD)
		assert_eq(hand.get_card_count(), 7,
			"Ensure the counter does not go negative")
		target.execute_scripts()
		yield(yield_for(0.1), YIELD)
		assert_eq(hand.get_card_count(), 8,
			"Ensure temp property modifiers don't remain")

	func test_no_costs_are_paid_when_target_costs_cannot_be_paid():
		pending("is_cost == true execute_tasks: No costs were paid because target card could not pay costs")
		pending("is_cost == false execute_tasks: Cost were paid because target card could not pay costs")
		pending("is_cost == true execute_tasks: costs were paid when subject == boardseek")
