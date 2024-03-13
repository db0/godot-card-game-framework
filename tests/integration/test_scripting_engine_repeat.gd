extends "res://tests/UTcommon.gd"

class TestRepeat:
	extends "res://tests/ScEng_common.gd"

	func test_repeat():
		card.scripts = {"manual": {"hand": [
				{"name": "mod_counter",
				"modification": 3,
				"repeat": 3,
				"counter_name":  "research"}]}}
		card.execute_scripts()
		assert_eq(9,await board.counters.get_counter("research"),
				"Counter increased by specified amount")
		card.scripts = {"manual": {"hand": [
				{"name": "mod_counter",
				"modification": 2,
				"repeat": 3,
				"set_to_mod": true,
				"counter_name": "credits"}]}}
		card.execute_scripts()
		assert_eq(2,await board.counters.get_counter("credits"),
				"Counter set to the specified amount")

class TestRepeatWithTarget:
	extends "res://tests/ScEng_common.gd"

	func test_repeat_with_target():
		card.scripts = {"manual": {"hand": [
				{"name": "mod_tokens",
				"subject": "target",
				"modification": 2,
				"repeat": 3,
				"token_name":  "industry"}]}}
		card.execute_scripts()
		await target_card(card,target)
		# My scripts are slower now
		await yield_for(0.2).YIELD
		var industry_token: Token = target.tokens.get_token("industry")
		assert_eq(6,industry_token.count,"Token set to specified amount")
